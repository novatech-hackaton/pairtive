-- Enable Realtime postgres_changes for the tables the client listens to (RLS still applies).
do $$
declare t text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
  foreach t in array array[
    'match_queue', 'match_proposals', 'proposal_members', 'messages',
    'conversation_members', 'session_invites', 'warnings', 'session_members'
  ] loop
    if not exists (
      select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
