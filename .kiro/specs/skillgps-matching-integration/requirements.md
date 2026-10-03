# Requirements Document

## Introduction

This feature merges the self-contained Diagnostic/SkillGPS module (branch `diagnostic-skillgps-module`, `modules/diagnostic-skillgps/`) into the main Pairtive app and rewires the AI matcher so each user's strengths and weaknesses come from their diagnostic mastery results instead of self-reported picks.

In scope: schema merge with owner-scoped RLS and explicit GRANTs, a Node port of the BKT prediction service, a required diagnostic before matching, a SkillGPS summary and retake entry point on /home, a mastery-to-profile bridge, a new "shared-strong" match rule added alongside complementary matching in both matching modes, a UI re-skin into the main design system, auth integration, and env cleanup.

Out of scope for v1: the Gemini recommendation service (`recommendation-service/dsserver.py`); the local recommendation engine is used instead. Python is not deployed.

## Glossary

- **Pairtive_App**: The main Vite + React 19 client in `src/`, deployed on Vercel together with the `/api` serverless functions.
- **Diagnostic_Page**: The re-skinned per-topic quiz page ported from `dsDiagnostic.jsx`.
- **SkillGPS_Page**: The re-skinned mastery overview page ported from `dsSkillGPS.jsx` (overall mastery %, Strength/Developing/Weak counts, per-topic skill-map bars, recommendations).
- **Home_Page**: The existing `/home` route.
- **Onboarding_Page**: The existing `/onboarding` route.
- **Predict_API**: The new Node Vercel function `api/amPredict.js` that computes a Prediction_Result for one topic.
- **BKT_Reference**: The Python implementation `ml/dsbkt.py` with the fitted parameters stored in `ml/dsmodel.pkl`.
- **Prediction_Result**: The object `{predicted_label, confidence, probabilities{Weak, Developing, Proficient}, mastery_probability}`.
- **Response_Sequence**: The request body `{topic_id, responses: [{is_correct, difficulty}]}` for one topic.
- **Mastery_Classifier**: The ported classifier mapping mastery_probability p to Weak (p < 0.40), Developing (0.40 ≤ p < 0.70) or Proficient (p ≥ 0.70), with thresholds read from the ported threshold config.
- **Mastery_Record**: A row of `student_topic_mastery` (user_id, topic_id, mastery_probability in [0, 1], mastery_level).
- **Student_Data_Tables**: `diagnostic_attempts`, `diagnostic_answers`, `student_topic_mastery`.
- **Reference_Tables**: `programs`, `subjects`, `topics`, `diagnostic_questions`.
- **Schema_Migration**: One or more new timestamp-prefixed SQL files in `supabase/migrations/`.
- **Mastery_Bridge**: The logic that derives `profiles.strong_subjects` and `profiles.weak_subjects` from a user's Mastery_Records.
- **Skill_Label**: The `topics.topic_name` of a Mastery_Record's topic, written into `strong_subjects` / `weak_subjects`.
- **Onboarding_Subject_Rules**: The existing `amValidateSubjects()` rules: every pick is an `AM_SUBJECTS` entry, 1–3 picks per list, no duplicates, and disjoint weak/strong lists.
- **Matcher**: The pure matching core `shared/amMatchScore.js` + `shared/amGroupBuilder.js`, executed by `api/amMatch.js`.
- **Study_Buddy_Mode**: The `buddy` queue mode (pairs).
- **Study_Peers_Mode**: The `peers` queue mode (groups of 3–5).
- **Hard_Filter**: The `amHardFilter()` function in the Matcher.
- **Complementary_Coverage**: `amCoverage(a, b) > 0` or `amCoverage(b, a) > 0`, i.e. one user is strong in at least one of the other's weak Skill_Labels.
- **Shared_Strong_Overlap**: The set of Skill_Labels present in both users' `strong` arrays.
- **Diagnostic_Guard**: The route guard that blocks `/match` for users with zero Mastery_Records.
- **AmGuard**: The existing guard in `src/amApp.jsx` (signed-in + profileComplete + not suspended).
- **Auth_Provider**: The existing `src/lib/amAuth.jsx` session provider.
- **Recommendation_Engine**: The local recommendation builder ported from `dsRecommendationEngine.js`.
- **Test_Suite**: The existing Vitest suite of the main app plus tests added by this feature.

## Requirements

### Requirement 1: Database integration, RLS and grants

**User Story:** As a platform maintainer, I want the module tables merged into the main schema with owner-scoped security, so that diagnostic data is private to each user and works with the sb_secret_/sb_publishable_ key model.

#### Acceptance Criteria

1. THE Schema_Migration SHALL create the Reference_Tables and Student_Data_Tables in the `public` schema of the main database, with `user_id` columns referencing `auth.users(id)`.
2. THE Schema_Migration SHALL enforce `UNIQUE(user_id, topic_id)` on `student_topic_mastery` and constrain `mastery_probability` to the range 0 to 1 and `mastery_level` to the values Weak, Developing and Proficient.
3. THE Schema_Migration SHALL enable RLS on every Student_Data_Table with SELECT, INSERT and UPDATE policies restricted to rows where `user_id = auth.uid()`.
4. THE Schema_Migration SHALL enable RLS on every Reference_Table with a SELECT-only policy for the `authenticated` role.
5. THE Schema_Migration SHALL grant SELECT, INSERT and UPDATE on the Student_Data_Tables and SELECT on the Reference_Tables to the `authenticated` role, and full table privileges on all Student_Data_Tables and Reference_Tables to the `service_role` role.
6. THE Schema_Migration SHALL revoke every privilege and remove every policy granted to the `anon` role on the Student_Data_Tables and Reference_Tables.
7. IF an authenticated user reads or writes a Student_Data_Table row whose `user_id` differs from `auth.uid()`, THEN THE database SHALL return zero rows for the read and reject the write.
8. THE Schema_Migration SHALL load the module seed data (programs, subjects, topics, diagnostic_questions) idempotently, so that re-running the seed produces no duplicate rows.
9. THE Schema_Migration SHALL enforce a unique `topics.topic_name`, so that each Skill_Label identifies exactly one topic.

### Requirement 2: BKT prediction port

**User Story:** As a platform maintainer, I want mastery prediction to run in a Node Vercel function, so that production needs no Python service.

#### Acceptance Criteria

1. WHEN the Predict_API receives a POST with a valid Response_Sequence from an authenticated user, THE Predict_API SHALL return HTTP 200 with a Prediction_Result.
2. THE Predict_API SHALL compute mastery_probability using the BKT update rules of the BKT_Reference and the fitted parameters extracted from `ml/dsmodel.pkl`.
3. FOR ALL valid Response_Sequences, THE Predict_API SHALL return a mastery_probability within 1e-6 of the value the BKT_Reference returns for the same Response_Sequence (parity property).
4. FOR ALL valid Response_Sequences, THE Predict_API SHALL return a mastery_probability in [0, 1], probabilities that each lie in [0, 1] and sum to 1 within 1e-6, and a predicted_label equal to the Mastery_Classifier level of mastery_probability.
5. IF the request body is malformed JSON, lacks `responses`, or contains a response with a non-boolean `is_correct` or an unknown `difficulty`, THEN THE Predict_API SHALL return HTTP 400 with an error message naming the invalid fields.
6. IF the request carries no valid Supabase access token, THEN THE Predict_API SHALL return HTTP 401.
7. IF the request uses a method other than POST, THEN THE Predict_API SHALL return HTTP 405.
8. IF the request body exceeds the configured maximum size, THEN THE Predict_API SHALL return HTTP 413.
9. IF the request's `topic_id` is missing or matches no row in `topics`, THEN THE Predict_API SHALL return HTTP 400 with an error message naming `topic_id`.

### Requirement 3: Required diagnostic before matching

**User Story:** As a learner, I want to take a diagnostic before I can match, so that my matches are based on measured skills.

#### Acceptance Criteria

1. WHILE a signed-in user has zero Mastery_Records, THE Diagnostic_Guard SHALL redirect any navigation to `/match` to the Diagnostic_Page.
2. WHILE a signed-in user has one or more Mastery_Records, THE Diagnostic_Guard SHALL allow navigation to `/match`.
3. IF `api/amMatch.js` receives a queue request from a user with zero Mastery_Records, THEN THE `api/amMatch.js` function SHALL reject the request with HTTP 403 and the reason `diagnostic-required`.
4. WHEN a user submits all answers for a topic on the Diagnostic_Page, THE Pairtive_App SHALL store the attempt and answers, obtain a Prediction_Result from the Predict_API, and upsert the Mastery_Record for that user and topic.
5. WHEN the user finishes the diagnostic, THE Pairtive_App SHALL navigate to the SkillGPS_Page.
6. WHEN the user selects the continue-to-match action on the SkillGPS_Page, THE Pairtive_App SHALL navigate to `/match`.
7. IF the Predict_API call fails, THEN THE Diagnostic_Page SHALL show an error message with a retry action and keep the user's submitted answers.
8. WHEN a user retakes the diagnostic for a topic, THE Pairtive_App SHALL overwrite that topic's Mastery_Record through the `UNIQUE(user_id, topic_id)` upsert.
9. WHEN a user retakes the diagnostic for a topic, THE Pairtive_App SHALL insert a new `diagnostic_attempts` row and new `diagnostic_answers` rows while retaining the user's earlier `diagnostic_attempts` and `diagnostic_answers` rows.

### Requirement 4: SkillGPS summary and retake on Home

**User Story:** As a learner, I want to see my SkillGPS summary on Home and retake the diagnostic, so that I can track and refresh my skill profile.

#### Acceptance Criteria

1. WHILE the user has one or more Mastery_Records, THE Home_Page SHALL display overall mastery %, and the counts of Proficient, Developing and Weak topics.
2. WHILE the user has one or more Mastery_Records, THE Home_Page SHALL display a "Retake Diagnostic" button that navigates to the Diagnostic_Page.
3. WHILE the user has zero Mastery_Records, THE Home_Page SHALL display a "Take Diagnostic" call to action that navigates to the Diagnostic_Page.
4. THE SkillGPS_Page SHALL display recommendations produced by the Recommendation_Engine.
5. FOR ALL non-empty sets of Mastery_Records, THE Home_Page SHALL display Proficient, Developing and Weak counts that sum to the number of Mastery_Records.
6. FOR ALL non-empty sets of Mastery_Records, THE Home_Page SHALL display an overall mastery % equal to the mean mastery_probability × 100 rounded to the nearest integer.

### Requirement 5: Mastery-to-profile bridge

**User Story:** As a learner, I want my profile strengths and weaknesses set from my diagnostic results, so that the matcher uses measured skills.

#### Acceptance Criteria

1. WHEN the user completes or retakes a diagnostic, THE Mastery_Bridge SHALL recompute `profiles.strong_subjects` from the Skill_Labels of all of the user's Proficient Mastery_Records and `profiles.weak_subjects` from the Skill_Labels of all of the user's Weak Mastery_Records.
2. THE Mastery_Bridge SHALL exclude Skill_Labels of Developing Mastery_Records from both `strong_subjects` and `weak_subjects`.
3. FOR ALL sets of Mastery_Records, THE Mastery_Bridge SHALL produce `strong_subjects` and `weak_subjects` arrays that are disjoint and free of duplicates.
4. FOR ALL sets of Mastery_Records, applying the Mastery_Bridge twice SHALL produce the same profile arrays as applying the Mastery_Bridge once (idempotence).
5. IF persisting the profile arrays fails, THEN THE Pairtive_App SHALL show an error message with a retry action and keep the stored Mastery_Records unchanged.
6. WHILE a user has completed onboarding and the user's `strong_subjects` and `weak_subjects` were written by the Mastery_Bridge, THE Pairtive_App SHALL evaluate profile completeness without applying the `AM_SUBJECTS` vocabulary check or the 1–3 pick limit, so that AmGuard keeps granting access for any number of entries, including zero.
7. THE Mastery_Bridge SHALL use the `topics.topic_name` of a Mastery_Record's topic as that record's Skill_Label.
8. WHEN the Mastery_Bridge runs, THE Mastery_Bridge SHALL overwrite any onboarding-entered `strong_subjects` and `weak_subjects` of the user.
9. WHEN a user submits subject picks on the Onboarding_Page, THE Pairtive_App SHALL validate the picks with the unchanged Onboarding_Subject_Rules.
10. THE Schema_Migration SHALL accept diagnostic-derived Skill_Label arrays of any length in `profiles.strong_subjects` and `profiles.weak_subjects`, while keeping the `AM_SUBJECTS` vocabulary and 1–3 pick constraints for onboarding-entered arrays.

### Requirement 6: Matcher changes (shared-strong matching)

**User Story:** As a learner, I want to match with peers who are proficient in the same topic, so that we can practice collaboratively, in addition to teach/learn matches.

#### Acceptance Criteria

1. THE Hard_Filter SHALL accept a pair that has a non-empty Shared_Strong_Overlap and zero Complementary_Coverage in both Study_Buddy_Mode and Study_Peers_Mode, provided every other existing hard-filter check passes.
2. IF a pair has zero Complementary_Coverage and an empty Shared_Strong_Overlap, THEN THE Hard_Filter SHALL reject the pair with reason `no-overlap`.
3. THE Matcher SHALL score every pair with a non-empty Shared_Strong_Overlap with a score in [0, 1] in both Study_Buddy_Mode and Study_Peers_Mode.
4. FOR ALL candidate pairs that differ only in Shared_Strong_Overlap size, THE Matcher SHALL assign a score to the pair with the larger overlap that is greater than or equal to the score of the pair with the smaller overlap (metamorphic property).
5. FOR ALL pairs with an empty Shared_Strong_Overlap, THE Hard_Filter result and Matcher score SHALL equal the results of the pre-change Matcher (backward-compatibility property).
6. THE Matcher SHALL keep the existing one-way relaxation rule (`relaxAfterMs`) for pairs whose only overlap is one-way Complementary_Coverage.
7. WHEN the Matcher forms a match based on Shared_Strong_Overlap, THE Matcher SHALL produce match copy that names the shared Skill_Labels as collaborative practice topics.
8. WHEN a pair has a non-empty Shared_Strong_Overlap, THE Matcher SHALL treat the pair as eligible for matching immediately, without waiting for `relaxAfterMs`.
9. WHEN the Matcher builds a Study_Peers_Mode group, THE Matcher SHALL count a member who shares at least one strong Skill_Label with another group member as having a valid role in the group.

### Requirement 7: UI re-skin and naming

**User Story:** As a learner, I want the Diagnostic and SkillGPS pages to look and feel like the rest of Pairtive, so that the experience is consistent.

#### Acceptance Criteria

1. THE Pairtive_App SHALL place every ported module source file under `src/` (or `shared/` for pure logic) with an `am` filename prefix.
2. THE Diagnostic_Page and SkillGPS_Page SHALL render inside AmLayout and use AmCard and AmButton with the main dark ink/brand theme and the Inter / Plus Jakarta fonts.
3. THE Pairtive_App SHALL register the Diagnostic_Page at `/diagnostic` and the SkillGPS_Page at `/skillgps`, both wrapped in AmGuard.
4. THE Diagnostic_Page SHALL render each answer option as a keyboard-operable control with an accessible label.

### Requirement 8: Auth integration

**User Story:** As a learner, I want diagnostic results saved under my Pairtive account, so that they persist across devices and sessions.

#### Acceptance Criteria

1. THE Pairtive_App SHALL use the single Supabase client in `src/lib/amSupabase.js` for all diagnostic reads and writes.
2. WHEN the Auth_Provider has a signed-in session, THE Pairtive_App SHALL write every Student_Data_Table row with `user_id` equal to the session user's id.
3. THE Pairtive_App SHALL resolve the diagnostic user id only from the Auth_Provider session, with the `window.__DS_USER_ID__` fallback removed.
4. WHEN the user signs out, THE Pairtive_App SHALL clear any cached diagnostic and mastery state from memory.

### Requirement 9: Config and environment cleanup

**User Story:** As a platform maintainer, I want obsolete config removed, so that deployment needs only one Vercel project and no dangling service URLs.

#### Acceptance Criteria

1. THE Pairtive_App SHALL contain no references to `VITE_PREDICTION_API_URL` or `VITE_RECOMMENDATION_SERVICE_URL` in source, `.env.example`, or Vercel config.
2. THE Pairtive_App SHALL call the Predict_API through the same-origin path `/api/amPredict`.
3. THE Pairtive_App SHALL expose only `VITE_`-prefixed publishable values to the client bundle, with service-role keys read only inside `/api` functions.

### Requirement 10: Backward compatibility and non-functional constraints

**User Story:** As a platform maintainer, I want the integration to keep existing behavior and deployment intact, so that current users and tests are unaffected.

#### Acceptance Criteria

1. THE Pairtive_App SHALL deploy as a single Vercel project with no Python runtime in production.
2. WHEN the Test_Suite runs with `vitest --run`, THE Test_Suite SHALL pass, including all pre-existing tests.
3. THE Pairtive_App SHALL keep the existing routes `/login`, `/signup`, `/onboarding`, `/home`, `/match`, `/session/:id`, `/rate/:id`, `/messages` and `/profile` reachable under their current guards.
4. WHILE an existing user who completed onboarding before this feature has zero Mastery_Records, THE Pairtive_App SHALL allow access to every guarded route except `/match`.
5. WHILE an existing user who completed onboarding before this feature has zero Mastery_Records, THE Diagnostic_Guard SHALL redirect navigation to `/match` to the Diagnostic_Page.
6. THE Schema_Migration SHALL leave existing tables, policies, grants and functions unchanged apart from the additions defined in Requirement 1 and the `profiles` changes required by Requirement 5.10.

## Resolved decisions

1. **Shared-strong mode applicability:** shared-strong matching applies to both Study_Buddy_Mode and Study_Peers_Mode (Req 6.1, 6.3, 6.9).
2. **Shared-strong vs. relaxation:** shared-strong pairs are eligible immediately; `relaxAfterMs` gates only one-way Complementary_Coverage pairs (Req 6.6, 6.8).
3. **Skill_Label form:** Skill_Label is `topics.topic_name` (Req 1.9, 5.7). Profile completeness for diagnostic-derived arrays does not depend on the `AM_SUBJECTS` vocabulary or the 1–3 pick limit (Req 5.6, 5.10).
4. **Retake semantics:** a retake overwrites the Mastery_Record per retaken topic through the `UNIQUE(user_id, topic_id)` upsert, keeps `diagnostic_attempts` / `diagnostic_answers` as history, and re-runs the Mastery_Bridge over all of the user's Mastery_Records (Req 3.8, 3.9, 5.1).
5. **Onboarding subject picks:** onboarding stays unchanged for v1; the Mastery_Bridge overwrites `strong_subjects` / `weak_subjects` on diagnostic completion (Req 5.8, 5.9).
