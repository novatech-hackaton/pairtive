-- Pairtive diagnostic + SkillGPS: reference tables (programs, subjects, topics, questions),
-- student tables (attempts, answers, topic mastery), owner-scoped RLS and grants.
-- Ported from modules/diagnostic-skillgps/supabase/dsschema.sql. The module's anon access
-- ("login removed") is replaced by authenticated, owner-scoped policies; anon gets nothing.
-- (gen_random_uuid() is built into Postgres 13+, no pgcrypto needed.)

-- ---------------------------------------------------------------------------
-- Reference tables (seeded by 20261003000008_am_diagnostic_seed.sql)
-- ---------------------------------------------------------------------------
create table public.programs (
  id uuid primary key default gen_random_uuid(),
  program_name text not null,
  program_code text not null unique
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs (id),
  subject_name text not null,
  constraint subjects_program_subject_unique unique (program_id, subject_name)
);

create table public.topics (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects (id),
  topic_name text not null,
  description text,
  constraint topics_subject_topic_unique unique (subject_id, topic_name),
  -- Each Skill_Label (topic_name) identifies exactly one topic.
  constraint am_topics_topic_name_unique unique (topic_name)
);

create table public.diagnostic_questions (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics (id),
  question text not null,
  choice_a text not null,
  choice_b text not null,
  choice_c text not null,
  choice_d text not null,
  correct_answer text not null,
  explanation text not null,
  difficulty integer not null,
  constraint diagnostic_questions_correct_answer_check check (correct_answer in ('A', 'B', 'C', 'D')),
  constraint diagnostic_questions_difficulty_check check (difficulty between 1 and 3),
  constraint diagnostic_questions_topic_question_unique unique (topic_id, question)
);
create index am_diagnostic_questions_topic_idx on public.diagnostic_questions (topic_id);

-- ---------------------------------------------------------------------------
-- Student tables
-- ---------------------------------------------------------------------------
-- An attempt is created at Start (completed_at and the scoring columns null) and
-- filled in after prediction, so those columns are nullable.
create table public.diagnostic_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_id uuid not null references public.subjects (id),
  topic_id uuid not null references public.topics (id),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  total_questions integer,
  correct_answers integer,
  accuracy numeric,
  mastery_probability numeric,
  mastery_level text,
  constraint diagnostic_attempts_total_questions_check
    check (total_questions is null or total_questions between 1 and 20),
  constraint diagnostic_attempts_correct_answers_check
    check (correct_answers is null or (correct_answers >= 0 and correct_answers <= total_questions)),
  constraint diagnostic_attempts_accuracy_check
    check (accuracy is null or (accuracy >= 0 and accuracy <= 1)),
  constraint diagnostic_attempts_mastery_probability_check
    check (mastery_probability is null or (mastery_probability >= 0 and mastery_probability <= 1)),
  constraint diagnostic_attempts_mastery_level_check
    check (mastery_level is null or mastery_level in ('Weak', 'Developing', 'Proficient'))
);
create index am_diagnostic_attempts_user_topic_idx on public.diagnostic_attempts (user_id, topic_id);

-- response_time is in seconds (fractional allowed) and must be > 0.
create table public.diagnostic_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.diagnostic_attempts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  question_id uuid not null references public.diagnostic_questions (id),
  topic_id uuid not null references public.topics (id),
  selected_answer text not null,
  correct_answer text not null,
  is_correct boolean not null,
  response_time numeric not null,
  created_at timestamptz not null default now(),
  constraint diagnostic_answers_selected_answer_check check (selected_answer in ('A', 'B', 'C', 'D')),
  constraint diagnostic_answers_correct_answer_check check (correct_answer in ('A', 'B', 'C', 'D')),
  constraint diagnostic_answers_response_time_check check (response_time > 0),
  constraint diagnostic_answers_attempt_question_unique unique (attempt_id, question_id)
);
create index am_diagnostic_answers_user_idx on public.diagnostic_answers (user_id);

-- One Mastery_Record per (user, topic), upserted on every (re)take. Rows are only
-- written after a successful prediction, so probability and level are required.
create table public.student_topic_mastery (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  topic_id uuid not null references public.topics (id),
  mastery_probability numeric not null,
  mastery_level text not null,
  ml_predicted_label text,
  ml_confidence numeric,
  total_questions integer,
  correct_answers integer,
  accuracy numeric,
  average_response_time numeric,
  updated_at timestamptz not null default now(),
  constraint student_topic_mastery_user_topic_unique unique (user_id, topic_id),
  constraint student_topic_mastery_mastery_probability_check
    check (mastery_probability >= 0 and mastery_probability <= 1),
  constraint student_topic_mastery_mastery_level_check
    check (mastery_level in ('Weak', 'Developing', 'Proficient')),
  constraint student_topic_mastery_ml_predicted_label_check
    check (ml_predicted_label is null or ml_predicted_label in ('Weak', 'Developing', 'Proficient')),
  constraint student_topic_mastery_ml_confidence_check
    check (ml_confidence is null or (ml_confidence >= 0 and ml_confidence <= 1)),
  constraint student_topic_mastery_total_questions_check
    check (total_questions is null or total_questions between 1 and 20),
  constraint student_topic_mastery_correct_answers_check
    check (correct_answers is null or (correct_answers >= 0 and correct_answers <= total_questions)),
  constraint student_topic_mastery_accuracy_check
    check (accuracy is null or (accuracy >= 0 and accuracy <= 1)),
  constraint student_topic_mastery_average_response_time_check
    check (average_response_time is null or average_response_time > 0)
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.programs enable row level security;
alter table public.subjects enable row level security;
alter table public.topics enable row level security;
alter table public.diagnostic_questions enable row level security;
alter table public.diagnostic_attempts enable row level security;
alter table public.diagnostic_answers enable row level security;
alter table public.student_topic_mastery enable row level security;

-- Reference tables: read-only for signed-in users.
create policy "am ref: authenticated read" on public.programs for select to authenticated using (true);
create policy "am ref: authenticated read" on public.subjects for select to authenticated using (true);
create policy "am ref: authenticated read" on public.topics for select to authenticated using (true);
create policy "am ref: authenticated read" on public.diagnostic_questions for select to authenticated using (true);

-- Student tables: owners read, insert and update their own rows. No delete policy,
-- so attempt and answer history is retained across retakes.
create policy "am diag: read own" on public.diagnostic_attempts for select to authenticated
  using (user_id = auth.uid());
create policy "am diag: insert own" on public.diagnostic_attempts for insert to authenticated
  with check (user_id = auth.uid());
create policy "am diag: update own" on public.diagnostic_attempts for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Answers additionally require the parent attempt to be the caller's.
create policy "am diag: read own" on public.diagnostic_answers for select to authenticated
  using (user_id = auth.uid());
create policy "am diag: insert own" on public.diagnostic_answers for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.diagnostic_attempts a
      where a.id = diagnostic_answers.attempt_id and a.user_id = auth.uid()
    )
  );
create policy "am diag: update own" on public.diagnostic_answers for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.diagnostic_attempts a
      where a.id = diagnostic_answers.attempt_id and a.user_id = auth.uid()
    )
  );

create policy "am diag: read own" on public.student_topic_mastery for select to authenticated
  using (user_id = auth.uid());
create policy "am diag: insert own" on public.student_topic_mastery for insert to authenticated
  with check (user_id = auth.uid());
create policy "am diag: update own" on public.student_topic_mastery for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Grants (reset Supabase's default table privileges, then grant exactly what is needed)
-- ---------------------------------------------------------------------------
revoke all on public.programs, public.subjects, public.topics, public.diagnostic_questions,
  public.diagnostic_attempts, public.diagnostic_answers, public.student_topic_mastery
  from public, anon, authenticated;

grant select on public.programs, public.subjects, public.topics, public.diagnostic_questions
  to authenticated;
grant select, insert, update on public.diagnostic_attempts, public.diagnostic_answers, public.student_topic_mastery
  to authenticated;
grant all on public.programs, public.subjects, public.topics, public.diagnostic_questions,
  public.diagnostic_attempts, public.diagnostic_answers, public.student_topic_mastery
  to service_role;

-- ---------------------------------------------------------------------------
-- Profiles: subjects_source + branching subject constraints
-- ---------------------------------------------------------------------------
-- subjects_source records where weak/strong_subjects came from. Existing rows default to
-- 'onboarding' and keep the original rules exactly. Only am_apply_mastery_bridge() sets
-- 'diagnostic'; the column-level update grant from am_core is deliberately not changed,
-- so clients cannot write this column.
alter table public.profiles
  add column subjects_source text not null default 'onboarding',
  add constraint am_profiles_subjects_source_check
    check (subjects_source in ('onboarding', 'diagnostic')),
  drop constraint am_profiles_subjects_check,
  drop constraint am_profiles_onboarded_check;

-- Same constraint names as am_core. The onboarding branch keeps every original clause;
-- diagnostic-derived topic-name arrays only need to be disjoint (no vocabulary or count limits).
alter table public.profiles
  add constraint am_profiles_subjects_check check (
    not (weak_subjects && strong_subjects)
    and cardinality(languages) <= 5
    and (
      subjects_source = 'diagnostic'
      or (
        public.am_valid_subjects(weak_subjects)
        and public.am_valid_subjects(strong_subjects)
        and cardinality(weak_subjects) <= 3
        and cardinality(strong_subjects) <= 3
      )
    )
  ),
  add constraint am_profiles_onboarded_check check (
    not onboarded or (
      cardinality(languages) >= 1
      and char_length(trim(name)) >= 2
      and char_length(trim(school)) >= 2
      and (
        subjects_source = 'diagnostic'
        or (cardinality(weak_subjects) >= 1 and cardinality(strong_subjects) >= 1)
      )
    )
  );

-- ---------------------------------------------------------------------------
-- Mastery_Bridge: recompute the caller's profile arrays from all stored Mastery_Records
-- ---------------------------------------------------------------------------
-- Proficient -> strong_subjects, Weak -> weak_subjects, Developing ignored. Labels are
-- topic names, sorted by code unit (collate "C") to match shared/amMasteryBridge.js.
-- A label in both lists is dropped from both (cannot happen while topic_name is unique).
-- OUT names differ from the profile columns to avoid plpgsql ambiguity.
create or replace function public.am_apply_mastery_bridge()
returns table (out_strong text[], out_weak text[])
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_strong text[];
  v_weak text[];
begin
  if v_uid is null then raise exception 'Not signed in'; end if;
  if not exists (select 1 from public.student_topic_mastery m where m.user_id = v_uid) then
    raise exception 'diagnostic-required';
  end if;

  v_strong := array(
    select distinct t.topic_name collate "C" as n
    from public.student_topic_mastery m join public.topics t on t.id = m.topic_id
    where m.user_id = v_uid and m.mastery_level = 'Proficient'
    order by n
  );
  v_weak := array(
    select distinct t.topic_name collate "C" as n
    from public.student_topic_mastery m join public.topics t on t.id = m.topic_id
    where m.user_id = v_uid and m.mastery_level = 'Weak'
    order by n
  );

  update public.profiles p set
    strong_subjects = array(
      select u.s from unnest(v_strong) with ordinality as u (s, i)
      where u.s <> all (v_weak) order by u.i
    ),
    weak_subjects = array(
      select u.s from unnest(v_weak) with ordinality as u (s, i)
      where u.s <> all (v_strong) order by u.i
    ),
    subjects_source = 'diagnostic'
  where p.id = v_uid
  returning p.strong_subjects, p.weak_subjects into out_strong, out_weak;

  return next;
end $$;

revoke execute on function public.am_apply_mastery_bridge() from public, anon;
grant execute on function public.am_apply_mastery_bridge() to authenticated, service_role;
