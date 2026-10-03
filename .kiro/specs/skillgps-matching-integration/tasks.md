# Implementation Plan: SkillGPS Matching Integration

## Overview

This plan implements the design in JavaScript (Node + React 19) on the existing Vite/Vitest stack. It starts with the test tooling and server plumbing, then the database layer, the BKT port and Predict_API, and the pure shared logic. Matcher changes, server gating, and the mastery provider follow. The UI pages and route wiring come last, followed by env cleanup. Each step builds on the previous one, so new code is always reachable from code written earlier or wired in the final routing task.

## Tasks

- [x] 1. Set up test tooling, the legacy oracle, and server plumbing
  - [x] 1.1 Add fast-check and freeze the pre-change matcher as a test oracle
    - Add `fast-check` pinned at exactly `4.10.2` to `devDependencies` in `package.json` and install it
    - Create `tests/fixtures/amLegacyMatcher.js` as a verbatim copy of the current `shared/amMatchScore.js`, `shared/amGroupBuilder.js` and `amIsProfileComplete` from `shared/amSubjects.js`, taken before tasks 8 and 9 change them
    - _Requirements: 5.9, 6.5, 10.2, 10.4_
  - [x] 1.2 Extend `server/amServer.js` and add `shared/amIds.js`
    - Move `amIsUuid` to `shared/amIds.js` and re-export it from `server/amServer.js`
    - `AmHttpError(status, message, extra = {})` stores optional `reason` and `fields`; `amHandler` returns `{ error, reason?, fields? }`
    - `amHandler(fn, { maxBodyBytes } = {})` returns 413 after the 405 check when `content-length` or the raw body exceeds the limit
    - Malformed JSON, including a throwing `req.body` getter, returns 400 `Request body must be valid JSON.` instead of 500
    - _Requirements: 2.5, 2.7, 2.8, 3.3_
  - [x] 1.3 Write unit tests for the `amHandler` extensions in `tests/amApi.test.js`
    - Cover 413 at the byte limit + 1, 400 on malformed JSON, and `reason` / `fields` in the response body
    - Confirm the existing 405 and hidden-500 cases still pass unchanged
    - _Requirements: 2.5, 2.7, 2.8, 10.2_

- [x] 2. Add the diagnostic schema migrations and seed
  - [x] 2.1 Create `supabase/migrations/20261003000007_am_diagnostic.sql` (tables and security)
    - Create `programs`, `subjects`, `topics` (with `am_topics_topic_name_unique`), `diagnostic_questions`, `diagnostic_attempts`, `diagnostic_answers` and `student_topic_mastery` with the constraints, FKs to `auth.users(id)` and indexes from the design
    - Enable RLS on all 7 tables; add authenticated SELECT-only policies on reference tables and owner-scoped SELECT/INSERT/UPDATE policies on student tables (answers also require the parent attempt to be the caller's)
    - Revoke all privileges from `public`, `anon` and `authenticated`, then grant SELECT on reference tables and SELECT/INSERT/UPDATE on student tables to `authenticated`, and all to `service_role`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.9, 3.9_
  - [x] 2.2 Add the `profiles` changes and the Mastery_Bridge RPC to `20261003000007_am_diagnostic.sql`
    - Add `profiles.subjects_source` (`'onboarding' | 'diagnostic'`, default `'onboarding'`, no client grant)
    - Replace `am_profiles_subjects_check` and `am_profiles_onboarded_check` with the branching versions, keeping the constraint names
    - Create the security-definer `public.am_apply_mastery_bridge()` (raises `diagnostic-required` with zero records, collate "C" ordering, disjoint arrays, sets `subjects_source = 'diagnostic'`), revoke execute from `public`/`anon`, and grant it to `authenticated` and `service_role`
    - _Requirements: 5.1, 5.2, 5.3, 5.7, 5.8, 5.10, 10.6_
  - [x] 2.3 Create `supabase/migrations/20261003000008_am_diagnostic_seed.sql`
    - Copy the body verbatim from `git show origin/diagnostic-skillgps-module:modules/diagnostic-skillgps/supabase/dsseed.sql` and add an `am`-style header comment
    - _Requirements: 1.8_
  - [x] 2.4 Write PGlite migration tests in `tests/amDiagnosticMigrations.test.js`
    - Reuse the `asUser` / `asService` pattern from `tests/amMigrations.test.js`
    - Assert tables and FKs exist, and `has_table_privilege` gives anon none, authenticated S/I/U (student) or S (reference), and service_role all
    - Assert no `pg_policies` row targets `anon`; cross-user reads return 0 rows and cross-user writes are rejected; reference tables are read-only for authenticated
    - Assert range, level and unique constraints, including unique `topic_name`
    - Run the seed twice and assert counts of 1 / 7 / 49 / 980
    - Assert a retake keeps two attempts and updates one mastery row
    - Assert a diagnostic profile with 10 topic names is accepted and an onboarding profile with `'Loops'` or 4 subjects is rejected
    - Assert the bridge overwrites onboarding arrays and raises `diagnostic-required` with zero records
    - Confirm `tests/amMigrations.test.js` passes unchanged
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 3.8, 3.9, 5.8, 5.10, 10.6_

- [x] 3. Checkpoint - Ensure all tests pass
  - Run `npx vitest --run`. Ensure all tests pass, ask the user if questions arise.

- [x] 4. Port BKT prediction to Node
  - [x] 4.1 Port the thresholds and classifier
    - Create `shared/amMasteryThresholds.js` (`AM_DEVELOPING_THRESHOLD = 0.4`, `AM_PROFICIENT_THRESHOLD = 0.7`) from `config/dsThresholds.js`
    - Create `shared/amMasteryClassifier.js` with `amClassifyMastery(p)` from `lib/dsMasteryClassifier.js` (level or `{error}`, one warning per load on invalid config)
    - _Requirements: 2.4, 7.1_
  - [x] 4.2 Create `scripts/amBktExtract.py` and generate the parameter and parity files
    - Dev-only stdlib script: load `ml/dsmodel.pkl`, assert `engine == 'bkt'`, 49 skills, params in [0, 1] and `p_slip + p_guess < 1`
    - Map skill key `str(k)` to the k-th topic in `supabase/dsseed.sql` insertion order and write `shared/amBktParams.js` (`AM_BKT_DEFAULT`, frozen `AM_BKT_SKILLS` keyed by `topic_name`)
    - Import `ml/dsbkt.py` and write `tests/fixtures/amBktParity.json` (720 held-out sequences from `ml/dstest_sequences.csv`, 300 random sequences of length 1–20, 20 default-parameter cases)
    - Run it with `python scripts/amBktExtract.py --module <checkout>/modules/diagnostic-skillgps` (for example, the local `.ds-branch` checkout) and commit both generated files
    - _Requirements: 2.2, 2.3, 10.1_
  - [x] 4.3 Implement `shared/amBkt.js`
    - `amBktPosterior`, `amBktTransition`, `amBktRun`, `amBktProbabilities`, `amBktParamsFor` and `amBktPredict` (label from `amClassifyMastery`, `confidence = probabilities[predicted_label]`)
    - `amValidatePredictBody(body)` with UUID `topic_id` via `shared/amIds.js`, 1–20 responses, strict boolean `is_correct`, optional integer `difficulty` 1–3, and Python-style field error strings
    - _Requirements: 2.2, 2.4, 2.5, 2.9_
  - [x] 4.4 Write the BKT parity property test in `shared/amBkt.test.js`
    - **Property 1: BKT parity with the Python reference**
    - Iterate all 1,040 fixture entries; assert probability and triple within 1e-6
    - **Validates: Requirements 2.2, 2.3**
  - [ ]* 4.5 Write a property test for Prediction_Result invariants in `shared/amBkt.test.js`
    - **Property 2: Prediction_Result invariants**
    - **Validates: Requirements 2.4**
  - [x]* 4.6 Write a property test for the classifier in `shared/amMasteryClassifier.test.js`
    - **Property 3: Classifier thresholds and monotonicity**
    - Include the explicit 0.4 / 0.7 boundaries, and port the module's `dsMasteryClassifier` example tests
    - **Validates: Requirements 2.4**
  - [ ]* 4.7 Write a property test for request validation in `shared/amBkt.test.js`
    - **Property 4: Invalid sequences are rejected with named fields**
    - **Validates: Requirements 2.5, 2.9**

- [x] 5. Implement the Predict_API
  - [x] 5.1 Create `api/amPredict.js` and register it in `vercel.json`
    - `AM_PREDICT_MAX_BYTES = 10 * 1024`; `amRequireUser` → `amValidatePredictBody` → service-role topic lookup → `amBktPredict(responses, amBktParamsFor(topic_name))`
    - Return 400 `fields: ['topic_id: unknown topic']` for unknown topics; store nothing
    - Add `"api/amPredict.js": { "maxDuration": 10 }` to `vercel.json`
    - _Requirements: 2.1, 2.2, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 9.2, 10.1_
  - [x] 5.2 Write API tests for `amPredict` in `tests/amApi.test.js`
    - Cover the 200 happy path, 401, 405, 413 (10 KB + 1), 400 malformed JSON, 400 invalid fields, and 400 unknown topic
    - Add `maybeSingle` support to `tests/amFakeAdmin.js` if it is missing
    - _Requirements: 2.1, 2.5, 2.6, 2.7, 2.8, 2.9_

- [x] 6. Port the diagnostic and SkillGPS pure logic
  - [x] 6.1 Port the response sequence builder and scorer
    - Create `shared/amResponseSequence.js` (`amBuildResponseSequence`, `AmSequenceError`) and `shared/amScorer.js` (`amScoreTopic`)
    - Port the module's tests as `shared/amResponseSequence.test.js` and `shared/amScorer.test.js`
    - _Requirements: 3.4, 7.1_
  - [x] 6.2 Port the recommendation content and engine
    - Create `shared/amRecommendationContent.js` and `shared/amRecommendations.js` (`amBuildRecommendations`: level rank, then p ascending, then case-insensitive name, then id)
    - _Requirements: 4.4, 7.1_
  - [x] 6.3 Create `shared/amMasterySummary.js`
    - `amSummarizeMastery(records)` returns `{ total, overallPct, proficient, developing, weak }` from stored levels with `overallPct = Math.round(mean(p) * 100)`
    - _Requirements: 4.1, 4.5, 4.6_
  - [x] 6.4 Create `shared/amMasteryBridge.js`
    - `amBridgeMastery(records)` (Proficient → strong, Weak → weak, Developing ignored, conflicting names removed from both, code-unit sort) and `amBridgeMatchesProfile(profile, bridged)`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.7_
  - [x]* 6.5 Write a property test for the summary in `shared/amMasterySummary.test.js`
    - **Property 5: Home summary counts and overall %**
    - **Validates: Requirements 4.5, 4.6**
  - [x]* 6.6 Write a property test for recommendation ordering in `shared/amRecommendations.test.js`
    - **Property 6: Recommendation ordering is deterministic**
    - **Validates: Requirements 4.4**
  - [x]* 6.7 Write a property test for bridge derivation in `shared/amMasteryBridge.test.js`
    - **Property 7: Bridge derivation**
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.7**
  - [ ]* 6.8 Write a property test for bridge idempotence in `shared/amMasteryBridge.test.js`
    - **Property 8: Bridge idempotence**
    - **Validates: Requirements 5.4**
  - [ ]* 6.9 Write a property test comparing the SQL bridge with the JS reference in `tests/amDiagnosticMigrations.test.js`
    - **Property 9: SQL bridge equals the JS reference**
    - **Validates: Requirements 5.1, 5.4, 5.8**

- [x] 7. Checkpoint - Ensure all tests pass
  - Run `npx vitest --run`. Ensure all tests pass, ask the user if questions arise.

- [x] 8. Branch profile completeness on `subjects_source`
  - [x] 8.1 Update `shared/amSubjects.js` and the profile load
    - Add `amValidateDiagnosticSubjects(weak, strong)` and branch `amIsProfileComplete` on `subjects_source === 'diagnostic'`; leave `amValidateSubjects` and `amToggleSubject` unchanged
    - Make sure the profile query in `src/lib/amAuth.jsx` returns `subjects_source`
    - _Requirements: 5.6, 5.9, 10.4_
  - [x] 8.2 Add the diagnostic mode to `src/pages/amProfilePage.jsx`
    - When `subjects_source === 'diagnostic'`, show read-only chips plus a "Retake diagnostic" link, skip `amValidateSubjects`, and omit `weak_subjects` / `strong_subjects` from the update payload
    - _Requirements: 5.6, 5.8_
  - [ ]* 8.3 Write a property test for diagnostic profile completeness in `shared/amSubjects.test.js`
    - **Property 10: Diagnostic profiles stay complete for any count**
    - **Validates: Requirements 5.6**
  - [ ]* 8.4 Write a property test for unchanged onboarding completeness in `shared/amSubjects.test.js`
    - **Property 11: Onboarding completeness is unchanged**
    - Compare against `tests/fixtures/amLegacyMatcher.js`
    - **Validates: Requirements 5.9, 10.4**

- [x] 9. Add shared-strong matching to the Matcher
  - [x] 9.1 Update `shared/amMatchScore.js`
    - Add `sharedStrongFull: 3` and `sharedStrongFactor: 0.75` to `AM_MATCH_CONFIG` (weights unchanged)
    - Add `amSharedStrong(a, b)` and `amPracticeScore(n, cfg)`
    - `amHardFilter`: reject `no-overlap` only when both coverages and the shared overlap are empty
    - `amScoreCandidate`: skip the `relaxAfterMs` gate when the overlap is non-empty; when it is empty keep the identical code path; otherwise use `reciprocity = max(comp, factor · practice)`; return `shared`
    - `amTeachLearn` returns `{ teach, learn, practice }`; `amTeachLearnCopy` adds `practice` entries and the shared-strengths headline only when teach and learn are empty
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_
  - [x] 9.2 Update `shared/amGroupBuilder.js` for Study_Peers_Mode
    - `amMarginalScore` uses `amSharedStrong` against the group's strong labels with the same reciprocity branch; `connects` also accepts a shared overlap
    - `amGroupSatisfied` accepts members with `practice.length > 0` regardless of `relaxed`
    - Add `amAllMembersEngaged(group)` and use it in the greedy `done` check; keep `amAllWeakCovered` exported and unchanged
    - _Requirements: 6.1, 6.3, 6.8, 6.9_
  - [x] 9.3 Write the legacy-equivalence property test in `shared/amMatchScore.test.js`
    - **Property 13: Empty overlap preserves legacy behavior**
    - Compare `amHardFilter`, `amScoreCandidate` (strict score equality) and `amPlanMatches` against `tests/fixtures/amLegacyMatcher.js` for pairs and queues with no shared strong labels
    - **Validates: Requirements 6.2, 6.5, 6.6**
  - [ ]* 9.4 Write a property test for immediate shared-strong acceptance in `shared/amMatchScore.test.js`
    - **Property 12: Shared-strong pairs are accepted immediately**
    - **Validates: Requirements 6.1, 6.8**
  - [ ]* 9.5 Write a property test for the score range in `shared/amGroupBuilder.test.js`
    - **Property 14: Scores stay in [0, 1]**
    - **Validates: Requirements 6.3**
  - [ ]* 9.6 Write a metamorphic property test for overlap size in `shared/amMatchScore.test.js`
    - **Property 15: Larger shared overlap never lowers the score**
    - **Validates: Requirements 6.4**
  - [ ]* 9.7 Write a property test for practice copy in `shared/amMatchScore.test.js`
    - **Property 16: Practice copy names the shared labels**
    - **Validates: Requirements 6.7**
  - [ ]* 9.8 Write a property test for Study Peers practice roles in `shared/amGroupBuilder.test.js`
    - **Property 17: Practice gives a valid Study Peers role**
    - **Validates: Requirements 6.9**
  - [x] 9.9 Show practice topics in `src/components/amPreviewCard.jsx`
    - Add a "You'll practice together" block rendered only when `copy.practice.length > 0`
    - _Requirements: 6.7_

- [x] 10. Gate matching on the diagnostic
  - [x] 10.1 Update `api/amMatch.js`
    - After `amRequireUser`, count the caller's `student_topic_mastery` rows (`{ count: 'exact', head: true }`); at zero, delete the caller's `match_queue` row and throw 403 with `reason: 'diagnostic-required'`
    - Add `subjects_source` to `PROFILE_FIELDS` and plan only users whose profile is diagnostic-sourced
    - Add `select(cols, { count, head })` support to `tests/amFakeAdmin.js`
    - _Requirements: 3.3, 10.6_
  - [x] 10.2 Handle `diagnostic-required` on the client
    - `src/lib/amApi.js` copies `json.reason` onto the thrown error
    - `src/lib/amQueue.js` (`useAmQueue`) exposes `errorReason`
    - `src/pages/amMatchPage.jsx` navigates to `/diagnostic` with `replace` when `errorReason === 'diagnostic-required'`
    - _Requirements: 3.1, 3.3_
  - [x] 10.3 Write API tests for the `amMatch` gate in `tests/amApi.test.js`
    - Assert the 403 `diagnostic-required` response with the queue row deleted, and that non-diagnostic profiles are excluded from planning
    - _Requirements: 3.3_

- [x] 11. Checkpoint - Ensure all tests pass
  - Run `npx vitest --run`. Ensure all tests pass, ask the user if questions arise.

- [x] 12. Add diagnostic data access and the mastery provider
  - [x] 12.1 Create `src/lib/amDiagnostic.js`
    - `amFetchSubjects`, `amFetchTopics` (with question counts), `amFetchQuestions`, `amStartAttempts`, `amSaveAnswers` (upsert `onConflict: 'attempt_id,question_id'`, `ignoreDuplicates`), `amPredictTopic` (`amApi('amPredict', …)`), `amCompleteAttempt`, `amUpsertMastery` (`onConflict: 'user_id,topic_id'`) and `amApplyBridge` (RPC)
    - Use only `amSupabase` and set every `user_id` from the caller-supplied auth user
    - _Requirements: 3.4, 3.8, 3.9, 8.1, 8.2, 8.3, 9.2_
  - [x] 12.2 Create `src/lib/amMastery.jsx` and mount it in `src/amMain.jsx`
    - `AmMasteryProvider` / `useAmMastery() → { records, count, loading, error, refresh }`, loading records with `topics(topic_name)`
    - Reset state when `user?.id` changes, including sign-out to `null`
    - Self-heal: when records exist and `amBridgeMatchesProfile` is false, call `amApplyBridge` once, then `refreshProfile()`
    - Mount inside `AmAuthProvider` in `src/amMain.jsx`
    - _Requirements: 5.4, 5.5, 8.1, 8.3, 8.4_

- [x] 13. Build the re-skinned Diagnostic, SkillGPS and Home UI
  - [x] 13.1 Create `src/components/amMasteryBadge.jsx` and `src/components/amMasteryBar.jsx`
    - Level pill in rose/amber/emerald/slate tones with a visible text label; progress bar with `role="progressbar"` and `aria-valuenow`, `aria-valuemin`, `aria-valuemax`
    - _Requirements: 7.2, 7.4_
  - [x] 13.2 Create `src/pages/amDiagnosticPage.jsx`
    - Select → answer → submit → results flow using `AmCard`, `AmButton` and the ds-* → main design mapping
    - Questions as `<fieldset>` + `<legend>` with native radio inputs inside labels; topic selection with native checkboxes; disabled "Unavailable" topics
    - Insert attempts at Start; per topic run save answers → predict → complete attempt → upsert mastery → apply bridge; on failure store `{step, error}`, show `role="alert"` text and a Retry that resumes from the failed step while keeping answers
    - When every topic finishes, call `refreshProfile()` and `mastery.refresh()`, then navigate to `/skillgps`
    - _Requirements: 3.4, 3.5, 3.7, 3.8, 3.9, 5.1, 5.5, 7.2, 7.4, 8.2_
  - [x] 13.3 Create `src/pages/amSkillGpsPage.jsx`
    - Overall %, level counts, skill map with `AmMasteryBar`, recommendations from `amBuildRecommendations`, and a "Continue to match" button to `/match`
    - Show the all-Developing notice when both bridged arrays are empty
    - _Requirements: 3.6, 4.4, 7.2_
  - [x] 13.4 Create `src/components/amSkillSummaryCard.jsx` and render it in `src/pages/amHomePage.jsx`
    - With records: summary from `amSummarizeMastery` plus a "Retake Diagnostic" button; with none: a "Take Diagnostic" CTA; both go to `/diagnostic`
    - Change the Home "Edit subjects" link to "Retake diagnostic" for diagnostic-sourced profiles
    - _Requirements: 4.1, 4.2, 4.3, 4.5, 4.6_
  - [ ]* 13.5 Write component tests in `src/pages/amDiagnosticPage.test.jsx`
    - Radios reachable by role and name with keyboard selection; submit call order with `user_id`; predict failure → Retry keeps answers; navigation to `/skillgps`
    - _Requirements: 3.4, 3.5, 3.7, 7.4, 8.2_
  - [ ]* 13.6 Write component tests in `src/pages/amSkillGpsPage.test.jsx` and `src/components/amSkillSummaryCard.test.jsx`
    - Recommendations render, continue-to-match, and Retake / Take Diagnostic CTAs
    - _Requirements: 3.6, 4.1, 4.2, 4.3, 4.4_

- [x] 14. Wire routes, guard and navigation
  - [x] 14.1 Add `AmDiagnosticGuard` and the new routes
    - In `src/amApp.jsx`, add `AmDiagnosticGuard` (loader, error card with retry, redirect to `/diagnostic` at count 0), register `/diagnostic` and `/skillgps` under `AmGuard` → `AmShell`, and wrap only `/match` in the guard
    - In `src/components/amLayout.jsx`, add the SkillGPS entry (`Compass` icon) to `AM_NAV` and change the mobile bar to `grid-cols-5`
    - _Requirements: 3.1, 3.2, 7.2, 7.3, 10.3, 10.4, 10.5_
  - [x] 14.2 Write routing tests in `src/amApp.test.jsx`
    - Guard redirects at count 0 and passes at count ≥ 1; legacy users reach `/home`, `/messages` and `/profile`; `/diagnostic` and `/skillgps` sit behind `AmGuard`
    - _Requirements: 3.1, 3.2, 7.3, 10.3, 10.4, 10.5_
  - [ ]* 14.3 Write provider tests in `src/lib/amMastery.test.jsx`
    - Sign-out clears records; self-heal calls the RPC exactly once
    - _Requirements: 5.4, 8.4_

- [x] 15. Clean up env and config
  - [x] 15.1 Update `.env.example` and `README.md`
    - Replace concrete-looking server values in `.env.example` with placeholders; document `VITE_SUPABASE_ANON_KEY` as the publishable key and `SUPABASE_SERVICE_ROLE_KEY` as the secret key
    - Ensure no `VITE_PREDICTION_API_URL` / `VITE_RECOMMENDATION_SERVICE_URL` remain anywhere in the app
    - README: describe the Diagnostic/SkillGPS feature and `/api/amPredict`, list both new migrations with `AM_DB_URL=... node scripts/amMigrate.mjs`, and note `scripts/amBktExtract.py` as dev-only
    - _Requirements: 9.1, 9.3_
  - [x] 15.2 Write the config smoke test in `tests/amConfig.test.js`
    - Assert no `VITE_PREDICTION_API_URL` / `VITE_RECOMMENDATION_SERVICE_URL` in `src/`, `shared/`, `api/`, `server/`, `.env.example` or `vercel.json`; no `__DS_USER_ID__`; no `SUPABASE_SERVICE_ROLE_KEY` or `createClient` under `src/` except `amSupabase.js`; no `.py` under `api/`; every new ported file is `am`-prefixed
    - _Requirements: 7.1, 8.1, 8.3, 9.1, 9.3, 10.1_

- [x] 16. Final checkpoint - Ensure all tests pass and the build succeeds
  - Run `npx vitest --run` and `npx vite build`; both must be green. Ensure all tests pass, ask the user if questions arise.
  - _Requirements: 10.1, 10.2_

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP. The BKT parity test (4.4), the legacy-equivalence test (9.3), the migration security tests (2.4), the API tests (1.3, 5.2, 10.3), the routing tests (14.2) and the config smoke test (15.2) stay required, because they are the only checks for parity, backward compatibility and access control.
- Every property test uses fast-check with at least `{ numRuns: 100 }` (Property 1 iterates all fixture entries) and carries the comment `// Feature: skillgps-matching-integration, Property N: <title>`.
- Task 1.1 must run before tasks 8 and 9 so the legacy oracle reflects the pre-change code.
- Each task references specific requirements for traceability. Checkpoints run the full Vitest suite.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "2.1", "2.3", "4.1", "4.2", "6.1", "6.2", "6.3", "6.4", "13.1"] },
    { "id": 1, "tasks": ["1.3", "2.2", "4.3", "4.6", "6.5", "6.6", "6.7", "8.1", "9.1"] },
    { "id": 2, "tasks": ["2.4", "4.4", "5.1", "6.8", "8.2", "8.3", "9.2", "9.9", "10.1", "12.1"] },
    { "id": 3, "tasks": ["4.5", "5.2", "6.9", "8.4", "9.3", "9.5", "10.2", "12.2"] },
    { "id": 4, "tasks": ["4.7", "9.4", "9.8", "10.3", "13.2", "13.3", "13.4"] },
    { "id": 5, "tasks": ["9.6", "13.5", "13.6", "14.1"] },
    { "id": 6, "tasks": ["9.7", "14.2", "14.3", "15.1"] },
    { "id": 7, "tasks": ["15.2"] }
  ]
}
```
