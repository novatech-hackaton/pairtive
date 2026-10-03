-- Pairtive messaging: lazily-created, de-duplicated threads, attachments, Reconnect invites.

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('direct', 'group')),
  member_key text not null unique, -- sorted member ids joined by ',' (prevents duplicates)
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);
create index am_conversation_members_user_idx on public.conversation_members (user_id);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  session_id uuid references public.sessions (id) on delete set null,
  body text check (body is null or char_length(body) <= 4000),
  attachment_path text check (attachment_path is null or char_length(attachment_path) <= 300),
  attachment_name text check (attachment_name is null or char_length(attachment_name) <= 120),
  attachment_type text check (attachment_type is null or char_length(attachment_type) <= 120),
  attachment_size integer check (attachment_size is null or attachment_size between 1 and 10485760),
  created_at timestamptz not null default now(),
  check (char_length(trim(coalesce(body, ''))) > 0 or attachment_path is not null)
);
create index am_messages_conversation_idx on public.messages (conversation_id, created_at desc);
create index am_messages_sender_session_idx on public.messages (sender_id, session_id);

create or replace function public.am_is_conversation_member(p_conversation uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.conversation_members where conversation_id = p_conversation and user_id = auth.uid()
  )
$$;

-- True when the caller blocked / was blocked by any other member of the conversation.
create or replace function public.am_conversation_blocked(p_conversation uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = p_conversation and cm.user_id <> auth.uid()
      and public.am_is_blocked(auth.uid(), cm.user_id)
  )
$$;

alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

create policy "am conversations: members read" on public.conversations for select to authenticated
  using (public.am_is_conversation_member(id));
create policy "am conversation members: members read" on public.conversation_members for select to authenticated
  using (public.am_is_conversation_member(conversation_id));
create policy "am conversation members: mark read" on public.conversation_members for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "am messages: members read" on public.messages for select to authenticated
  using (public.am_is_conversation_member(conversation_id));
create policy "am messages: members send" on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.am_is_conversation_member(conversation_id)
    and not public.am_conversation_blocked(conversation_id)
    and not public.am_is_suspended(auth.uid())
    and (session_id is null or public.am_is_session_member(session_id))
    and (attachment_path is null or (storage.foldername(attachment_path))[1] = conversation_id::text)
  );

revoke insert, update, delete on public.conversations from anon, authenticated;
revoke insert, update, delete on public.conversation_members from anon, authenticated;
grant update (last_read_at) on public.conversation_members to authenticated;
revoke update, delete on public.messages from anon, authenticated;
revoke all on public.conversations, public.conversation_members, public.messages from anon;

create or replace function public.am_touch_conversation()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.conversations set last_message_at = new.created_at where id = new.conversation_id;
  update public.conversation_members set last_read_at = new.created_at
  where conversation_id = new.conversation_id and user_id = new.sender_id;
  return new;
end $$;
create trigger am_messages_touch after insert on public.messages
  for each row execute function public.am_touch_conversation();

-- Find or create the single thread for this exact set of people. Only called when a
-- message is actually being sent, so threads exist only if a conversation happened.
create or replace function public.am_get_or_create_conversation(p_member_ids uuid[])
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_ids uuid[];
  v_key text;
  v_id uuid;
begin
  if auth.uid() is null then raise exception 'Not signed in'; end if;
  select array_agg(x order by x::text collate "C") into v_ids
  from (select distinct unnest(array_append(coalesce(p_member_ids, '{}'), auth.uid())) as x) s;
  if cardinality(v_ids) < 2 or cardinality(v_ids) > 5 then raise exception 'A thread needs 2 to 5 people'; end if;
  if public.am_is_suspended(auth.uid()) then raise exception 'Your account is suspended'; end if;

  if not exists (
    select 1 from public.session_members sm
    where sm.user_id = any (v_ids)
    group by sm.session_id
    having count(distinct sm.user_id) = cardinality(v_ids)
  ) then
    raise exception 'You can only message people you studied with';
  end if;

  if exists (select 1 from unnest(v_ids) o where o <> auth.uid() and public.am_is_blocked(auth.uid(), o)) then
    raise exception 'You can''t message this person';
  end if;

  v_key := array_to_string(v_ids::text[], ',');
  insert into public.conversations (kind, member_key)
  values (case when cardinality(v_ids) = 2 then 'direct' else 'group' end, v_key)
  on conflict (member_key) do nothing
  returning id into v_id;

  if v_id is null then
    select id into v_id from public.conversations where member_key = v_key;
  else
    insert into public.conversation_members (conversation_id, user_id)
    select v_id, unnest(v_ids)
    on conflict do nothing;
  end if;
  return v_id;
end $$;

-- Messenger list: only threads with at least one message, newest first.
create or replace function public.am_list_conversations()
returns table (
  id uuid,
  kind text,
  last_message_at timestamptz,
  last_body text,
  last_sender_id uuid,
  last_attachment_type text,
  members jsonb,
  unread integer
) language sql stable security definer set search_path = public as $$
  select c.id, c.kind, c.last_message_at, lm.body, lm.sender_id, lm.attachment_type,
    coalesce((
      select jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'avatar_url', p.avatar_url) order by p.name)
      from public.conversation_members cm2 join public.profiles p on p.id = cm2.user_id
      where cm2.conversation_id = c.id and cm2.user_id <> auth.uid()
    ), '[]'::jsonb),
    (select count(*) from public.messages m
      where m.conversation_id = c.id and m.sender_id <> auth.uid()
        and m.created_at > coalesce(cm.last_read_at, 'epoch'::timestamptz))::integer
  from public.conversation_members cm
  join public.conversations c on c.id = cm.conversation_id
  join lateral (
    select m.body, m.sender_id, m.attachment_type from public.messages m
    where m.conversation_id = c.id order by m.created_at desc limit 1
  ) lm on true
  where cm.user_id = auth.uid()
  order by c.last_message_at desc
$$;

-- Notes from sessions every member of this thread attended together.
create or replace function public.am_thread_notes(p_conversation uuid)
returns table (session_id uuid, started_at timestamptz, content text, updated_at timestamptz)
language sql stable security definer set search_path = public as $$
  select s.id, s.started_at, n.content, n.updated_at
  from public.sessions s
  join public.session_notes n on n.session_id = s.id
  where public.am_is_conversation_member(p_conversation)
    and char_length(trim(n.content)) > 0
    and (
      select count(distinct sm.user_id) from public.session_members sm
      join public.conversation_members cm on cm.user_id = sm.user_id and cm.conversation_id = p_conversation
      where sm.session_id = s.id
    ) = (select count(*) from public.conversation_members where conversation_id = p_conversation)
  order by s.started_at desc
  limit 50
$$;

-- ---------------------------------------------------------------------------
-- Chat attachments bucket: private, members of the thread only (<conversation_id>/...)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-attachments', 'chat-attachments', false, 10485760, array[
  'image/png', 'image/jpeg', 'image/gif', 'image/webp',
  'application/pdf', 'text/plain', 'application/zip',
  'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
])
on conflict (id) do nothing;

create policy "am chat files: members read" on storage.objects for select to authenticated
  using (bucket_id = 'chat-attachments'
         and public.am_is_conversation_member(public.am_try_uuid((storage.foldername(name))[1])));
create policy "am chat files: members upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'chat-attachments'
              and public.am_is_conversation_member(public.am_try_uuid((storage.foldername(name))[1]))
              and not public.am_is_suspended(auth.uid()));

-- ---------------------------------------------------------------------------
-- Reconnect invites (bypass matching cooldown on purpose)
-- ---------------------------------------------------------------------------
create table public.session_invites (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  from_user uuid not null references public.profiles (id) on delete cascade,
  mode text not null check (mode in ('buddy', 'peers')),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined', 'cancelled', 'expired')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '10 minutes'
);
create index am_session_invites_conv_idx on public.session_invites (conversation_id, created_at desc);

alter table public.sessions
  add constraint am_sessions_invite_fk foreign key (invite_id) references public.session_invites (id) on delete set null;

alter table public.session_invites enable row level security;
create policy "am invites: members read" on public.session_invites for select to authenticated
  using (public.am_is_conversation_member(conversation_id));
revoke insert, update, delete on public.session_invites from anon, authenticated;
revoke all on public.session_invites from anon;

create or replace function public.am_create_invite(p_conversation uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_kind text;
  v_id uuid;
begin
  if not public.am_is_conversation_member(p_conversation) then raise exception 'Not your thread'; end if;
  if public.am_is_suspended(auth.uid()) then raise exception 'Your account is suspended'; end if;
  if public.am_conversation_blocked(p_conversation) then raise exception 'You can''t call this person'; end if;
  if (select count(*) from public.session_invites where from_user = auth.uid() and created_at > now() - interval '1 hour') >= 20 then
    raise exception 'Too many invites. Try again later.';
  end if;
  select kind into v_kind from public.conversations where id = p_conversation;

  update public.session_invites set status = 'cancelled'
  where conversation_id = p_conversation and from_user = auth.uid() and status = 'pending';

  insert into public.session_invites (conversation_id, from_user, mode)
  values (p_conversation, auth.uid(), case when v_kind = 'direct' then 'buddy' else 'peers' end)
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.am_respond_invite(p_invite uuid, p_accept boolean)
returns text language plpgsql security definer set search_path = public as $$
declare v_inv public.session_invites;
begin
  select * into v_inv from public.session_invites where id = p_invite for update;
  if not found or not public.am_is_conversation_member(v_inv.conversation_id) then raise exception 'Invite not found'; end if;
  if v_inv.from_user = auth.uid() then raise exception 'You sent this invite'; end if;
  if v_inv.expires_at < now() and v_inv.status = 'pending' then
    update public.session_invites set status = 'expired' where id = p_invite;
    return 'expired';
  end if;
  if v_inv.status not in ('pending', 'accepted') then return v_inv.status; end if;
  if p_accept then
    if public.am_is_suspended(auth.uid()) then raise exception 'Your account is suspended'; end if;
    update public.session_invites set status = 'accepted' where id = p_invite;
    return 'accepted';
  end if;
  if v_inv.status = 'pending' and (select kind from public.conversations where id = v_inv.conversation_id) = 'direct' then
    update public.session_invites set status = 'declined' where id = p_invite;
    return 'declined';
  end if;
  return v_inv.status;
end $$;

create or replace function public.am_cancel_invite(p_invite uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.session_invites set status = 'cancelled'
  where id = p_invite and from_user = auth.uid() and status = 'pending';
end $$;

revoke execute on function public.am_is_conversation_member(uuid) from public, anon;
revoke execute on function public.am_conversation_blocked(uuid) from public, anon;
revoke execute on function public.am_get_or_create_conversation(uuid[]) from public, anon;
revoke execute on function public.am_list_conversations() from public, anon;
revoke execute on function public.am_thread_notes(uuid) from public, anon;
revoke execute on function public.am_create_invite(uuid) from public, anon;
revoke execute on function public.am_respond_invite(uuid, boolean) from public, anon;
revoke execute on function public.am_cancel_invite(uuid) from public, anon;
revoke execute on function public.am_touch_conversation() from public, anon, authenticated;
grant execute on function public.am_is_conversation_member(uuid) to authenticated;
grant execute on function public.am_conversation_blocked(uuid) to authenticated;
grant execute on function public.am_get_or_create_conversation(uuid[]) to authenticated;
grant execute on function public.am_list_conversations() to authenticated;
grant execute on function public.am_thread_notes(uuid) to authenticated;
grant execute on function public.am_create_invite(uuid) to authenticated;
grant execute on function public.am_respond_invite(uuid, boolean) to authenticated;
grant execute on function public.am_cancel_invite(uuid) to authenticated;
