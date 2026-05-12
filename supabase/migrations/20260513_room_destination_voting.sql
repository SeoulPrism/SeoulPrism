-- 방 공통 목적지 투표 시스템.
-- 방장이 후보 제안 → 멤버들이 yes/no → 과반(멤버 수 기준) yes 도달 시 자동 approved
-- + rooms.dest_* 갱신. 과반 no 도달 시 자동 rejected. 방장은 언제든 cancel.

CREATE TABLE IF NOT EXISTS public.room_destination_proposals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  proposer_id uuid NOT NULL REFERENCES auth.users(id),
  name text NOT NULL,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  address text,
  status text NOT NULL DEFAULT 'voting'
    CHECK (status IN ('voting','approved','rejected','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  finalized_at timestamptz
);

CREATE INDEX IF NOT EXISTS room_destination_proposals_room_status_idx
  ON public.room_destination_proposals (room_id, status);

CREATE TABLE IF NOT EXISTS public.room_destination_votes (
  proposal_id uuid NOT NULL REFERENCES public.room_destination_proposals(id)
    ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  vote boolean NOT NULL,
  voted_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (proposal_id, user_id)
);

ALTER TABLE public.room_destination_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_destination_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rdp_select ON public.room_destination_proposals;
CREATE POLICY rdp_select ON public.room_destination_proposals
  FOR SELECT USING (public._is_room_member(room_id));

DROP POLICY IF EXISTS rdv_select ON public.room_destination_votes;
CREATE POLICY rdv_select ON public.room_destination_votes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.room_destination_proposals p
      WHERE p.id = proposal_id AND public._is_room_member(p.room_id)
    )
  );

ALTER PUBLICATION supabase_realtime ADD TABLE public.room_destination_proposals;
ALTER PUBLICATION supabase_realtime ADD TABLE public.room_destination_votes;

CREATE OR REPLACE FUNCTION public._evaluate_proposal(p_proposal_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  v_proposal record;
  v_yes int;
  v_no int;
  v_members int;
  v_threshold int;
begin
  select * into v_proposal
    from public.room_destination_proposals
   where id = p_proposal_id and status = 'voting';
  if v_proposal is null then return; end if;

  select count(*) into v_yes
    from public.room_destination_votes
   where proposal_id = p_proposal_id and vote = true;
  select count(*) into v_no
    from public.room_destination_votes
   where proposal_id = p_proposal_id and vote = false;
  select count(*) into v_members
    from public.room_members where room_id = v_proposal.room_id;

  v_threshold := (v_members / 2) + 1;

  if v_yes >= v_threshold then
    update public.room_destination_proposals
       set status = 'approved', finalized_at = now()
     where id = p_proposal_id;
    update public.rooms
       set dest_name = v_proposal.name,
           dest_lat = v_proposal.lat,
           dest_lng = v_proposal.lng,
           dest_set_by = v_proposal.proposer_id,
           dest_set_at = now()
     where id = v_proposal.room_id;
    insert into public.room_messages (room_id, user_id, kind, body)
    values (v_proposal.room_id, v_proposal.proposer_id, 'system',
            '🎯 목적지 확정: ' || v_proposal.name);
  elsif v_no >= v_threshold then
    update public.room_destination_proposals
       set status = 'rejected', finalized_at = now()
     where id = p_proposal_id;
    insert into public.room_messages (room_id, user_id, kind, body)
    values (v_proposal.room_id, v_proposal.proposer_id, 'system',
            '❌ 후보 기각: ' || v_proposal.name);
  end if;
end;
$function$;

CREATE OR REPLACE FUNCTION public.propose_room_destination(
  p_room_id uuid,
  p_name text,
  p_lat double precision,
  p_lng double precision,
  p_address text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  v_owner uuid;
  v_new_id uuid;
begin
  select owner_id into v_owner from public.rooms where id = p_room_id;
  if v_owner is null then
    raise exception 'room not found' using errcode = 'P0009';
  end if;
  if v_owner <> auth.uid() then
    raise exception 'not the room owner' using errcode = 'P0011';
  end if;

  update public.room_destination_proposals
     set status = 'cancelled', finalized_at = now()
   where room_id = p_room_id and status = 'voting';

  insert into public.room_destination_proposals
    (room_id, proposer_id, name, lat, lng, address)
  values (p_room_id, auth.uid(), p_name, p_lat, p_lng, p_address)
  returning id into v_new_id;

  insert into public.room_messages (room_id, user_id, kind, body)
  values (p_room_id, auth.uid(), 'system',
          '🗳 새 후보: ' || p_name);
  return v_new_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.vote_room_destination(
  p_proposal_id uuid,
  p_vote boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare v_room_id uuid; v_status text;
begin
  select room_id, status into v_room_id, v_status
    from public.room_destination_proposals where id = p_proposal_id;
  if v_room_id is null then
    raise exception 'proposal not found' using errcode = 'P0009';
  end if;
  if v_status <> 'voting' then
    raise exception 'proposal not in voting' using errcode = 'P0016';
  end if;
  if not public._is_room_member(v_room_id) then
    raise exception 'not a room member' using errcode = 'P0010';
  end if;

  insert into public.room_destination_votes (proposal_id, user_id, vote)
  values (p_proposal_id, auth.uid(), p_vote)
  on conflict (proposal_id, user_id) do update
    set vote = excluded.vote, voted_at = now();

  perform public._evaluate_proposal(p_proposal_id);
end;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_room_destination_proposal(
  p_proposal_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare v_room_id uuid; v_owner uuid; v_name text;
begin
  select rdp.room_id, r.owner_id, rdp.name
    into v_room_id, v_owner, v_name
    from public.room_destination_proposals rdp
    join public.rooms r on r.id = rdp.room_id
   where rdp.id = p_proposal_id and rdp.status = 'voting';
  if v_room_id is null then
    raise exception 'proposal not found or not active' using errcode = 'P0009';
  end if;
  if v_owner <> auth.uid() then
    raise exception 'not the room owner' using errcode = 'P0011';
  end if;

  update public.room_destination_proposals
     set status = 'cancelled', finalized_at = now()
   where id = p_proposal_id;

  insert into public.room_messages (room_id, user_id, kind, body)
  values (v_room_id, auth.uid(), 'system',
          '↩️ 후보 취소: ' || coalesce(v_name, ''));
end;
$function$;

GRANT EXECUTE ON FUNCTION public.propose_room_destination(uuid, text, double precision, double precision, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.vote_room_destination(uuid, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_room_destination_proposal(uuid) TO authenticated;
