-- 사용자 아바타 (프로필 사진) — 2026-05-12
-- Storage bucket `avatars` 만 생성. 아바타 URL 자체는 `auth.users.user_metadata.avatar_url`
-- 에 저장 (Seoul Live / multiplayer 와 무관 — 모든 사용자가 가질 수 있음).
-- `public.profiles` 는 멀티플레이어 전용 테이블이라 아바타 컬럼을 두지 않는다.

insert into storage.buckets (id, name, public)
  values ('avatars', 'avatars', true)
  on conflict (id) do nothing;

-- SELECT 정책 의도적 미생성 — public bucket 이라 URL 직접 GET 은 정책 없이 동작.
-- SELECT 정책을 두면 storage.list() 가 전체 파일을 노출함 (advisor 0025).

-- 업로드: 로그인 + 자신의 user_id 폴더에만.
drop policy if exists avatars_insert on storage.objects;
create policy avatars_insert on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists avatars_update on storage.objects;
create policy avatars_update on storage.objects for update
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists avatars_delete on storage.objects;
create policy avatars_delete on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
