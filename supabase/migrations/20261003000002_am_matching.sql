-- Pairtive matching: queue, proposals (= matches), accept/next, atomic claim.

create table public.match_proposals (
  id uuid primary key default gen_random_uuid(),
  mode text not null check (mode in ('buddy', 'peers')),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined', 'expired')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  resolved_at timestamptz
);
create index am_match_proposals_status_idx on public.match_proposals (status, expires_at);
create index am_match_proposals_created_idx on public.match_proposals (created_at desc);

create table public.proposal_members (
  proposal_id uuid not null references public.match_proposals (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  accepted boolean,
  responded_at timestamptz,
  teach_subjects text[] not null default '{}',
  learn_subjects text[] not null default '{}',
  primary key (proposal_id, user_id)
);
create index am_proposal_members_user_idx on public.proposal_members (user_id);

create table public.match_queue (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  mode text not null check (mode in ('buddy', 'peers')),
  same_school_only boolean not null default false,
  joined_at timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  status text not null default 'waiting' check (status in ('waiting', 'proposed', 'in_session')),
  proposal_id uuid references public.match_proposals (id) on delete set null
);
create index am_match_queue_wait_idx on public.match_queue (mode, status, joined_at);

create or replace function public.am_is_proposal_member(p_proposal uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.proposal_members where proposal_id = p_proposal and user_id = auth.uid())
$$;

alter table public.match_queue enable row level security;
alter table public.match_proposals enable row level security;
alter table public.proposal_members enable row level security;

create policy "am queue: read own" on public.match_queue for select to authenticated using (user_id = auth.uid());
create policy "am proposals: members read" on public.match_proposals for select to authenticated
  using (public.am_is_proposal_member(id));
create policy "am proposal members: members read" on public.proposal_members for select to authenticated
  using (public.am_is_proposal_member(proposal_id));

revoke insert, update, delete on public.match_queue, public.match_proposals, public.proposal_members from anon, authenticated;
revoke select on public.match_queue, public.match_proposals, public.proposal_members from anon;

-- ---------------------------------------------------------------------------
-- Client RPCs
-- ---------------------------------------------------------------------------
create or replace function public.am_join_queue(p_mode text, p_same_school boolean default false)
returns public.match_queue language plpgsql security definer set search_path = public as $$
declare
  v_profile public.profiles;
  v_row public.match_queue;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  select * into v_profile from public.profiles where id = auth.uid();
  if not found or not v_profile.onboarded then raise exception 'Complete your profile first'; end if;
  if v_profile.rules_accepted_at is null then raise exception 'Please agree to the community rules first'; end if;
  if public.am_is_suspended(auth.uid()) then raise exception 'Your account is suspended'; end if;
  if p_mode not in ('buddy', 'peers') then raise exception 'Invalid mode'; end if;

  insert into public.match_queue as q (user_id, mode, same_school_only, joined_at, last_seen, status, proposal_id)
  values (auth.uid(), p_mode, coalesce(p_same_school, false), now(), now(), 'waiting', null)
  on conflict (user_id) do update set
    mode = case when q.status = 'proposed' then q.mode else excluded.mode end,
    same_school_only = case when q.status = 'proposed' then q.same_school_only else excluded.same_school_only end,
    last_seen = now(),
    joined_at = case
      when q.status = 'proposed' then q.joined_at
      when q.status = 'waiting' and q.mode = excluded.mode then q.joined_at
      else now() end,
    status = case when q.status = 'proposed' then q.status else 'waiting' end,
    proposal_id = case when q.status = 'proposed' then q.proposal_id else null end
  returning * into v_row;
  return v_row;
end $$;

create or replace function public.am_heartbeat()
returns public.match_queue language plpgsql security definer set search_path = public as $$
declare v_row public.match_queue;
begin
  update public.match_queue set last_seen = now() where user_id = auth.uid() returning * into v_row;
  return v_row;
end $$;

-- Resolve a pending proposal as declined / expired and put people back in line.
-- Accepted members (and, on decline, members who had not answered yet) keep their joined_at,
-- so they return to the front of the line. Whoever pressed Next re-enters at the back.
-- On expiry, members who never answered (AFK) are removed from the queue.
create or replace function public.am_resolve_proposal(p_proposal uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.match_proposals set status = p_status, resolved_at = now()
  where id = p_proposal and status = 'pending';
  if not found then return; end if;

  update public.match_queue q set status = 'waiting', proposal_id = null, last_seen = now()
  from public.proposal_members m
  where m.proposal_id = p_proposal and m.user_id = q.user_id and q.proposal_id = p_proposal
    and (m.accepted is true or (p_status = 'declined' and m.accepted is null));

  update public.match_queue q set status = 'waiting', proposal_id = null, joined_at = now(), last_seen = now()
  from public.proposal_members m
  where m.proposal_id = p_proposal and m.user_id = q.user_id and q.proposal_id = p_proposal
    and m.accepted is false;

  delete from public.match_queue q
  using public.proposal_members m
  where m.proposal_id = p_proposal and m.user_id = q.user_id and q.proposal_id = p_proposal
    and m.accepted is null and p_status = 'expired';
end $$;

create or replace function public.am_respond_proposal(p_proposal uuid, p_accept boolean)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_prop public.match_proposals;
  v_open integer;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  select * into v_prop from public.match_proposals where id = p_proposal for update;
  if not found then raise exception 'Match not found'; end if;
  if not exists (select 1 from public.proposal_members where proposal_id = p_proposal and user_id = auth.uid()) then
    raise exception 'Not your match';
  end if;
  if v_prop.status <> 'pending' then return v_prop.status; end if;
  if v_prop.expires_at < now() - interval '3 seconds' then
    perform public.am_resolve_proposal(p_proposal, 'expired');
    return 'expired';
  end if;

  update public.proposal_members set accepted = p_accept, responded_at = now()
  where proposal_id = p_proposal and user_id = auth.uid();

  if not p_accept then
    perform public.am_resolve_proposal(p_proposal, 'declined');
    return 'declined';
  end if;

  select count(*) into v_open from public.proposal_members where proposal_id = p_proposal and accepted is not true;
  if v_open = 0 then
    update public.match_proposals set status = 'accepted', resolved_at = now() where id = p_proposal;
    update public.match_queue set status = 'in_session' where proposal_id = p_proposal;
    return 'accepted';
  end if;
  return 'pending';
end $$;

create or replace function public.am_leave_queue()
returns void language plpgsql security definer set search_path = public as $$
declare v_row public.match_queue;
begin
  select * into v_row from public.match_queue where user_id = auth.uid();
  if not found then return; end if;
  if v_row.status = 'proposed' and v_row.proposal_id is not null then
    update public.proposal_members set accepted = false, responded_at = now()
    where proposal_id = v_row.proposal_id and user_id = auth.uid() and accepted is null;
    perform public.am_resolve_proposal(v_row.proposal_id, 'declined');
  end if;
  delete from public.match_queue where user_id = auth.uid();
end $$;

-- ---------------------------------------------------------------------------
-- Server-only RPCs (called by /api/amMatch with the service role key)
-- ---------------------------------------------------------------------------
-- Atomically claim waiting users into a new proposal. Returns null if any of them
-- is no longer waiting/fresh or is locked by a concurrent matcher run.
create or replace function public.am_claim_proposal(p_mode text, p_members jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_ids uuid[];
  v_count integer;
  v_id uuid;
begin
  select array_agg(distinct (m ->> 'user_id')::uuid) into v_ids from jsonb_array_elements(p_members) m;
  if v_ids is null or cardinality(v_ids) < 2 or cardinality(v_ids) > 5 then return null; end if;
  if cardinality(v_ids) <> jsonb_array_length(p_members) then return null; end if;

  select count(*) into v_count from (
    select 1 from public.match_queue
    where user_id = any (v_ids) and status = 'waiting' and mode = p_mode
      and last_seen > now() - interval '30 seconds'
    for update skip locked
  ) locked;
  if v_count <> cardinality(v_ids) then return null; end if;

  insert into public.match_proposals (mode, expires_at)
  values (p_mode, now() + interval '16 seconds')
  returning id into v_id;

  insert into public.proposal_members (proposal_id, user_id, teach_subjects, learn_subjects)
  select v_id,
         (m ->> 'user_id')::uuid,
         coalesce(array(select jsonb_array_elements_text(coalesce(m -> 'teach', '[]'::jsonb))), '{}'),
         coalesce(array(select jsonb_array_elements_text(coalesce(m -> 'learn', '[]'::jsonb))), '{}')
  from jsonb_array_elements(p_members) m;

  update public.match_queue set status = 'proposed', proposal_id = v_id where user_id = any (v_ids);
  return v_id;
end $$;

-- Housekeeping: expire timed-out proposals and drop long-stale queue rows.
create or replace function public.am_expire_proposals()
returns integer language plpgsql security definer set search_path = public as $$
declare
  r record;
  n integer := 0;
begin
  for r in
    select id from public.match_proposals
    where status = 'pending' and expires_at < now() - interval '3 seconds'
    for update skip locked
  loop
    perform public.am_resolve_proposal(r.id, 'expired');
    n := n + 1;
  end loop;
  delete from public.match_queue where status = 'waiting' and last_seen < now() - interval '2 minutes';
  return n;
end $$;

revoke execute on function public.am_join_queue(text, boolean) from public, anon;
revoke execute on function public.am_heartbeat() from public, anon;
revoke execute on function public.am_respond_proposal(uuid, boolean) from public, anon;
revoke execute on function public.am_leave_queue() from public, anon;
revoke execute on function public.am_is_proposal_member(uuid) from public, anon;
revoke execute on function public.am_resolve_proposal(uuid, text) from public, anon, authenticated;
revoke execute on function public.am_claim_proposal(text, jsonb) from public, anon, authenticated;
revoke execute on function public.am_expire_proposals() from public, anon, authenticated;
grant execute on function public.am_is_proposal_member(uuid) to authenticated;
grant execute on function public.am_join_queue(text, boolean) to authenticated;
grant execute on function public.am_heartbeat() to authenticated;
grant execute on function public.am_respond_proposal(uuid, boolean) to authenticated;
grant execute on function public.am_leave_queue() to authenticated;
grant execute on function public.am_resolve_proposal(uuid, text) to service_role;
grant execute on function public.am_claim_proposal(text, jsonb) to service_role;
grant execute on function public.am_expire_proposals() to service_role;
