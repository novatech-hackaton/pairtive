-- Pairtive sessions: live calls, membership, live notes, realtime channel authorization.

create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  proposal_id uuid unique references public.match_proposals (id) on delete set null,
  invite_id uuid unique,
  mode text not null check (mode in ('buddy', 'peers')),
  daily_room_name text,
  daily_room_url text,
  created_at timestamptz not null default now(),
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create table public.session_members (
  session_id uuid not null references public.sessions (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  teach_subjects text[] not null default '{}',
  learn_subjects text[] not null default '{}',
  joined_at timestamptz,
  left_at timestamptz,
  primary key (session_id, user_id)
);
create index am_session_members_user_idx on public.session_members (user_id);

create or replace function public.am_is_session_member(p_session uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.session_members where session_id = p_session and user_id = auth.uid())
$$;

alter table public.sessions enable row level security;
alter table public.session_members enable row level security;

create policy "am sessions: members read" on public.sessions for select to authenticated
  using (public.am_is_session_member(id));
create policy "am session members: members read" on public.session_members for select to authenticated
  using (public.am_is_session_member(session_id));

revoke insert, update, delete on public.sessions, public.session_members from anon, authenticated;
revoke select on public.sessions, public.session_members from anon;

-- ---------------------------------------------------------------------------
-- Stats: sessions_count, success_count/rate (success = stayed >= 1 min, no confirmed report)
-- reports table is created in a later migration; plpgsql resolves it at run time.
-- ---------------------------------------------------------------------------
create or replace function public.am_recompute_stats(p_uid uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_total integer;
  v_success integer;
begin
  select count(*),
         count(*) filter (
           where sm.joined_at is not null
             and sm.left_at - sm.joined_at >= interval '60 seconds'
             and not exists (
               select 1 from public.reports r
               where r.reported_id = p_uid and r.session_id = sm.session_id and r.ai_verdict = 'confirmed'
             )
         )
    into v_total, v_success
  from public.session_members sm
  where sm.user_id = p_uid and sm.left_at is not null;

  update public.profiles
  set sessions_count = v_total,
      success_count = v_success,
      success_rate = case when v_total > 0 then round(v_success::numeric / v_total, 3) else 0 end
  where id = p_uid;
end $$;

-- Called when the Daily call is actually joined (used for fair rating eligibility).
create or replace function public.am_mark_joined(p_session uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.session_members set joined_at = coalesce(joined_at, now())
  where session_id = p_session and user_id = auth.uid();
end $$;

-- Stop / Next / closing the tab. Returns seconds the caller was in the call.
create or replace function public.am_leave_session(p_session uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare
  v_member public.session_members;
begin
  update public.session_members set left_at = coalesce(left_at, now())
  where session_id = p_session and user_id = auth.uid()
  returning * into v_member;
  if not found then raise exception 'Not in this session'; end if;

  if not exists (select 1 from public.session_members where session_id = p_session and left_at is null) then
    update public.sessions set ended_at = coalesce(ended_at, now()) where id = p_session;
  end if;

  delete from public.match_queue where user_id = auth.uid() and status = 'in_session';
  perform public.am_recompute_stats(auth.uid());

  if v_member.joined_at is null then return 0; end if;
  return extract(epoch from (v_member.left_at - v_member.joined_at))::integer;
end $$;

-- ---------------------------------------------------------------------------
-- Live notes (Yjs snapshot + plain text copy for later viewing)
-- ---------------------------------------------------------------------------
create table public.session_notes (
  session_id uuid primary key references public.sessions (id) on delete cascade,
  content text not null default '' check (char_length(content) <= 50000),
  ydoc text check (ydoc is null or char_length(ydoc) <= 400000),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id) on delete set null
);

alter table public.session_notes enable row level security;
create policy "am notes: members read" on public.session_notes for select to authenticated
  using (public.am_is_session_member(session_id));
create policy "am notes: members insert" on public.session_notes for insert to authenticated
  with check (public.am_is_session_member(session_id) and updated_by = auth.uid());
create policy "am notes: members update" on public.session_notes for update to authenticated
  using (public.am_is_session_member(session_id))
  with check (public.am_is_session_member(session_id) and updated_by = auth.uid());
revoke delete on public.session_notes from anon, authenticated;
revoke all on public.session_notes from anon;

-- ---------------------------------------------------------------------------
-- Private Realtime channels "session:<uuid>" (live notes sync) - members only
-- ---------------------------------------------------------------------------
create or replace function public.am_session_topic_member(p_topic text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare v_id uuid;
begin
  if p_topic is null or p_topic !~ '^session:[0-9a-fA-F-]{36}$' then return false; end if;
  v_id := public.am_try_uuid(substring(p_topic from 9));
  if v_id is null then return false; end if;
  return public.am_is_session_member(v_id);
end $$;

create policy "am realtime: session members receive" on realtime.messages for select to authenticated
  using (public.am_session_topic_member(realtime.topic()));
create policy "am realtime: session members send" on realtime.messages for insert to authenticated
  with check (public.am_session_topic_member(realtime.topic()));

revoke execute on function public.am_recompute_stats(uuid) from public, anon, authenticated;
revoke execute on function public.am_is_session_member(uuid) from public, anon;
revoke execute on function public.am_session_topic_member(text) from public, anon;
revoke execute on function public.am_mark_joined(uuid) from public, anon;
revoke execute on function public.am_leave_session(uuid) from public, anon;
grant execute on function public.am_recompute_stats(uuid) to service_role;
grant execute on function public.am_mark_joined(uuid) to authenticated;
grant execute on function public.am_leave_session(uuid) to authenticated;
grant execute on function public.am_session_topic_member(text) to authenticated;
grant execute on function public.am_is_session_member(uuid) to authenticated;
