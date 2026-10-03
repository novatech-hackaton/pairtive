-- dsschema.sql
-- Diagnostic Assessment and SkillGPS â€” Database Schema
--
-- Paste this script into the Supabase SQL Editor and run it once on a new
-- project. It creates the seven tables with their primary keys, foreign keys,
-- non-null columns, defaults, check constraints, and unique constraints.
--
-- Row Level Security policies are added separately (see task 1.2); this script
-- defines only the table structure and data-integrity constraints
-- (Requirements 2.1-2.16).
--
-- `gen_random_uuid()` is provided by the pgcrypto extension, which is available
-- by default on Supabase. The explicit create keeps the script self-contained.
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Reference tables
-- ---------------------------------------------------------------------------

-- programs (Req 2.1)
create table if not exists public.programs (
  id            uuid primary key default gen_random_uuid(),
  program_name  text not null,
  program_code  text not null unique
);

-- subjects (Req 2.2)
create table if not exists public.subjects (
  id            uuid primary key default gen_random_uuid(),
  program_id    uuid not null references public.programs (id),
  subject_name  text not null
);

-- topics (Req 2.3)
create table if not exists public.topics (
  id          uuid primary key default gen_random_uuid(),
  subject_id  uuid not null references public.subjects (id),
  topic_name  text not null,
  description text,
  constraint topics_subject_topic_unique unique (subject_id, topic_name)
);

-- diagnostic_questions (Req 2.4, 2.5, 2.6)
create table if not exists public.diagnostic_questions (
  id             uuid primary key default gen_random_uuid(),
  topic_id       uuid not null references public.topics (id),
  question       text not null,
  choice_a       text not null,
  choice_b       text not null,
  choice_c       text not null,
  choice_d       text not null,
  correct_answer text not null,
  explanation    text not null,
  difficulty     integer not null,
  constraint diagnostic_questions_correct_answer_check
    check (correct_answer in ('A', 'B', 'C', 'D')),
  constraint diagnostic_questions_difficulty_check
    check (difficulty between 1 and 3)
);

-- ---------------------------------------------------------------------------
-- Student-data tables
-- ---------------------------------------------------------------------------

-- diagnostic_attempts (Req 2.7, 2.11, 2.12, 2.15)
-- An attempt is created at session start (completed_at and the scoring/mastery
-- columns null) and filled in on completion and prediction, so those columns
-- are nullable. Check constraints only apply when the value is non-null.
create table if not exists public.diagnostic_attempts (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users (id),
  subject_id          uuid not null references public.subjects (id),
  topic_id            uuid not null references public.topics (id),
  started_at          timestamptz not null default now(),
  completed_at        timestamptz,
  total_questions     integer,
  correct_answers     integer,
  accuracy            numeric,
  mastery_probability numeric,
  mastery_level       text,
  constraint diagnostic_attempts_total_questions_check
    check (total_questions is null or total_questions between 1 and 20),
  constraint diagnostic_attempts_correct_answers_check
    check (correct_answers is null
           or (correct_answers >= 0 and correct_answers <= total_questions)),
  constraint diagnostic_attempts_accuracy_check
    check (accuracy is null or (accuracy >= 0 and accuracy <= 1)),
  constraint diagnostic_attempts_mastery_probability_check
    check (mastery_probability is null
           or (mastery_probability >= 0 and mastery_probability <= 1)),
  constraint diagnostic_attempts_mastery_level_check
    check (mastery_level is null
           or mastery_level in ('Weak', 'Developing', 'Proficient'))
);

-- diagnostic_answers (Req 2.8, 2.5, 2.9)
-- response_time is stored in seconds and accepts fractional values; it must be
-- strictly greater than 0. The (attempt_id, question_id) pair is unique.
create table if not exists public.diagnostic_answers (
  id              uuid primary key default gen_random_uuid(),
  attempt_id      uuid not null references public.diagnostic_attempts (id),
  user_id         uuid not null references auth.users (id),
  question_id     uuid not null references public.diagnostic_questions (id),
  topic_id        uuid not null references public.topics (id),
  selected_answer text not null,
  correct_answer  text not null,
  is_correct      boolean not null,
  response_time   numeric not null,
  created_at      timestamptz not null default now(),
  constraint diagnostic_answers_selected_answer_check
    check (selected_answer in ('A', 'B', 'C', 'D')),
  constraint diagnostic_answers_correct_answer_check
    check (correct_answer in ('A', 'B', 'C', 'D')),
  constraint diagnostic_answers_response_time_check
    check (response_time > 0),
  constraint diagnostic_answers_attempt_question_unique
    unique (attempt_id, question_id)
);

-- student_topic_mastery (Req 2.10, 2.11, 2.12, 2.15)
-- The (user_id, topic_id) pair is unique so the frontend can upsert the latest
-- mastery for a topic idempotently. mastery_probability is nullable; the check
-- constraints apply only when their columns are non-null.
create table if not exists public.student_topic_mastery (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users (id),
  topic_id              uuid not null references public.topics (id),
  mastery_probability   numeric,
  mastery_level         text,
  ml_predicted_label    text,
  ml_confidence         numeric,
  total_questions       integer,
  correct_answers       integer,
  accuracy              numeric,
  average_response_time numeric,
  updated_at            timestamptz not null default now(),
  constraint student_topic_mastery_user_topic_unique
    unique (user_id, topic_id),
  constraint student_topic_mastery_mastery_probability_check
    check (mastery_probability is null
           or (mastery_probability >= 0 and mastery_probability <= 1)),
  constraint student_topic_mastery_accuracy_check
    check (accuracy is null or (accuracy >= 0 and accuracy <= 1)),
  constraint student_topic_mastery_ml_confidence_check
    check (ml_confidence is null
           or (ml_confidence >= 0 and ml_confidence <= 1)),
  constraint student_topic_mastery_mastery_level_check
    check (mastery_level is null
           or mastery_level in ('Weak', 'Developing', 'Proficient')),
  constraint student_topic_mastery_ml_predicted_label_check
    check (ml_predicted_label is null
           or ml_predicted_label in ('Weak', 'Developing', 'Proficient')),
  constraint student_topic_mastery_total_questions_check
    check (total_questions is null or total_questions between 1 and 20),
  constraint student_topic_mastery_correct_answers_check
    check (correct_answers is null
           or (correct_answers >= 0 and correct_answers <= total_questions)),
  constraint student_topic_mastery_average_response_time_check
    check (average_response_time is null or average_response_time > 0)
);

-- ===========================================================================
-- Row Level Security — ANONYMOUS ACCESS (login removed)
-- ===========================================================================
--
-- NOTE: Authentication was removed from the app by request, so these policies
-- grant the `anon` role full access. This makes all data readable and writable
-- by anyone holding the Anon_Key. It is intended for a local/demo build only
-- and is NOT a production security model. To restore per-user security,
-- revert this section to the owner-only (`user_id = auth.uid()`) policies.
--
-- RLS stays ENABLED on every table; the policies below simply allow the anon
-- (and authenticated) roles. Reference tables remain read-only; student-data
-- tables allow select/insert/update but no delete.

-- Enable RLS on all seven tables.
alter table public.programs                enable row level security;
alter table public.subjects               enable row level security;
alter table public.topics                 enable row level security;
alter table public.diagnostic_questions   enable row level security;
alter table public.diagnostic_attempts    enable row level security;
alter table public.diagnostic_answers     enable row level security;
alter table public.student_topic_mastery  enable row level security;

-- Roles allowed without a login. `anon` is the Supabase unauthenticated role;
-- `authenticated` is kept so the app still works if a session ever exists.
-- (Policies are defined for both via the `public` pseudo-role.)

-- ---- Reference tables: public SELECT only (no writes for anyone) ----------
drop policy if exists programs_select_public on public.programs;
create policy programs_select_public on public.programs for select to anon, authenticated using (true);

drop policy if exists subjects_select_public on public.subjects;
create policy subjects_select_public on public.subjects for select to anon, authenticated using (true);

drop policy if exists topics_select_public on public.topics;
create policy topics_select_public on public.topics for select to anon, authenticated using (true);

drop policy if exists diagnostic_questions_select_public on public.diagnostic_questions;
create policy diagnostic_questions_select_public on public.diagnostic_questions for select to anon, authenticated using (true);

-- ---- Student-data tables: public SELECT/INSERT/UPDATE, no DELETE ----------
-- diagnostic_attempts
drop policy if exists diagnostic_attempts_select_public on public.diagnostic_attempts;
create policy diagnostic_attempts_select_public on public.diagnostic_attempts for select to anon, authenticated using (true);
drop policy if exists diagnostic_attempts_insert_public on public.diagnostic_attempts;
create policy diagnostic_attempts_insert_public on public.diagnostic_attempts for insert to anon, authenticated with check (true);
drop policy if exists diagnostic_attempts_update_public on public.diagnostic_attempts;
create policy diagnostic_attempts_update_public on public.diagnostic_attempts for update to anon, authenticated using (true) with check (true);

-- diagnostic_answers
drop policy if exists diagnostic_answers_select_public on public.diagnostic_answers;
create policy diagnostic_answers_select_public on public.diagnostic_answers for select to anon, authenticated using (true);
drop policy if exists diagnostic_answers_insert_public on public.diagnostic_answers;
create policy diagnostic_answers_insert_public on public.diagnostic_answers for insert to anon, authenticated with check (true);
drop policy if exists diagnostic_answers_update_public on public.diagnostic_answers;
create policy diagnostic_answers_update_public on public.diagnostic_answers for update to anon, authenticated using (true) with check (true);

-- student_topic_mastery
drop policy if exists student_topic_mastery_select_public on public.student_topic_mastery;
create policy student_topic_mastery_select_public on public.student_topic_mastery for select to anon, authenticated using (true);
drop policy if exists student_topic_mastery_insert_public on public.student_topic_mastery;
create policy student_topic_mastery_insert_public on public.student_topic_mastery for insert to anon, authenticated with check (true);
drop policy if exists student_topic_mastery_update_public on public.student_topic_mastery;
create policy student_topic_mastery_update_public on public.student_topic_mastery for update to anon, authenticated using (true) with check (true);

-- ===========================================================================
-- Table privileges for the anon role (login removed / demo access)
-- ===========================================================================
-- RLS policies decide WHICH ROWS a role sees, but the role still needs a
-- base table-level GRANT to access the table at all. Supabase grants these to
-- `authenticated` by default but NOT to `anon`, so without these the anon key
-- gets "permission denied" (SQLSTATE 42501) before RLS is evaluated.
-- Reference tables: SELECT only. Student-data tables: SELECT/INSERT/UPDATE
-- (no DELETE), matching the RLS policies above. Remove these grants when
-- restoring authenticated-only access for integration.
grant select on public.programs             to anon;
grant select on public.subjects             to anon;
grant select on public.topics               to anon;
grant select on public.diagnostic_questions to anon;
grant select, insert, update on public.diagnostic_attempts   to anon;
grant select, insert, update on public.diagnostic_answers    to anon;
grant select, insert, update on public.student_topic_mastery to anon;
