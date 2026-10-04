-- Pairtive: subjects are optional at onboarding.
-- Onboarding now collects only the basics (name, school, languages). Strong/weak topics
-- come only from the diagnostic via am_apply_mastery_bridge(), so an onboarded profile
-- may have empty weak_subjects / strong_subjects for any subjects_source.
-- am_profiles_onboarded_check keeps its name; am_profiles_subjects_check is unchanged
-- (empty arrays already pass it, and onboarding-sourced picks keep the AM_SUBJECTS / <= 3 rules).

alter table public.profiles
  drop constraint am_profiles_onboarded_check;

alter table public.profiles
  add constraint am_profiles_onboarded_check check (
    not onboarded or (
      cardinality(languages) >= 1
      and char_length(trim(name)) >= 2
      and char_length(trim(school)) >= 2
    )
  );
