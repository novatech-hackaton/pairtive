// Diagnostic data access: reference reads, attempt/answer history, prediction,
// Mastery_Record upsert and the Mastery_Bridge RPC. Every query goes through
// amSupabase / amApi, and every user_id is taken from the caller-supplied auth user
// (useAmAuth().user), never from caller data (Req 8.1-8.3).
import { amSupabase, amFriendlyError } from './amSupabase.js';
import { amApi } from './amApi.js';
import { amScoreTopic } from '../../shared/amScorer.js';
import { amBuildResponseSequence, AM_MAX_SEQUENCE_LENGTH } from '../../shared/amResponseSequence.js';
import { amClassifyMastery, amIsClassificationError } from '../../shared/amMasteryClassifier.js';

export const AM_DIAGNOSTIC_PROGRAM_CODE = 'BSCS';

const AM_MIN_RESPONSE_TIME = 0.001; // seconds; diagnostic_answers.response_time must be > 0

function amThrowIf(error) {
  if (error) throw new Error(amFriendlyError(error));
}

function amUserId(user) {
  const id = user?.id;
  if (typeof id !== 'string' || !id) throw new Error('Not signed in.');
  return id;
}

/**
 * Grade one answer client-side. Answers are `{ question_id, selected_answer,
 * correct_answer, difficulty?, response_time, sequence_index? }`; an explicit boolean
 * `is_correct` wins over the letter comparison.
 */
function amGrade(answer) {
  return typeof answer.is_correct === 'boolean'
    ? answer.is_correct
    : answer.selected_answer != null && answer.selected_answer === answer.correct_answer;
}

function amGraded(answers) {
  if (!Array.isArray(answers)) throw new Error('Answers must be an array.');
  return answers.map((a) => ({ ...a, is_correct: amGrade(a) }));
}

function amResponseTime(value) {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? n : AM_MIN_RESPONSE_TIME;
}

function amLevelFor(p) {
  const level = amClassifyMastery(p);
  if (amIsClassificationError(level)) throw new Error('Invalid mastery probability.');
  return level;
}

/** Subjects of the BSCS program, ordered by name. */
export async function amFetchSubjects() {
  const { data: programs, error: pErr } = await amSupabase
    .from('programs')
    .select('id')
    .eq('program_code', AM_DIAGNOSTIC_PROGRAM_CODE)
    .limit(1);
  amThrowIf(pErr);
  const program = programs?.[0];
  if (!program) return [];
  const { data, error } = await amSupabase
    .from('subjects')
    .select('id, subject_name')
    .eq('program_id', program.id)
    .order('subject_name', { ascending: true });
  amThrowIf(error);
  return data ?? [];
}

/** Topics of a subject, each with `questionCount` (0 means Unavailable). */
export async function amFetchTopics(subjectId) {
  const { data: topics, error } = await amSupabase
    .from('topics')
    .select('id, topic_name, description')
    .eq('subject_id', subjectId)
    .order('topic_name', { ascending: true });
  amThrowIf(error);
  const list = topics ?? [];
  if (list.length === 0) return [];
  const { data: rows, error: qErr } = await amSupabase
    .from('diagnostic_questions')
    .select('topic_id')
    .in('topic_id', list.map((t) => t.id));
  amThrowIf(qErr);
  const counts = new Map();
  for (const r of rows ?? []) counts.set(r.topic_id, (counts.get(r.topic_id) ?? 0) + 1);
  return list.map((t) => ({ ...t, questionCount: counts.get(t.id) ?? 0 }));
}

/**
 * Questions for the selected topics, at most 20 per topic. `correct_answer` is read
 * because grading is client-side (see the design's limitations).
 */
export async function amFetchQuestions(topicIds) {
  if (!Array.isArray(topicIds) || topicIds.length === 0) return [];
  const { data, error } = await amSupabase
    .from('diagnostic_questions')
    .select('id, topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty')
    .in('topic_id', topicIds)
    .limit(AM_MAX_SEQUENCE_LENGTH * topicIds.length);
  amThrowIf(error);
  const perTopic = new Map();
  return (data ?? []).filter((q) => {
    const n = (perTopic.get(q.topic_id) ?? 0) + 1;
    perTopic.set(q.topic_id, n);
    return n <= AM_MAX_SEQUENCE_LENGTH;
  });
}

/**
 * Insert one new diagnostic_attempts row per topic at Start (Req 3.9: every retake
 * creates new rows). Returns `{ [topicId]: attemptId }`.
 */
export async function amStartAttempts(user, { subjectId, topicIds }) {
  const userId = amUserId(user);
  if (!Array.isArray(topicIds) || topicIds.length === 0) throw new Error('Pick at least one topic.');
  const rows = topicIds.map((topicId) => ({ user_id: userId, subject_id: subjectId, topic_id: topicId }));
  const { data, error } = await amSupabase.from('diagnostic_attempts').insert(rows).select('id, topic_id');
  amThrowIf(error);
  const byTopic = {};
  for (const r of data ?? []) byTopic[r.topic_id] = r.id;
  return byTopic;
}

/**
 * Store one topic's answers on its attempt. Upserting with ignoreDuplicates makes a
 * retry after a partial failure safe (existing rows are kept unchanged).
 */
export async function amSaveAnswers(user, { attemptId, topicId, answers }) {
  const userId = amUserId(user);
  const graded = amGraded(answers);
  if (graded.length === 0) return;
  const rows = graded.map((a) => ({
    attempt_id: attemptId,
    user_id: userId,
    question_id: a.question_id,
    topic_id: topicId,
    selected_answer: a.selected_answer,
    correct_answer: a.correct_answer,
    is_correct: a.is_correct,
    response_time: amResponseTime(a.response_time),
  }));
  const { error } = await amSupabase
    .from('diagnostic_answers')
    .upsert(rows, { onConflict: 'attempt_id,question_id', ignoreDuplicates: true });
  amThrowIf(error);
}

/** Prediction_Result from /api/amPredict for one topic's answers (Bearer token via amApi). */
export async function amPredictTopic({ topicId, answers }) {
  const responses = amBuildResponseSequence(amGraded(answers));
  return amApi('amPredict', { topic_id: topicId, responses });
}

/** Fill in the attempt's completion, totals and mastery after a successful prediction. */
export async function amCompleteAttempt(user, { attemptId, answers, prediction }) {
  const userId = amUserId(user);
  const score = amScoreTopic(amGraded(answers));
  const p = prediction?.mastery_probability;
  const { error } = await amSupabase
    .from('diagnostic_attempts')
    .update({
      completed_at: new Date().toISOString(),
      total_questions: score.total_questions,
      correct_answers: score.correct_answers,
      accuracy: score.accuracy,
      mastery_probability: p,
      mastery_level: amLevelFor(p),
    })
    .eq('id', attemptId)
    .eq('user_id', userId);
  amThrowIf(error);
}

/** Upsert the caller's Mastery_Record for a topic; a retake overwrites it (Req 3.8). */
export async function amUpsertMastery(user, { topicId, answers, prediction }) {
  const userId = amUserId(user);
  const graded = amGraded(answers);
  const score = amScoreTopic(graded);
  const p = prediction?.mastery_probability;
  const avgRt = graded.reduce((s, a) => s + amResponseTime(a.response_time), 0) / graded.length;
  const row = {
    user_id: userId,
    topic_id: topicId,
    mastery_probability: p,
    mastery_level: amLevelFor(p),
    ml_predicted_label: prediction?.predicted_label ?? null,
    ml_confidence: typeof prediction?.confidence === 'number' ? prediction.confidence : null,
    total_questions: score.total_questions,
    correct_answers: score.correct_answers,
    accuracy: score.accuracy,
    average_response_time: avgRt,
    updated_at: new Date().toISOString(),
  };
  const { error } = await amSupabase.from('student_topic_mastery').upsert(row, { onConflict: 'user_id,topic_id' });
  amThrowIf(error);
}

/**
 * Recompute the caller's profile arrays from all stored Mastery_Records
 * (security-definer RPC, scoped to auth.uid()). Returns `{ strong, weak }`.
 */
export async function amApplyBridge() {
  const { data, error } = await amSupabase.rpc('am_apply_mastery_bridge');
  amThrowIf(error);
  const row = Array.isArray(data) ? data[0] : data;
  return { strong: row?.out_strong ?? [], weak: row?.out_weak ?? [] };
}
