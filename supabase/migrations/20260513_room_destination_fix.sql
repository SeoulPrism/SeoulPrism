-- set_room_destination / clear_room_destination 이 내부에서
-- _is_room_member(p_room_id, auth.uid()) 처럼 2 인자로 호출했으나, 실제
-- public._is_room_member 시그니처는 (p_room_id uuid) 1 인자 (내부적으로
-- auth.uid() 사용). PostgreSQL 이 시그니처 매칭 실패 → 42883.
-- → 호출을 1 인자로 정정.

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
begin
  if not public._is_room_member(p_room_id) then
    raise exception 'not a room member';
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
begin
  if not public._is_room_member(p_room_id) then
    raise exception 'not a room member';
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
