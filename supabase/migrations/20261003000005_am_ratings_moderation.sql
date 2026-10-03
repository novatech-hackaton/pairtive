-- Pairtive ratings + reports, strikes, warnings (AI-verified, no admin page).

-- ---------------------------------------------------------------------------
-- Ratings
-- ---------------------------------------------------------------------------
create table public.ratings (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions (id) on delete cascade,
  rater_id uuid not null references public.profiles (id) on delete cascade,
  ratee_id uuid not null references public.profiles (id) on delete cascade,
  stars smallint not null check (stars between 1 and 5),
  tags text[] not null default '{}' check (tags <@ array['Helpful', 'Patient', 'Clear', 'Knowledgeable']::text[]),
  comment text check (comment is null or char_length(comment) <= 500),
  created_at timestamptz not null default now(),
  unique (session_id, rater_id, ratee_id),
  check (rater_id <> ratee_id)
);
create index am_ratings_ratee_idx on public.ratings (ratee_id);

-- Both were in the call together for at least 1 minute, rated within 24h.
create or replace function public.am_can_rate(p_session uuid, p_ratee uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.session_members r
    join public.session_members e on e.session_id = r.session_id and e.user_id = p_ratee
    join public.sessions s on s.id = r.session_id
    where r.session_id = p_session and r.user_id = auth.uid() and p_ratee <> auth.uid()
      and r.joined_at is not null and e.joined_at is not null
      and s.started_at > now() - interval '24 hours'
      and least(coalesce(r.left_at, now()), coalesce(e.left_at, now())) - greatest(r.joined_at, e.joined_at)
          >= interval '60 seconds'
  )
$$;

alter table public.ratings enable row level security;
create policy "am ratings: read own given/received" on public.ratings for select to authenticated
  using (rater_id = auth.uid() or ratee_id = auth.uid());
create policy "am ratings: rate session partners" on public.ratings for insert to authenticated
  with check (rater_id = auth.uid() and public.am_can_rate(session_id, ratee_id));
revoke update, delete on public.ratings from anon, authenticated;
revoke all on public.ratings from anon;

create or replace function public.am_on_rating()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.profiles p
  set rating_avg = coalesce((select round(avg(stars)::numeric, 2) from public.ratings where ratee_id = new.ratee_id), 0),
      rating_count = (select count(*) from public.ratings where ratee_id = new.ratee_id)
  where p.id = new.ratee_id;
  return new;
end $$;
create trigger am_ratings_aggregate after insert on public.ratings
  for each row execute function public.am_on_rating();

-- ---------------------------------------------------------------------------
-- Reports, strikes, warnings
-- ---------------------------------------------------------------------------
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reported_id uuid not null references public.profiles (id) on delete cascade,
  session_id uuid references public.sessions (id) on delete set null,
  conversation_id uuid references public.conversations (id) on delete set null,
  reason text not null check (reason in ('inappropriate', 'harassment', 'spam', 'no_show', 'other')),
  note text check (note is null or char_length(note) <= 500),
  evidence_paths text[] not null default '{}',
  ai_score numeric(4, 3),
  ai_verdict text not null default 'pending'
    check (ai_verdict in ('pending', 'confirmed', 'uncertain', 'rejected', 'stored')),
  ai_details jsonb not null default '{}',
  counted_in_strike boolean not null default false,
  created_at timestamptz not null default now(),
  verified_at timestamptz,
  check (reporter_id <> reported_id)
);
create index am_reports_reported_idx on public.reports (reported_id, created_at desc);
create index am_reports_reporter_idx on public.reports (reporter_id, created_at desc);

create table public.strikes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  report_id uuid unique references public.reports (id) on delete set null,
  created_at timestamptz not null default now()
);
create index am_strikes_user_idx on public.strikes (user_id, created_at desc);

create table public.warnings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  report_id uuid references public.reports (id) on delete set null,
  message text not null,
  created_at timestamptz not null default now(),
  seen_at timestamptz
);
create index am_warnings_user_idx on public.warnings (user_id, created_at desc);

alter table public.reports enable row level security;
alter table public.strikes enable row level security;
alter table public.warnings enable row level security;

create policy "am reports: reporter reads own" on public.reports for select to authenticated
  using (reporter_id = auth.uid());
create policy "am strikes: read own" on public.strikes for select to authenticated using (user_id = auth.uid());
create policy "am warnings: read own" on public.warnings for select to authenticated using (user_id = auth.uid());
create policy "am warnings: dismiss own" on public.warnings for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

revoke insert, update, delete on public.reports, public.strikes, public.warnings from anon, authenticated;
grant update (seen_at) on public.warnings to authenticated;
revoke all on public.reports, public.strikes, public.warnings from anon;

-- Create a report + immediate block. Rate-limited. Returns the report id.
create or replace function public.am_create_report(
  p_reported uuid,
  p_reason text,
  p_note text default null,
  p_session uuid default null,
  p_conversation uuid default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  if p_reported = auth.uid() then raise exception 'You can''t report yourself'; end if;
  if p_reason not in ('inappropriate', 'harassment', 'spam', 'no_show', 'other') then raise exception 'Pick a reason'; end if;

  if p_session is not null then
    if not exists (select 1 from public.session_members where session_id = p_session and user_id = auth.uid())
       or not exists (select 1 from public.session_members where session_id = p_session and user_id = p_reported) then
      raise exception 'You can only report people from your sessions';
    end if;
  elsif p_conversation is not null then
    if not exists (select 1 from public.conversation_members where conversation_id = p_conversation and user_id = auth.uid())
       or not exists (select 1 from public.conversation_members where conversation_id = p_conversation and user_id = p_reported) then
      raise exception 'You can only report people from your chats';
    end if;
  else
    raise exception 'Report from a session or a chat';
  end if;

  if (select count(*) from public.reports where reporter_id = auth.uid() and created_at > now() - interval '24 hours') >= 10 then
    raise exception 'You have sent a lot of reports today. Please try again tomorrow.';
  end if;
  if exists (
    select 1 from public.reports
    where reporter_id = auth.uid() and reported_id = p_reported
      and coalesce(session_id::text, '') = coalesce(p_session::text, '')
      and created_at > now() - interval '24 hours'
  ) then
    raise exception 'You already reported this person for this session';
  end if;

  insert into public.reports (reporter_id, reported_id, session_id, conversation_id, reason, note)
  values (auth.uid(), p_reported, p_session, p_conversation, p_reason, nullif(left(trim(coalesce(p_note, '')), 500), ''))
  returning id into v_id;

  insert into public.blocks (blocker_id, blocked_id) values (auth.uid(), p_reported) on conflict do nothing;
  return v_id;
end $$;

-- Evidence frames bucket: reporter can upload to <report_id>/ for 10 minutes; nobody can read
-- except the service role (used by /api/amReportVerify).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('report-evidence', 'report-evidence', false, 2097152, array['image/jpeg'])
on conflict (id) do nothing;

create or replace function public.am_can_upload_evidence(p_folder text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.reports
    where id = public.am_try_uuid(p_folder) and reporter_id = auth.uid()
      and ai_verdict = 'pending' and created_at > now() - interval '10 minutes'
  )
$$;

create policy "am evidence: reporter uploads" on storage.objects for insert to authenticated
  with check (bucket_id = 'report-evidence' and public.am_can_upload_evidence((storage.foldername(name))[1]));

revoke execute on function public.am_can_rate(uuid, uuid) from public, anon;
revoke execute on function public.am_create_report(uuid, text, text, uuid, uuid) from public, anon;
revoke execute on function public.am_can_upload_evidence(text) from public, anon;
revoke execute on function public.am_on_rating() from public, anon, authenticated;
grant execute on function public.am_can_rate(uuid, uuid) to authenticated;
grant execute on function public.am_create_report(uuid, text, text, uuid, uuid) to authenticated;
grant execute on function public.am_can_upload_evidence(text) to authenticated;
