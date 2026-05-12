-- set_room_destination / clear_room_destination 에 방장(owner) 검증 추가.
-- 기존: 멤버 누구나 호출 가능. 이제: rooms.owner_id = auth.uid() 인 방장만.
-- 비-방장 호출 시 'not the room owner' 예외.

CREATE OR REPLACE FUNCTION public.set_room_destination(
  p_room_id uuid,
  p_name text,
  p_lat double precision,
  p_lng double precision
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare v_owner uuid;
begin
  select owner_id into v_owner from public.rooms where id = p_room_id;
  if v_owner is null then
    raise exception 'room not found' using errcode = 'P0009';
  end if;
  if v_owner <> auth.uid() then
    raise exception 'not the room owner' using errcode = 'P0011';
  end if;
  update public.rooms
     set dest_name = p_name,
         dest_lat = p_lat,
         dest_lng = p_lng,
         dest_set_by = auth.uid(),
         dest_set_at = now()
   where id = p_room_id;

  insert into public.room_messages (room_id, user_id, kind, body)
  values (p_room_id, auth.uid(), 'system',
          '🎯 목적지: ' || coalesce(p_name, '이름 없음'));
end;
$function$;

CREATE OR REPLACE FUNCTION public.clear_room_destination(p_room_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare v_owner uuid;
begin
  select owner_id into v_owner from public.rooms where id = p_room_id;
  if v_owner is null then
    raise exception 'room not found' using errcode = 'P0009';
  end if;
  if v_owner <> auth.uid() then
    raise exception 'not the room owner' using errcode = 'P0011';
  end if;
  update public.rooms
     set dest_name = null,
         dest_lat = null,
         dest_lng = null,
         dest_set_by = null,
         dest_set_at = null
   where id = p_room_id;

  insert into public.room_messages (room_id, user_id, kind, body)
  values (p_room_id, auth.uid(), 'system', '🎯 목적지 해제');
end;
$function$;
