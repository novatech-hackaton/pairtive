-- Pairtive core: profiles, blocks, helpers, avatars bucket.
-- (gen_random_uuid() is built into Postgres 13+, no extension needed.)

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function public.am_valid_subjects(arr text[])
returns boolean language sql immutable as $$
  select coalesce(arr, '{}') <@ array['Math','English','Science','Filipino','History','Programming']::text[]
$$;

create or replace function public.am_try_uuid(p text)
returns uuid language plpgsql immutable as $$
begin
  return p::uuid;
exception when others then
  return null;
end $$;

create or replace function public.am_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '' check (char_length(name) <= 60),
  avatar_url text check (avatar_url is null or char_length(avatar_url) <= 500),
  school text not null default '' check (char_length(school) <= 120),
  languages text[] not null default '{}',
  weak_subjects text[] not null default '{}',
  strong_subjects text[] not null default '{}',
  onboarded boolean not null default false,
  rules_accepted_at timestamptz,
  rating_avg numeric(3, 2) not null default 0,
  rating_count integer not null default 0,
  success_count integer not null default 0,
  success_rate numeric(4, 3) not null default 0,
  sessions_count integer not null default 0,
  status text not null default 'active' check (status in ('active', 'suspended')),
  suspended_until timestamptz,
  suspension_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint am_profiles_subjects_check check (
    public.am_valid_subjects(weak_subjects)
    and public.am_valid_subjects(strong_subjects)
    and not (weak_subjects && strong_subjects)
    and cardinality(weak_subjects) <= 3
    and cardinality(strong_subjects) <= 3
    and cardinality(languages) <= 5
  ),
  constraint am_profiles_onboarded_check check (
    not onboarded or (
      cardinality(weak_subjects) >= 1
      and cardinality(strong_subjects) >= 1
      and cardinality(languages) >= 1
      and char_length(trim(name)) >= 2
      and char_length(trim(school)) >= 2
    )
  )
);

create trigger am_profiles_touch before update on public.profiles
  for each row execute function public.am_touch_updated_at();

-- Auto-create a profile row for every new auth user (email or Google).
create or replace function public.am_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, avatar_url)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''), 60),
    left(new.raw_user_meta_data ->> 'avatar_url', 500)
  )
  on conflict (id) do nothing;
  return new;
end $$;

create trigger am_on_auth_user_created after insert on auth.users
  for each row execute function public.am_handle_new_user();

alter table public.profiles enable row level security;

create policy "am profiles: authenticated can read"
  on public.profiles for select to authenticated using (true);

create policy "am profiles: update own"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Users may only edit their own profile fields, never stats or moderation fields.
revoke insert, update, delete on public.profiles from anon, authenticated;
revoke select on public.profiles from anon;
grant select on public.profiles to authenticated;
grant update (name, avatar_url, school, languages, weak_subjects, strong_subjects, onboarded, rules_accepted_at)
  on public.profiles to authenticated;

create or replace function public.am_is_suspended(p_uid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = p_uid and status = 'suspended' and suspended_until > now()
  )
$$;

-- ---------------------------------------------------------------------------
-- Blocks (created automatically when someone reports; never matched again)
-- ---------------------------------------------------------------------------
create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index am_blocks_blocked_idx on public.blocks (blocked_id);

alter table public.blocks enable row level security;
create policy "am blocks: read own" on public.blocks for select to authenticated using (blocker_id = auth.uid());
revoke insert, update, delete on public.blocks from anon, authenticated;

create or replace function public.am_is_blocked(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  )
$$;

-- ---------------------------------------------------------------------------
-- Avatars bucket (public read, owner write under <uid>/...)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/png', 'image/jpeg', 'image/webp', 'image/gif'])
on conflict (id) do nothing;

create policy "am avatars: read own" on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "am avatars: upload own" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "am avatars: update own" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "am avatars: delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

revoke execute on function public.am_is_suspended(uuid) from public, anon;
revoke execute on function public.am_is_blocked(uuid, uuid) from public, anon;
revoke execute on function public.am_handle_new_user() from public, anon, authenticated;
grant execute on function public.am_is_suspended(uuid) to authenticated, service_role;
grant execute on function public.am_is_blocked(uuid, uuid) to authenticated, service_role;
