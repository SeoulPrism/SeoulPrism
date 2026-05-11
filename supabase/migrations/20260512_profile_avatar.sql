-- 프로필 사진 (avatar) — 2026-05-12
-- profiles.avatar_url 컬럼 + Storage bucket `avatars` + RLS.
-- 정책: 본인 폴더(<user_id>/...) 안에서만 업로드/삭제. SELECT 는 누구나 가능
--       (URL 알면 다운로드) — bucket public=true 이고 visibility=ghost
--       프로필이라도 URL 자체가 추측 불가능한 timestamp 기반이라 사실상 비공개.

alter table public.profiles
  add column if not exists avatar_url text;

-- 길이 sanity check — Supabase Storage public URL 은 보통 200자 안쪽.
alter table public.profiles
  drop constraint if exists profiles_avatar_url_len;
alter table public.profiles
  add constraint profiles_avatar_url_len
  check (avatar_url is null or char_length(avatar_url) <= 1024);

------------------------------------------------------------
-- Storage bucket
------------------------------------------------------------
insert into storage.buckets (id, name, public)
  values ('avatars', 'avatars', true)
  on conflict (id) do nothing;

-- SELECT 정책 의도적으로 생략 — public bucket 이라 URL 다운로드는 정책 없이
-- 동작. SELECT 정책을 두면 storage.list() 가 모든 파일을 노출시키므로 보안상
-- 빼는 게 정답 (advisor 0025 public_bucket_allows_listing).

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
