// Seoul Live - notify edge function
//
// 흐름:
// 1. Authorization 헤더 검증 (service role key 또는 cron secret)
// 2. notification_queue 의 status='pending' row 가져옴
// 3. 각 row 의 user_id 의 user_devices.fcm_token 조회
// 4. FCM HTTP v1 API 로 발송 (Service Account JSON 으로 OAuth)
// 5. invalid token 감지 시 user_devices 에서 정리
// 6. status sent/failed 갱신
//
// 환경 변수 (Supabase Dashboard > Edge Functions > Secrets):
//   - FCM_SERVICE_ACCOUNT_JSON  (Firebase Console > 프로젝트 설정 > 서비스 계정 > 새 비공개 키 → 전체 JSON)
//   - SUPABASE_URL  (자동 주입)
//   - SUPABASE_SERVICE_ROLE_KEY (자동 주입)
//   - NOTIFY_CRON_SECRET (선택 — cron 외 호출 차단용 별도 secret)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'
import { SignJWT, importPKCS8 } from 'https://esm.sh/jose@5.6.3'

interface ServiceAccount {
  client_email: string
  private_key: string
  private_key_id: string
  project_id: string
}

let cachedToken: { token: string; exp: number } | null = null

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  if (cachedToken && cachedToken.exp > now + 60) return cachedToken.token

  const privateKey = await importPKCS8(sa.private_key, 'RS256')
  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256', kid: sa.private_key_id })
    .setIssuer(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey)

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  const data = await res.json()
  if (!data.access_token) throw new Error(`OAuth 실패: ${JSON.stringify(data)}`)
  cachedToken = { token: data.access_token, exp: now + (data.expires_in || 3600) }
  return data.access_token
}

interface SendResult {
  ok: boolean
  invalidToken: boolean
  error?: string
}

async function sendFcm(
  accessToken: string,
  projectId: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, unknown>,
): Promise<SendResult> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`
  // FCM 메시지 payload 4KB 제한 — data 가 너무 크면 truncate.
  let stringified = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, String(v)]),
  )
  if (JSON.stringify(stringified).length > 2500) {
    console.warn(`[notify] data payload 큼 — truncate`)
    // 필수 필드만 남김 — kind 우선 유지.
    stringified = stringified.kind ? { kind: stringified.kind } : {}
  }
  const payload = {
    message: {
      token: fcmToken,
      notification: { title, body },
      data: stringified,
      apns: {
        payload: {
          aps: {
            sound: 'default',
            'mutable-content': 1,
          },
        },
      },
      android: {
        priority: 'high',
        notification: { sound: 'default' },
      },
    },
  }
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  })
  if (!res.ok) {
    const errBody = await res.text()
    console.error(`FCM 실패 ${res.status}: ${errBody}`)
    // FCM error code 별 invalid token 판정 — token 자체가 무효이면 정리 필요.
    // ref: https://firebase.google.com/docs/cloud-messaging/send-message#admin
    const invalidToken =
      res.status === 404 ||
      res.status === 410 ||
      errBody.includes('UNREGISTERED') ||
      errBody.includes('INVALID_ARGUMENT') ||
      errBody.includes('NOT_FOUND') ||
      errBody.includes('SENDER_ID_MISMATCH')
    return { ok: false, invalidToken, error: errBody.slice(0, 300) }
  }
  return { ok: true, invalidToken: false }
}

Deno.serve(async (req) => {
  // ── 1. Auth 검증 — Supabase verify_jwt: true 가 platform 레벨에서 JWT 검증.
  //    여기 도달했으면 valid anon/service JWT 이거나 cron secret. 외부 random
  //    attacker 는 platform 단계에서 401. 추가로 service / anon / cron-secret
  //    중 하나는 매치하는지 (방어 깊이).
  const auth = req.headers.get('Authorization') ?? ''
  const cronSecret = req.headers.get('x-cron-secret') ?? ''
  const sbRole = `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''}`
  const anon = `Bearer ${Deno.env.get('SUPABASE_ANON_KEY') ?? ''}`
  const expectedCron = Deno.env.get('NOTIFY_CRON_SECRET') ?? ''
  const authorized =
    (auth.length > 7 && (auth === sbRole || auth === anon)) ||
    (expectedCron.length > 0 && cronSecret === expectedCron)
  if (!authorized) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  const saJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')
  if (!saJson) {
    return new Response(
      JSON.stringify({ error: 'FCM_SERVICE_ACCOUNT_JSON 미설정' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
  const sa: ServiceAccount = JSON.parse(saJson)
  const accessToken = await getAccessToken(sa)

  // Pending 50개 가져옴.
  const { data: pending, error: qerr } = await supabase
    .from('notification_queue')
    .select('*')
    .eq('status', 'pending')
    .order('created_at', { ascending: true })
    .limit(50)
  if (qerr) throw qerr
  if (!pending || pending.length === 0) {
    return new Response(JSON.stringify({ processed: 0 }), {
      headers: { 'Content-Type': 'application/json' },
    })
  }

  let success = 0
  let failed = 0
  let noDevice = 0
  let cleanedTokens = 0

  for (const n of pending) {
    const { data: devices } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', n.user_id)

    if (!devices || devices.length === 0) {
      await supabase.from('notification_queue').update({
        status: 'sent',
        sent_at: new Date().toISOString(),
        error: 'no_device',
      }).eq('id', n.id)
      noDevice++
      continue
    }

    let anyOk = false
    const errors: string[] = []
    for (const d of devices) {
      try {
        const r = await sendFcm(
          accessToken,
          sa.project_id,
          d.fcm_token,
          n.title,
          n.body,
          { ...n.data, kind: n.kind },
        )
        if (r.ok) {
          anyOk = true
        } else {
          if (r.error) errors.push(r.error)
          // FCM 이 알려준 invalid token — 즉시 정리. 안 그러면 다음 push 도 모두 실패.
          if (r.invalidToken) {
            try {
              await supabase
                .from('user_devices')
                .delete()
                .eq('fcm_token', d.fcm_token)
              cleanedTokens++
            } catch (e) {
              console.error('[notify] invalid token cleanup 실패:', e)
            }
          }
        }
      } catch (e) {
        errors.push(String(e))
      }
    }

    await supabase.from('notification_queue').update({
      status: anyOk ? 'sent' : 'failed',
      sent_at: anyOk ? new Date().toISOString() : null,
      error: anyOk ? null : errors.join('; ').slice(0, 500),
    }).eq('id', n.id)

    if (anyOk) success++
    else failed++
  }

  return new Response(
    JSON.stringify({
      processed: pending.length,
      success,
      failed,
      noDevice,
      cleanedTokens,
    }),
    { headers: { 'Content-Type': 'application/json' } },
  )
})
