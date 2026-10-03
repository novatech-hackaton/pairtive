# Requirements Document

## Introduction

Pairtive is an AI-moderated peer-tutoring video matching web application. Users build a profile declaring subjects they are weak in and strong in, then are matched in real time with peers whose strengths complement their weaknesses. Matching supports one-to-one (Study Buddy) and small-group (Study Peers) sessions over live video/voice. Sessions include screen sharing, client-side recording, in-session messaging, and live collaborative notes. After each session, participants rate one another. A persistent messenger lets peers keep chatting and reconnect directly. Safety is enforced through user reports, AI-assisted moderation (image and text classification), a strike ladder, and timed suspensions. The platform runs as a React + Vite single-page web app with a Supabase backend (Auth, Postgres with Row-Level Security, Realtime, Storage), Daily.co for media, and Vercel-hosted serverless API functions.

This document formalizes the full approved product scope.

## Glossary

- **Pairtive**: The overall peer-tutoring video matching web application (also referred to as "THE System").
- **User**: An authenticated person using Pairtive.
- **Profile**: A User's required attributes: name, preferred language(s), organization/school, optional avatar, and subject selections.
- **Subject**: A member of the fixed list: Math, English, Science, Filipino, History, Programming.
- **Weak_Subject**: A Subject a User wants help with (1 to 3 selected).
- **Strong_Subject**: A Subject a User can help others with (1 to 3 selected).
- **Study_Buddy**: A match mode producing a session of exactly 2 Users.
- **Study_Peers**: A match mode producing a session of 3 to 5 Users.
- **Matcher**: The subsystem that applies hard filters, scoring, group building, and cooldowns to pair Users.
- **Heartbeat**: A periodic signal from a waiting User's client indicating the User is still in the queue.
- **Queue**: The set of Users currently waiting for a match in a given mode.
- **Match_Preview**: The pre-join screen showing prospective peer(s) with a countdown and Accept/Next controls.
- **Session**: A live video/voice meeting between matched Users.
- **Cooldown**: A time- or event-bound restriction preventing specific Users or groups from being re-matched.
- **Reciprocity**: Two-way subject coverage where each User's Weak_Subject is covered by another's Strong_Subject.
- **One_Way_Match**: A match where coverage flows in only one direction (one User helps, the other is helped).
- **Bayesian_Smoothing**: A smoothing method that blends an individual's observed value with a global prior so Users with few data points are not unfairly ranked.
- **Success_Rate**: The fraction of a User's sessions that are successful, where a successful Session lasts at least 1 minute and has no confirmed report.
- **Thread**: A persistent messenger conversation between a fixed set of Users (a pair or a group).
- **Collaborative_Notes**: A shared document edited by all Session participants in real time.
- **Report**: A User-submitted complaint against another User.
- **Strike**: A moderation penalty that advances a User along the suspension ladder.
- **Suspension**: A time-bound state in which a User is gated from the app and the Matcher.
- **Moderation_Service**: The server-side subsystem that classifies report evidence and issues verdicts.
- **Evidence_Frames**: Still frames of a reported User's video captured client-side during a live Session for moderation.
- **RLS**: Row-Level Security policies in Supabase Postgres and Storage.
- **JWT**: A Supabase-issued JSON Web Token proving an authenticated session.

## Requirements

### Requirement 1: Accounts and Authentication

**User Story:** As a prospective user, I want to sign up and sign in with email/password or Google, so that I can access Pairtive securely.

#### Acceptance Criteria

1. THE System SHALL offer account creation and sign-in using Supabase Auth with email and password.
2. THE System SHALL offer account creation and sign-in using Google OAuth.
3. WHEN a User authenticates successfully, THE System SHALL establish an authenticated session identified by a Supabase JWT.
4. IF a User attempts to access any application feature other than authentication and profile completion while unauthenticated, THEN THE System SHALL redirect the User to the sign-in screen.
5. WHEN a User signs in with Google and has an incomplete Profile, THE System SHALL redirect the User to the onboarding flow.

### Requirement 2: Profile Completion (Identity Fields)

**User Story:** As a new user, I want to complete my profile, so that I can be matched accurately and others can recognize me.

#### Acceptance Criteria

1. IF an authenticated User has an incomplete Profile, THEN THE System SHALL require the User to complete the Profile before accessing matching features.
2. THE System SHALL require a name as part of the Profile.
3. THE System SHALL require one or more preferred languages selected from a multi-select control as part of the Profile.
4. THE System SHALL require an organization or school as part of the Profile.
5. THE System SHALL accept an optional avatar image as part of the Profile.
6. WHERE a User provides an avatar image, THE System SHALL store the avatar in Supabase Storage and display it as a circular avatar.

### Requirement 3: Subject Selection

**User Story:** As a user, I want to declare the subjects I need help with and the subjects I can help with, so that the Matcher can pair me complementarily.

#### Acceptance Criteria

1. THE System SHALL present subjects only from the fixed list: Math, English, Science, Filipino, History, Programming.
2. THE System SHALL require the User to select between 1 and 3 Weak_Subjects.
3. THE System SHALL require the User to select between 1 and 3 Strong_Subjects.
4. IF a User selects the same Subject as both a Weak_Subject and a Strong_Subject, THEN THE System SHALL reject the selection and require the User to resolve the overlap.
5. WHEN the User completes name, language(s), organization/school, and valid Weak_Subject and Strong_Subject selections, THE System SHALL mark the Profile as complete.

### Requirement 4: Match Entry and Mode Selection

**User Story:** As a user, I want to start a match and choose how I study, so that I can find the right kind of session.

#### Acceptance Criteria

1. THE System SHALL display a "Find Match" control on the Home screen.
2. WHEN the User activates the "Find Match" control, THE System SHALL navigate the User to the match screen.
3. THE System SHALL allow the User to choose exactly one match mode: Study_Buddy or Study_Peers.
4. THE System SHALL provide an optional "Same school only" toggle on the match screen.
5. THE System SHALL display an expandable "How matching works" section containing a plain-language explanation of the matching process.

### Requirement 5: Camera Behavior During Matching

**User Story:** As a user, I want my camera to be ready while I search and preview, so that I can join a session without delay.

#### Acceptance Criteria

1. WHEN the User enters the match screen, THE System SHALL open the camera automatically.
2. WHILE the User is searching for a match, THE System SHALL display the User's camera preview at the top of the match screen.
3. WHILE the User is in the joining or preview phase, THE System SHALL display the User's camera preview at the top of the screen.
4. IF camera access is denied or unavailable, THEN THE System SHALL display a message describing that camera access is required and allow the User to retry granting access.

### Requirement 6: Community Rules Acceptance

**User Story:** As a user, I want to understand and accept community rules, so that sessions remain safe and respectful.

#### Acceptance Criteria

1. THE System SHALL display community rules beneath the "Find Match" control.
2. IF a User has never accepted the community rules, THEN THE System SHALL require the User to tick an "I agree" control before the first match.
3. WHEN a User accepts the community rules for the first time, THE System SHALL record the acceptance timestamp as rules_accepted_at.
4. WHERE a User has previously accepted the community rules, THE System SHALL display the rules as a collapsed reminder rather than requiring acceptance again.

### Requirement 7: Hard Match Filters

**User Story:** As a user, I want to be matched only with eligible peers, so that each match is relevant, safe, and fair.

#### Acceptance Criteria

1. THE Matcher SHALL only pair Users who selected the same match mode.
2. THE Matcher SHALL only pair Users who are currently waiting with a Heartbeat received within the last 30 seconds.
3. THE Matcher SHALL only pair a User with a candidate WHERE at least one of the User's Weak_Subjects is one of the candidate's Strong_Subjects.
4. THE Matcher SHALL exclude any candidate who has a block or report relationship with the User.
5. THE Matcher SHALL exclude any candidate currently in Cooldown with the User.
6. THE Matcher SHALL exclude any candidate who is currently suspended.
7. WHERE either the User or a candidate has enabled "Same school only", THE Matcher SHALL only pair Users whose organization/school matches.

### Requirement 8: Match Scoring

**User Story:** As a user, I want matches ranked by quality, so that I am paired with the most suitable eligible peer.

#### Acceptance Criteria

1. THE Matcher SHALL compute a match score using a single configuration with the following weights: 40% Reciprocity, 25% rating, 20% Success_Rate, 10% wait time, and 5% shared language.
2. THE Matcher SHALL compute the Reciprocity component from two-way subject coverage between the Users.
3. THE Matcher SHALL compute the rating component using Bayesian_Smoothing so that Users with few ratings are not ranked last by default.
4. THE Matcher SHALL compute the Success_Rate component using Bayesian_Smoothing, where a successful Session lasts at least 1 minute and has no confirmed report.
5. THE Matcher SHALL compute the wait time component from how long each User has been waiting in the Queue.
6. THE Matcher SHALL apply shared language as a 5% soft boost to the score and SHALL NOT use shared language as a hard filter.
7. WHEN multiple eligible candidates exist, THE Matcher SHALL select the candidate with the highest total score.

### Requirement 9: Partial (One-Way) Matching

**User Story:** As a user, I want a reasonable match even when no perfect two-way peer is available, so that I am not stuck waiting indefinitely.

#### Acceptance Criteria

1. WHILE a User has been waiting for less than 30 seconds, THE Matcher SHALL only form two-way (reciprocal) matches for that User.
2. WHEN a User has been waiting for 30 seconds or more, THE Matcher SHALL allow a One_Way_Match for that User.

### Requirement 10: Cooldown Rules

**User Story:** As a user, I want variety in who I am matched with, so that I meet different peers over time.

#### Acceptance Criteria

1. WHEN two Users complete or leave a Session together, THE Matcher SHALL place that pair in Cooldown for 24 hours or until 5 other matches have occurred for the User, whichever comes first.
2. WHEN a group Session ends, THE Matcher SHALL apply the Cooldown rule to any new group in which at least half of the members previously shared a Session together.
3. WHEN a User declines a Match_Preview, selects Next, or the Match_Preview timer expires, THE Matcher SHALL place the affected pairing in Cooldown.
4. WHEN a User initiates a Reconnect from the messenger, THE Matcher SHALL bypass Cooldown for that pairing.

### Requirement 11: Study Peers Group Building

**User Story:** As a user choosing group study, I want a well-formed small group, so that everyone's weak subjects can be covered.

#### Acceptance Criteria

1. WHEN building a Study_Peers group, THE Matcher SHALL seed the group with the longest-waiting eligible User.
2. WHILE building a Study_Peers group, THE Matcher SHALL add the highest-scoring eligible candidate until every member's Weak_Subject is covered or the group reaches 5 members.
3. THE Matcher SHALL only finalize a Study_Peers group containing at least 3 members.
4. THE Matcher SHALL NOT finalize a Study_Peers group containing more than 5 members.

### Requirement 12: Match Preview Before Joining

**User Story:** As a user, I want to preview who I am about to study with, so that I can decide whether to join.

#### Acceptance Criteria

1. WHEN a prospective match is formed, THE System SHALL display a Match_Preview showing each other User's circular avatar, name, rating, language(s), and school.
2. THE System SHALL display friendly teach/learn copy in the Match_Preview, stating which Subject the User will help each peer with and which Subject each peer will help the User with.
3. WHERE the match is a Study_Peers group, THE System SHALL combine peer names in the teach/learn copy for a shared Subject.
4. THE System SHALL display a 15-second countdown ring in the Match_Preview.
5. THE System SHALL provide Accept and Next controls in the Match_Preview.
6. WHEN every participant accepts the Match_Preview, THE System SHALL start the Session.
7. IF any participant selects Next or the 15-second timer expires, THEN THE System SHALL place the affected pairing in Cooldown and return the remaining Users to the Queue while preserving their waiting position.
8. WHERE the match is a Study_Peers group and a participant declines, THE Matcher SHALL replace the decliner with the next best eligible candidate.

### Requirement 13: In-Session Media Controls

**User Story:** As a session participant, I want to control my video, mic, and screen sharing, so that I can communicate effectively.

#### Acceptance Criteria

1. THE System SHALL provide a control to toggle the User's video on and off during a Session.
2. THE System SHALL provide a control to toggle the User's microphone on and off during a Session.
3. WHERE the User's device is a desktop and screen sharing is supported, THE System SHALL provide a screen share control.
4. IF screen sharing is unsupported on the User's device, THEN THE System SHALL hide the screen share control.
5. WHERE the User is on a mobile device, THE System SHALL allow the User to view screen shares from other participants.

### Requirement 14: Session Recording

**User Story:** As a session participant, I want to optionally record a session with everyone's consent, so that I can review it later while preserving privacy.

#### Acceptance Criteria

1. WHEN a User requests to record a Session, THE System SHALL require every other participant to accept before recording begins.
2. WHEN all other participants accept a recording request, THE System SHALL ask each non-requesting participant whether that participant also wants a personal copy.
3. THE System SHALL produce recordings client-side by compositing video via canvas and audio via WebAudio into a MediaRecorder stream.
4. THE System SHALL prefer the mp4 recording format and SHALL fall back to webm when mp4 is unavailable.
5. WHEN recording stops on a desktop or Android device, THE System SHALL automatically download the recording file.
6. WHEN recording stops on an iOS device, THE System SHALL present a share sheet and SHALL provide a download fallback.
7. THE System SHALL NOT upload Session recordings to application storage.
8. WHILE a Session is being recorded, THE System SHALL display a recording indicator visible to all participants.
9. THE System SHALL allow any participant to stop an in-progress recording.
10. WHILE recording on a mobile device, WHEN the recording reaches 60 minutes, THE System SHALL display a warning to the User.

### Requirement 15: In-Session Reporting

**User Story:** As a session participant, I want to report a user who misbehaves, so that the platform can act on it.

#### Acceptance Criteria

1. THE System SHALL allow a User to report another User from the participant's video tile.
2. THE System SHALL allow a User to report another User from the rating screen.
3. THE System SHALL allow a User to report another User from a messenger Thread.

### Requirement 16: In-Session Messaging and Collaborative Notes

**User Story:** As a session participant, I want to chat and take shared notes during a session, so that we can collaborate effectively.

#### Acceptance Criteria

1. THE System SHALL provide a messenger side panel during a Session supporting text, images, and files.
2. THE System SHALL provide Collaborative_Notes that all participants can edit and view in real time.
3. WHEN a participant edits the Collaborative_Notes, THE System SHALL propagate the change to all other participants in real time.
4. WHEN a Session ends, THE System SHALL persist a snapshot of the Collaborative_Notes.
5. THE System SHALL make the persisted Collaborative_Notes viewable later from the associated Thread.

### Requirement 17: Session Exit (Stop and Next)

**User Story:** As a session participant, I want simple controls to end or move on, so that I can continue studying or finish.

#### Acceptance Criteria

1. WHEN the User selects Next during a Session, THE System SHALL present the rating screen and then return the User to the Queue.
2. WHEN the User selects Stop during a Session, THE System SHALL present the rating screen and then return the User to the Home screen.

### Requirement 18: Ratings

**User Story:** As a user, I want to rate my session peers, so that match quality improves over time.

#### Acceptance Criteria

1. WHEN a ratable Session ends, THE System SHALL present a rating screen allowing a 1-to-5 star rating.
2. THE System SHALL allow optional tags from the set: Helpful, Patient, Clear, Knowledgeable.
3. THE System SHALL allow an optional free-text comment with a rating.
4. THE System SHALL allow the User to skip rating.
5. IF a Session lasted less than 1 minute, THEN THE System SHALL NOT allow the Session to be rated.
6. WHERE the Session is a Study_Peers group, THE System SHALL allow the User to rate every other member on a single screen.
7. THE System SHALL accept at most one rating per combination of Session, rater, and ratee.
8. WHEN a rating is submitted, THE System SHALL update the ratee's rating average, rating count, and Success_Rate aggregates.
9. WHEN a User submits a high rating, THE System SHALL display a light confetti animation.

### Requirement 19: Messenger Threads and History

**User Story:** As a user, I want a persistent messenger, so that I can keep in touch with peers after sessions.

#### Acceptance Criteria

1. WHEN a User sends the first message to a pair or group, THE System SHALL create the Thread at that moment and not before.
2. THE System SHALL maintain exactly one Thread per unique set of members, deduplicated by the sorted member identifiers.
3. THE System SHALL use the same Thread for in-Session chat and post-Session chat for a given set of members.
4. THE System SHALL provide a messages list page and a thread page.
5. THE System SHALL display a Thread header showing a circular avatar and name for a pair, and stacked avatars with names for a group.
6. THE System SHALL allow Users to continue exchanging text, images, and files in a Thread after the Session ends.
7. THE System SHALL provide a "Reconnect" control in a Thread that sends a Session invite.
8. WHEN an invited User accepts a Reconnect invite, THE System SHALL start a Session directly and bypass Cooldown.

### Requirement 20: Report Submission and Immediate Blocking

**User Story:** As a user, I want reporting to be straightforward and protective, so that I am shielded from a user I reported.

#### Acceptance Criteria

1. THE System SHALL offer report reasons: Inappropriate behavior, Harassment, Spam, No-show, and Other.
2. THE System SHALL accept an optional note with a Report.
3. WHEN a User submits a Report, THE System SHALL immediately block the reporter and the reported User from matching with each other.
4. THE System SHALL rate-limit the number of Reports a single User may submit within a defined period.
5. WHILE a live Session is in progress and the User submits a Report, THE System SHALL capture 3 Evidence_Frames of the reported User's video to a private evidence storage bucket.
6. THE System SHALL NOT provide an administrative moderation page.

### Requirement 21: AI-Assisted Moderation Verdicts

**User Story:** As a platform operator, I want reports verified automatically, so that moderation scales without manual review.

#### Acceptance Criteria

1. THE Moderation_Service SHALL expose a server-side API endpoint that evaluates a Report according to its reason.
2. WHERE a Report reason is Inappropriate behavior, THE Moderation_Service SHALL classify the captured Evidence_Frames using an image content classifier.
3. WHERE a Report reason is Harassment, THE Moderation_Service SHALL fetch the reported User's messages server-side and classify them using a text toxicity model.
4. WHERE a Report reason is Spam or No-show, THE Moderation_Service SHALL evaluate the Report using rule-based logic.
5. WHERE a Report reason is Other, THE Moderation_Service SHALL store the Report without taking automated action.
6. WHEN a classification score is 0.8 or higher, THE Moderation_Service SHALL issue a Confirmed verdict and apply a Strike to the reported User.
7. WHEN a classification score is at least 0.4 and less than 0.8, THE Moderation_Service SHALL issue an Uncertain verdict and apply a warning to the reported User.
8. WHEN a User receives 2 Uncertain verdicts from different reporters within 7 days, THE Moderation_Service SHALL apply a Strike to that User.
9. WHEN a classification score is less than 0.4, THE Moderation_Service SHALL issue a Rejected verdict, store it, and take no action.

### Requirement 22: Safety Net and Strike Ladder

**User Story:** As a user, I want repeat offenders removed temporarily, so that the community stays safe.

#### Acceptance Criteria

1. WHEN a User receives 3 Reports from different reporters within 7 days, THE System SHALL automatically suspend that User for 24 hours regardless of AI verdicts.
2. WHEN a User receives a first Strike, THE System SHALL suspend that User for 24 hours.
3. WHEN a User receives a second Strike within 30 days of the previous Strike, THE System SHALL suspend that User for 7 days.
4. WHEN a User receives a third Strike, THE System SHALL suspend that User for 30 days.
5. THE System SHALL NOT permanently ban a User.

### Requirement 23: Suspension Gating

**User Story:** As a suspended user, I want to understand my suspension, so that I know why and when it ends.

#### Acceptance Criteria

1. WHILE a User is suspended, THE System SHALL display a suspension screen showing the suspension reason and the end time.
2. WHILE a User is suspended, THE System SHALL prevent the User from accessing the app features and the Matcher.
3. WHEN a User's suspension end time passes, THE System SHALL restore the User's access to the app and the Matcher.

### Requirement 24: Visual Design System

**User Story:** As a user, I want a polished, consistent interface, so that the app feels trustworthy and pleasant.

#### Acceptance Criteria

1. THE System SHALL present a dark theme using indigo, violet, and cyan gradients.
2. THE System SHALL render content cards using a glassmorphism style.
3. THE System SHALL display per-Subject chips, each with a distinct color and icon.
4. THE System SHALL use self-hosted fonts, with Plus Jakarta Sans for headings and Inter for body text.

### Requirement 25: Motion and Feedback

**User Story:** As a user, I want responsive visual feedback, so that the app communicates state clearly.

#### Acceptance Criteria

1. WHILE the User is searching for a match, THE System SHALL display a radar pulse animation.
2. WHEN a match is found, THE System SHALL display a "Match found" slide-in animation.
3. THE System SHALL display a countdown ring during the Match_Preview.
4. WHEN a User submits a high rating, THE System SHALL display a confetti animation.
5. WHERE the User's system indicates a reduced-motion preference, THE System SHALL honor that preference by reducing or removing non-essential animation.

### Requirement 26: Onboarding and Controls Usability

**User Story:** As a new user, I want guided onboarding and clear controls, so that I can get started confidently.

#### Acceptance Criteria

1. THE System SHALL present onboarding as a stepper with progress dots.
2. THE System SHALL present large, labeled controls with tooltips for primary actions.
3. WHERE a list or screen has no content, THE System SHALL display a friendly empty state.

### Requirement 27: Responsive Layout

**User Story:** As a mobile user, I want a layout suited to my device, so that the app is comfortable to use on any screen.

#### Acceptance Criteria

1. THE System SHALL use a mobile-first responsive layout.
2. WHERE the viewport is a small (mobile) screen, THE System SHALL present side panels as bottom sheets.

### Requirement 28: Accessibility

**User Story:** As a user relying on assistive technology, I want accessible controls, so that I can use the app fully.

#### Acceptance Criteria

1. THE System SHALL meet legible color contrast between text and background.
2. THE System SHALL display a visible focus ring on focusable elements.
3. THE System SHALL support full keyboard operation of interactive controls.
4. THE System SHALL provide aria-labels on icon-only buttons.
5. WHERE the User's system indicates a reduced-motion preference, THE System SHALL respect that preference across the interface.

### Requirement 29: Data and Storage Security

**User Story:** As a platform operator, I want strict data access controls, so that user data is protected.

#### Acceptance Criteria

1. THE System SHALL apply RLS policies to every Postgres table.
2. THE System SHALL apply access policies to every Storage bucket.
3. THE System SHALL require a valid Supabase JWT for every API endpoint request.
4. IF an API endpoint request lacks a valid Supabase JWT, THEN THE System SHALL reject the request.

### Requirement 30: Secret and Credential Handling

**User Story:** As a platform operator, I want secrets kept server-side, so that credentials are never exposed to clients.

#### Acceptance Criteria

1. THE System SHALL keep the Supabase service role key available only to server-side code via server environment configuration.
2. THE System SHALL keep the Daily API key available only to server-side code via server environment configuration.
3. THE System SHALL NOT expose the service role key or the Daily API key in client code.

### Requirement 31: Media Room Provisioning

**User Story:** As a session participant, I want secure, bounded video rooms, so that sessions are private and controlled.

#### Acceptance Criteria

1. THE System SHALL create Daily rooms and tokens server-side.
2. THE System SHALL create Daily rooms as private.
3. THE System SHALL set Daily room token expiry to approximately 2 hours.
4. THE System SHALL limit each Daily room to a maximum of 5 participants.
5. THE System SHALL enable screen sharing in Daily rooms.
6. THE System SHALL disable Daily's built-in chat and recording features.

### Requirement 32: Platform Limitations and Disclosures

**User Story:** As a user, I want transparency about platform limits and data use, so that I can make informed choices.

#### Acceptance Criteria

1. THE System SHALL treat screen sharing and recording limitations on mobile devices as expected behavior.
2. THE System SHALL disclose the capture and use of moderation Evidence_Frames in the Terms and Privacy documentation.
