-- City Pulse Live (멀티플레이어 v1) — 2026-05-10
-- 정책: 위치 데이터는 영구 저장 X (Realtime Presence 휘발 채널만 사용).
-- 본 마이그레이션은 프로필/친구/룸/채팅/차단만 다룬다.

----------------------------------------------------------------------
-- 1. profiles  (Auth user 1:1)
----------------------------------------------------------------------
create table if not exists public.profiles (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  nickname    text not null check (char_length(nickname) between 1 and 20),
  pin_color   text not null default '#7C5CFF' check (pin_color ~ '^#[0-9A-Fa-f]{6}$'),
  pin_emoji   text not null default '📍' check (char_length(pin_emoji) between 1 and 8),
  visibility  text not null default 'ghost' check (visibility in ('public','friends','ghost')),
  birth_year  smallint not null check (birth_year between 1900 and 2100),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 만 14세 미만 가입 거부 (PIPA 법정대리인 동의 회피).
-- 매년 1월 1일 기준 단순화 — 정확한 생일은 받지 않음 (최소수집 원칙).
create or replace function public._enforce_min_age()
returns trigger language plpgsql as $$
begin
  if (extract(year from now())::int - new.birth_year) < 14 then
    raise exception '14세 미만은 가입할 수 없습니다.' using errcode = 'P0001';
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_profiles_min_age on public.profiles;
create trigger trg_profiles_min_age
  before insert or update on public.profiles
  for each row execute function public._enforce_min_age();

alter table public.profiles enable row level security;

-- SELECT: 본인 + 같은 룸 멤버 + 친구 (블록은 RLS 단계에서 제외).
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select using (
  user_id = auth.uid()
  or exists (
    select 1 from public.friendships f
     where f.status = 'accepted'
       and ((f.user_a = auth.uid() and f.user_b = profiles.user_id)
         or (f.user_b = auth.uid() and f.user_a = profiles.user_id))
  )
  or exists (
    select 1 from public.room_members m1
    join public.room_members m2 on m1.room_id = m2.room_id
     where m1.user_id = auth.uid() and m2.user_id = profiles.user_id
  )
);

drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert
  with check (user_id = auth.uid());

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists profiles_delete on public.profiles;
create policy profiles_delete on public.profiles for delete
  using (user_id = auth.uid());


----------------------------------------------------------------------
-- 2. blocks  (단방향 차단)
----------------------------------------------------------------------
create table if not exists public.blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

alter table public.blocks enable row level security;

drop policy if exists blocks_owner on public.blocks;
create policy blocks_owner on public.blocks for all
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());


----------------------------------------------------------------------
-- 3. friendships  (양방향 정렬, user_a < user_b)
----------------------------------------------------------------------
create table if not exists public.friendships (
  user_a   uuid not null references auth.users (id) on delete cascade,
  user_b   uuid not null references auth.users (id) on delete cascade,
  status   text not null default 'pending' check (status in ('pending','accepted','blocked')),
  initiated_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_a, user_b),
  check (user_a < user_b)
);

create index if not exists friendships_user_b_idx on public.friendships (user_b);

alter table public.friendships enable row level security;

drop policy if exists friendships_select on public.friendships;
create policy friendships_select on public.friendships for select
  using (auth.uid() in (user_a, user_b));

-- 친구 신청: 본인이 initiated_by, 차단 관계는 거부.
drop policy if exists friendships_insert on public.friendships;
create policy friendships_insert on public.friendships for insert
  with check (
    auth.uid() = initiated_by
    and auth.uid() in (user_a, user_b)
    and not exists (
      select 1 from public.blocks
       where (blocker_id = user_a and blocked_id = user_b)
          or (blocker_id = user_b and blocked_id = user_a)
    )
  );

-- 수락/거절: 신청 받은 쪽만 update 가능.
drop policy if exists friendships_update on public.friendships;
create policy friendships_update on public.friendships for update
  using (auth.uid() in (user_a, user_b) and auth.uid() <> initiated_by);

drop policy if exists friendships_delete on public.friendships;
create policy friendships_delete on public.friendships for delete
  using (auth.uid() in (user_a, user_b));


----------------------------------------------------------------------
-- 4. rooms  (친구방, 6자리 초대코드, 24h TTL)
----------------------------------------------------------------------
create table if not exists public.rooms (
  id           uuid primary key default gen_random_uuid(),
  invite_code  text not null unique check (char_length(invite_code) = 6),
  owner_id     uuid not null references auth.users (id) on delete cascade,
  name         text,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default (now() + interval '24 hours')
);

create index if not exists rooms_owner_idx on public.rooms (owner_id);
create index if not exists rooms_expires_idx on public.rooms (expires_at);


----------------------------------------------------------------------
-- 5. room_members  (정원 8명)
----------------------------------------------------------------------
create table if not exists public.room_members (
  room_id   uuid not null references public.rooms (id) on delete cascade,
  user_id   uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create index if not exists room_members_user_idx on public.room_members (user_id);

-- 정원 제한 + 차단 사용자 입장 차단.
create or replace function public._enforce_room_join()
returns trigger language plpgsql as $$
declare
  member_count int;
begin
  -- 만료된 방 거부.
  if exists (select 1 from public.rooms where id = new.room_id and expires_at <= now()) then
    raise exception '만료된 방입니다.' using errcode = 'P0002';
  end if;

  -- 정원 8명 제한.
  select count(*) into member_count from public.room_members where room_id = new.room_id;
  if member_count >= 8 then
    raise exception '방 정원(8명)을 초과했습니다.' using errcode = 'P0003';
  end if;

  -- 기존 멤버 중 차단 관계 있으면 입장 거부.
  if exists (
    select 1 from public.room_members m
    join public.blocks b on
      (b.blocker_id = m.user_id and b.blocked_id = new.user_id)
      or (b.blocker_id = new.user_id and b.blocked_id = m.user_id)
    where m.room_id = new.room_id
  ) then
    raise exception '차단 관계가 있는 사용자가 이미 방에 있습니다.' using errcode = 'P0004';
  end if;

  return new;
end $$;

drop trigger if exists trg_room_join on public.room_members;
create trigger trg_room_join
  before insert on public.room_members
  for each row execute function public._enforce_room_join();


----------------------------------------------------------------------
-- 6. RLS for rooms / room_members
----------------------------------------------------------------------
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;

drop policy if exists rooms_select on public.rooms;
create policy rooms_select on public.rooms for select using (
  owner_id = auth.uid()
  or exists (select 1 from public.room_members m where m.room_id = rooms.id and m.user_id = auth.uid())
);

drop policy if exists rooms_insert on public.rooms;
create policy rooms_insert on public.rooms for insert with check (owner_id = auth.uid());

drop policy if exists rooms_update on public.rooms;
create policy rooms_update on public.rooms for update using (owner_id = auth.uid());

drop policy if exists rooms_delete on public.rooms;
create policy rooms_delete on public.rooms for delete using (owner_id = auth.uid());

drop policy if exists room_members_select on public.room_members;
create policy room_members_select on public.room_members for select using (
  exists (select 1 from public.room_members m where m.room_id = room_members.room_id and m.user_id = auth.uid())
);

drop policy if exists room_members_insert on public.room_members;
create policy room_members_insert on public.room_members for insert
  with check (user_id = auth.uid());

-- 본인 자진 퇴장 또는 owner 가 강퇴.
drop policy if exists room_members_delete on public.room_members;
create policy room_members_delete on public.room_members for delete using (
  user_id = auth.uid()
  or exists (select 1 from public.rooms r where r.id = room_members.room_id and r.owner_id = auth.uid())
);


----------------------------------------------------------------------
-- 7. room_messages  (24h 후 자동 삭제)
----------------------------------------------------------------------
create table if not exists public.room_messages (
  id         uuid primary key default gen_random_uuid(),
  room_id    uuid not null references public.rooms (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 500),
  kind       text not null default 'text' check (kind in ('text','emoji','system','meetup')),
  created_at timestamptz not null default now()
);

create index if not exists room_messages_room_time_idx on public.room_messages (room_id, created_at desc);

alter table public.room_messages enable row level security;

drop policy if exists room_messages_select on public.room_messages;
create policy room_messages_select on public.room_messages for select using (
  exists (select 1 from public.room_members m where m.room_id = room_messages.room_id and m.user_id = auth.uid())
  -- 차단한 사용자 메시지 숨김.
  and not exists (select 1 from public.blocks b where b.blocker_id = auth.uid() and b.blocked_id = room_messages.user_id)
);

drop policy if exists room_messages_insert on public.room_messages;
create policy room_messages_insert on public.room_messages for insert with check (
  user_id = auth.uid()
  and exists (select 1 from public.room_members m where m.room_id = room_messages.room_id and m.user_id = auth.uid())
);

drop policy if exists room_messages_delete on public.room_messages;
create policy room_messages_delete on public.room_messages for delete using (user_id = auth.uid());


----------------------------------------------------------------------
-- 8. RPC — 초대 코드로 방 입장
----------------------------------------------------------------------
create or replace function public.join_room_by_code(p_code text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_room_id uuid;
begin
  select id into v_room_id from public.rooms
   where invite_code = upper(p_code) and expires_at > now();
  if v_room_id is null then
    raise exception '유효하지 않거나 만료된 초대 코드입니다.' using errcode = 'P0005';
  end if;
  insert into public.room_members (room_id, user_id) values (v_room_id, auth.uid())
    on conflict do nothing;
  return v_room_id;
end $$;

grant execute on function public.join_room_by_code(text) to authenticated;


----------------------------------------------------------------------
-- 9. 청소 작업 (만료 룸/메시지 — pg_cron 사용 가능한 경우 스케줄 별도 권장)
----------------------------------------------------------------------
create or replace function public.cleanup_multiplayer()
returns void language sql security definer set search_path = public as $$
  delete from public.rooms where expires_at <= now() - interval '1 hour';
  delete from public.room_messages where created_at <= now() - interval '24 hours';
$$;

-- pg_cron 사용 가능하면:
--   select cron.schedule('multiplayer_cleanup', '*/30 * * * *', $$select public.cleanup_multiplayer();$$);


----------------------------------------------------------------------
-- 10. Realtime publication (Postgres Changes 구독용)
----------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

alter publication supabase_realtime add table public.room_messages;
alter publication supabase_realtime add table public.room_members;
alter publication supabase_realtime add table public.friendships;
