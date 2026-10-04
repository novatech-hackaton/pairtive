// Diagnostic_Page: select → answer → submit → results (Req 3.4, 3.5, 3.7–3.9, 5.1, 5.5).
// Ported from the module's dsDiagnostic.jsx and re-skinned with AmCard / AmButton
// (Req 7.2). Questions are native radios inside <fieldset>/<legend> (Req 7.4). The user
// id comes only from useAmAuth() (Req 8.2); all state is component-local.
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'motion/react';
import { ArrowLeft, ArrowRight, CheckCircle2, ClipboardCheck, LoaderCircle, RotateCcw, Send } from 'lucide-react';
import { useAmAuth } from '../lib/amAuth.jsx';
import { useAmMastery } from '../lib/amMastery.jsx';
import {
  amApplyBridge,
  amCompleteAttempt,
  amFetchQuestions,
  amFetchSubjects,
  amFetchTopics,
  amPredictTopic,
  amSaveAnswers,
  amStartAttempts,
  amUpsertMastery,
} from '../lib/amDiagnostic.js';
import { amScoreTopic } from '../../shared/amScorer.js';
import { amClassifyMastery, amIsClassificationError } from '../../shared/amMasteryClassifier.js';
import { AmButton } from '../components/amButton.jsx';
import { AmCard } from '../components/amCard.jsx';
import { AmMasteryBadge } from '../components/amMasteryBadge.jsx';
import { AmMasteryBar } from '../components/amMasteryBar.jsx';

const AM_LETTERS = ['A', 'B', 'C', 'D'];

/** Per-topic submit pipeline, run in order; a retry resumes from the failed step. */
export const AM_DIAGNOSTIC_STEPS = ['save', 'predict', 'complete', 'mastery', 'bridge'];

const AM_STEP_ERRORS = {
  save: "Couldn't save your answers.",
  predict: "Couldn't get your mastery prediction.",
  complete: "Couldn't save this attempt.",
  mastery: "Couldn't save your mastery result.",
  bridge: "Couldn't update your profile from the results.",
};

const AM_STEP_LABELS = {
  save: 'Saving answers',
  predict: 'Estimating mastery',
  complete: 'Saving attempt',
  mastery: 'Saving mastery',
  bridge: 'Updating profile',
};

/** Smallest response time we record, in seconds (diagnostic_answers.response_time > 0). */
export const AM_MIN_RESPONSE_SECONDS = 0.1;

/** Seconds between two Date.now() timestamps, clamped to a small positive minimum. */
export function amElapsedSeconds(from, to) {
  const s = (Number(to) - Number(from)) / 1000;
  return Number.isFinite(s) && s > AM_MIN_RESPONSE_SECONDS ? s : AM_MIN_RESPONSE_SECONDS;
}

function amLevelOf(prediction) {
  const p = prediction?.mastery_probability;
  if (typeof p !== 'number') return null;
  const level = amClassifyMastery(p);
  return amIsClassificationError(level) ? null : level;
}

const amPill = (active) =>
  `inline-flex h-9 items-center rounded-full px-4 text-sm font-medium ring-1 transition ${
    active ? 'bg-brand text-white shadow-glow ring-transparent' : 'bg-white/[0.03] text-slate-200 ring-white/10 hover:bg-white/[0.07]'
  }`;

const amTile = (active, disabled) =>
  `flex w-full cursor-pointer items-start gap-3 rounded-2xl p-3.5 ring-1 transition has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-offset-2 has-[:focus-visible]:outline-brand-cyan ${
    disabled
      ? 'cursor-not-allowed bg-white/[0.03] opacity-40 ring-white/10'
      : active
        ? 'bg-white/10 ring-2 ring-brand-violet'
        : 'bg-white/[0.03] ring-white/10 hover:bg-white/[0.07]'
  }`;

function AmInlineError({ message, onRetry }) {
  return (
    <div role="alert" className="text-sm text-rose-300">
      <p>{message}</p>
      {onRetry ? (
        <AmButton variant="secondary" size="sm" icon={RotateCcw} className="mt-2" onClick={onRetry}>
          Retry
        </AmButton>
      ) : null}
    </div>
  );
}

/** Run a topic's remaining pipeline steps, reporting each state change via onUpdate. */
async function amRunTopic(user, result, onUpdate) {
  let cur = { ...result, running: true, step: null, error: null };
  onUpdate(cur);
  for (let i = cur.nextStep; i < AM_DIAGNOSTIC_STEPS.length; i += 1) {
    const step = AM_DIAGNOSTIC_STEPS[i];
    const { attemptId, topicId, answers } = cur;
    try {
      if (step === 'save') await amSaveAnswers(user, { attemptId, topicId, answers });
      else if (step === 'predict') cur = { ...cur, prediction: await amPredictTopic({ topicId, answers }) };
      else if (step === 'complete') await amCompleteAttempt(user, { attemptId, answers, prediction: cur.prediction });
      else if (step === 'mastery') await amUpsertMastery(user, { topicId, answers, prediction: cur.prediction });
      else await amApplyBridge();
    } catch (err) {
      const detail = err?.message ? ` ${err.message}` : '';
      cur = { ...cur, running: false, step, error: `${AM_STEP_ERRORS[step]}${detail}` };
      onUpdate(cur);
      return cur;
    }
    cur = { ...cur, nextStep: i + 1 };
    onUpdate(cur);
  }
  cur = { ...cur, running: false };
  onUpdate(cur);
  return cur;
}

const amIsDone = (r) => r.nextStep >= AM_DIAGNOSTIC_STEPS.length;

export default function AmDiagnosticPage() {
  const { user, refreshProfile } = useAmAuth();
  const mastery = useAmMastery();
  const navigate = useNavigate();

  const [phase, setPhase] = useState('select');

  // Select phase.
  const [subjects, setSubjects] = useState([]);
  const [subjectsState, setSubjectsState] = useState({ loading: true, error: '' });
  const [subjectId, setSubjectId] = useState(null);
  const [topics, setTopics] = useState([]);
  const [topicsState, setTopicsState] = useState({ loading: false, error: '' });
  const [topicIds, setTopicIds] = useState([]);
  const [starting, setStarting] = useState(false);
  const [startError, setStartError] = useState('');
  const topicsReq = useRef(0);

  // Answer phase.
  const [questions, setQuestions] = useState([]);
  const [attempts, setAttempts] = useState({});
  const [current, setCurrent] = useState(0);
  const [selections, setSelections] = useState({});
  const timesRef = useRef({}); // question id → accumulated seconds on screen
  const shownAtRef = useRef(0);
  const questionHeadingRef = useRef(null);

  // Submit phase.
  const [results, setResults] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const [finishing, setFinishing] = useState(false);
  const resultsRef = useRef([]);
  const finishedRef = useRef(false);

  const loadSubjects = useCallback(async () => {
    setSubjectsState({ loading: true, error: '' });
    try {
      setSubjects(await amFetchSubjects());
      setSubjectsState({ loading: false, error: '' });
    } catch {
      setSubjectsState({ loading: false, error: 'Could not load subjects. Please try again.' });
    }
  }, []);
  useEffect(() => {
    loadSubjects();
  }, [loadSubjects]);

  const loadTopics = useCallback(async (id) => {
    const req = ++topicsReq.current;
    setTopics([]);
    setTopicsState({ loading: true, error: '' });
    try {
      const list = await amFetchTopics(id);
      if (req === topicsReq.current) {
        setTopics(list);
        setTopicsState({ loading: false, error: '' });
      }
    } catch {
      if (req === topicsReq.current) setTopicsState({ loading: false, error: 'Could not load topics. Please try again.' });
    }
  }, []);

  function selectSubject(id) {
    if (id === subjectId) return;
    setSubjectId(id);
    setTopicIds([]);
    setStartError('');
    loadTopics(id);
  }

  function toggleTopic(id) {
    setTopicIds((prev) => (prev.includes(id) ? prev.filter((t) => t !== id) : [...prev, id]));
  }

  const subject = useMemo(() => subjects.find((s) => s.id === subjectId) ?? null, [subjects, subjectId]);
  const topicNameById = useMemo(() => new Map(topics.map((t) => [t.id, t.topic_name])), [topics]);

  async function start() {
    setStartError('');
    setStarting(true);
    try {
      // Keep the user's pick order; only topics that actually have questions get an attempt.
      const ordered = topics.filter((t) => topicIds.includes(t.id) && t.questionCount > 0).map((t) => t.id);
      const loaded = await amFetchQuestions(ordered);
      const byTopic = new Map(ordered.map((id) => [id, []]));
      for (const q of loaded) byTopic.get(q.topic_id)?.push(q);
      const withQuestions = ordered.filter((id) => byTopic.get(id).length > 0);
      if (withQuestions.length === 0) {
        setStartError('No questions are available for the selected topics.');
        return;
      }
      const attemptIds = await amStartAttempts(user, { subjectId, topicIds: withQuestions });
      setAttempts(attemptIds);
      setQuestions(withQuestions.flatMap((id) => byTopic.get(id)));
      setSelections({});
      timesRef.current = {};
      shownAtRef.current = Date.now();
      setCurrent(0);
      setPhase('answer');
    } catch (err) {
      setStartError(err?.message ? `Could not start the diagnostic. ${err.message}` : 'Could not start the diagnostic.');
    } finally {
      setStarting(false);
    }
  }

  /** Add the time spent on the current question since it was shown. */
  function recordTime() {
    const q = questions[current];
    if (!q) return;
    const now = Date.now();
    timesRef.current[q.id] = (timesRef.current[q.id] ?? 0) + amElapsedSeconds(shownAtRef.current, now);
    shownAtRef.current = now;
  }

  function goTo(index) {
    recordTime();
    setCurrent(index);
    // Move focus to the new question so keyboard and screen-reader users follow along.
    requestAnimationFrame(() => questionHeadingRef.current?.focus());
  }

  function choose(questionId, letter) {
    setSelections((prev) => ({ ...prev, [questionId]: letter }));
  }

  const answeredCount = Object.keys(selections).length;
  const allAnswered = questions.length > 0 && answeredCount === questions.length;

  const updateResult = useCallback((next) => {
    resultsRef.current = resultsRef.current.map((r) => (r.topicId === next.topicId ? next : r));
    setResults(resultsRef.current);
  }, []);

  const finishIfDone = useCallback(async () => {
    const list = resultsRef.current;
    if (finishedRef.current || list.length === 0 || !list.every(amIsDone)) return;
    finishedRef.current = true;
    setFinishing(true);
    try {
      await refreshProfile();
      await mastery.refresh();
    } catch (err) {
      console.warn('Refreshing after the diagnostic failed:', err);
    }
    navigate('/skillgps');
  }, [refreshProfile, mastery, navigate]);

  async function submit() {
    if (!allAnswered || submitting) return;
    recordTime();
    const byTopic = new Map();
    questions.forEach((q, idx) => {
      const selected = selections[q.id];
      const answer = {
        question_id: q.id,
        selected_answer: selected,
        correct_answer: q.correct_answer,
        is_correct: selected === q.correct_answer,
        difficulty: q.difficulty,
        response_time: Math.max(AM_MIN_RESPONSE_SECONDS, timesRef.current[q.id] ?? AM_MIN_RESPONSE_SECONDS),
        sequence_index: idx,
      };
      if (!byTopic.has(q.topic_id)) byTopic.set(q.topic_id, []);
      byTopic.get(q.topic_id).push(answer);
    });
    const initial = [...byTopic.entries()].map(([topicId, answers]) => ({
      topicId,
      topicName: topicNameById.get(topicId) ?? 'Topic',
      attemptId: attempts[topicId],
      answers,
      score: amScoreTopic(answers),
      nextStep: 0,
      prediction: null,
      running: false,
      step: null,
      error: null,
    }));
    resultsRef.current = initial;
    finishedRef.current = false;
    setResults(initial);
    setSubmitting(true);
    setPhase('submit');
    // Sequential, so bridge calls never overlap; a failed topic doesn't stop the others.
    for (const r of initial) await amRunTopic(user, r, updateResult);
    setSubmitting(false);
    await finishIfDone();
  }

  async function retry(topicId) {
    const target = resultsRef.current.find((r) => r.topicId === topicId);
    if (!target || target.running || amIsDone(target)) return;
    await amRunTopic(user, target, updateResult);
    await finishIfDone();
  }

  const q = questions[current];
  const qTopicName = q ? topicNameById.get(q.topic_id) : '';
  const doneCount = results.filter(amIsDone).length;
  const failed = results.filter((r) => r.error);
  const running = results.find((r) => r.running);

  return (
    <div className="mx-auto max-w-3xl">
      <motion.header initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="mb-6">
        <p className="text-sm font-medium text-brand-cyan">Diagnostic</p>
        <h1 className="mt-1 text-3xl font-extrabold text-white">
          {phase === 'select' ? (
            <>
              Measure your <span className="text-gradient">skills</span>
            </>
          ) : phase === 'answer' ? (
            'Answer the questions'
          ) : (
            'Scoring your diagnostic'
          )}
        </h1>
        {phase === 'select' ? (
          <p className="mt-2 max-w-2xl text-slate-400">
            Pick a subject and the topics you want to be assessed on. Each topic has up to 20 questions, and your results decide who you
            match with.
          </p>
        ) : null}
      </motion.header>

      {phase === 'select' ? (
        <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
          <AmCard as="section" aria-labelledby="am-diag-subjects">
            <h2 id="am-diag-subjects" className="mb-4 text-sm font-semibold tracking-wider text-slate-300 uppercase">
              1 · Choose a subject
            </h2>
            {subjectsState.loading ? (
              <p className="text-sm text-slate-400">Loading subjects…</p>
            ) : subjectsState.error ? (
              <AmInlineError message={subjectsState.error} onRetry={loadSubjects} />
            ) : subjects.length === 0 ? (
              <p className="text-sm text-slate-400">No subjects are available yet.</p>
            ) : (
              <ul className="flex flex-wrap gap-2.5">
                {subjects.map((s) => (
                  <li key={s.id}>
                    <button type="button" aria-pressed={s.id === subjectId} onClick={() => selectSubject(s.id)} className={amPill(s.id === subjectId)}>
                      {s.subject_name}
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </AmCard>

          {subjectId !== null ? (
            <AmCard as="section" aria-labelledby="am-diag-topics">
              <h2 id="am-diag-topics" className="mb-4 text-sm font-semibold tracking-wider text-slate-300 uppercase">
                2 · Choose topics
              </h2>
              {topicsState.loading ? (
                <p className="text-sm text-slate-400">Loading topics…</p>
              ) : topicsState.error ? (
                <AmInlineError message={topicsState.error} onRetry={() => loadTopics(subjectId)} />
              ) : topics.length === 0 ? (
                <p className="text-sm text-slate-400">This subject has no topics yet.</p>
              ) : (
                <fieldset>
                  <legend className="mb-3 font-semibold text-white">{subject?.subject_name ?? 'Topics'}</legend>
                  <ul className="grid gap-2.5 sm:grid-cols-2">
                    {topics.map((t) => {
                      const unavailable = t.questionCount === 0;
                      const checked = topicIds.includes(t.id);
                      return (
                        <li key={t.id}>
                          <label className={amTile(checked, unavailable)}>
                            <input
                              type="checkbox"
                              className="mt-1 size-4 shrink-0 accent-brand-violet"
                              checked={checked}
                              disabled={unavailable}
                              onChange={() => toggleTopic(t.id)}
                            />
                            <span className="min-w-0 flex-1">
                              <span className="flex items-center justify-between gap-2">
                                <span className="font-semibold text-white">{t.topic_name}</span>
                                {unavailable ? <AmMasteryBadge level="Unavailable" size="sm" /> : null}
                              </span>
                              {t.description ? <span className="mt-1 block text-sm text-slate-400">{t.description}</span> : null}
                            </span>
                          </label>
                        </li>
                      );
                    })}
                  </ul>
                </fieldset>
              )}
            </AmCard>
          ) : null}

          {startError ? <AmInlineError message={startError} /> : null}
          <div className="flex flex-wrap items-center gap-4">
            <AmButton size="lg" iconRight={ArrowRight} loading={starting} disabled={topicIds.length === 0} onClick={start}>
              Start diagnostic
            </AmButton>
            <span className="text-sm text-slate-400" aria-live="polite">
              {topicIds.length > 0 ? `${topicIds.length} topic${topicIds.length > 1 ? 's' : ''} selected` : ''}
            </span>
          </div>
        </motion.div>
      ) : null}

      {phase === 'answer' && q ? (
        <div>
          <div className="mb-5">
            <div className="mb-2 flex items-center justify-between text-sm text-slate-400">
              <span>
                Question {current + 1} of {questions.length}
              </span>
              <span aria-live="polite">{answeredCount} answered</span>
            </div>
            <AmMasteryBar value={answeredCount / questions.length} ariaLabel="Questions answered" showValue={false} />
          </div>

          <motion.div key={q.id} initial={{ opacity: 0, x: 12 }} animate={{ opacity: 1, x: 0 }}>
            <AmCard>
              <p className="mb-3 text-sm font-medium text-brand-cyan">{qTopicName}</p>
              <fieldset>
                <legend ref={questionHeadingRef} tabIndex={-1} className="mb-5 text-xl leading-snug font-bold text-white">
                  {q.question}
                </legend>
                <div className="space-y-3">
                  {AM_LETTERS.map((letter) => {
                    const text = q[`choice_${letter.toLowerCase()}`];
                    const chosen = selections[q.id] === letter;
                    return (
                      <label key={letter} className={amTile(chosen, false)}>
                        <input
                          type="radio"
                          name={q.id}
                          value={letter}
                          checked={chosen}
                          onChange={() => choose(q.id, letter)}
                          className="am-sr-only"
                        />
                        <span
                          aria-hidden
                          className={`grid size-8 shrink-0 place-items-center rounded-lg text-sm font-bold ${chosen ? 'bg-brand text-white' : 'bg-white/10 text-slate-300'}`}
                        >
                          {letter}
                        </span>
                        <span className="self-center text-slate-100">
                          <span className="am-sr-only">{`${letter}.`}</span> {text}
                        </span>
                      </label>
                    );
                  })}
                </div>
              </fieldset>
            </AmCard>
          </motion.div>

          <div className="mt-6 flex items-center justify-between gap-3">
            <AmButton variant="secondary" icon={ArrowLeft} disabled={current === 0} onClick={() => goTo(current - 1)}>
              Previous
            </AmButton>
            {current < questions.length - 1 ? (
              <AmButton iconRight={ArrowRight} onClick={() => goTo(current + 1)}>
                Next
              </AmButton>
            ) : (
              <AmButton variant="success" icon={Send} disabled={!allAnswered} onClick={submit}>
                Submit diagnostic
              </AmButton>
            )}
          </div>
          {!allAnswered && current === questions.length - 1 ? (
            <p className="mt-3 text-sm text-amber-300">
              Answer all questions before submitting ({questions.length - answeredCount} left).
            </p>
          ) : null}
        </div>
      ) : null}

      {phase === 'submit' ? (
        <div className="space-y-4">
          <AmCard className="flex items-center gap-3">
            {failed.length > 0 && !running ? (
              <ClipboardCheck className="size-5 shrink-0 text-amber-300" aria-hidden />
            ) : doneCount === results.length ? (
              <CheckCircle2 className="size-5 shrink-0 text-emerald-300" aria-hidden />
            ) : (
              <LoaderCircle className="size-5 shrink-0 animate-spin text-brand-cyan" aria-hidden />
            )}
            <p className="text-sm text-slate-200" aria-live="polite" aria-atomic="true">
              {finishing
                ? 'All topics saved. Opening SkillGPS…'
                : running
                  ? `${AM_STEP_LABELS[AM_DIAGNOSTIC_STEPS[running.nextStep]] ?? 'Working'} for ${running.topicName} (${doneCount} of ${results.length} topics done)…`
                  : failed.length > 0
                    ? `${doneCount} of ${results.length} topics saved. Retry the topics below to finish.`
                    : submitting
                      ? `${doneCount} of ${results.length} topics done…`
                      : `${doneCount} of ${results.length} topics saved.`}
            </p>
          </AmCard>

          <ul className="grid gap-4 sm:grid-cols-2">
            {results.map((r) => {
              const level = amLevelOf(r.prediction);
              return (
                <li key={r.topicId}>
                  <AmCard className="h-full transition hover:bg-white/[0.08]">
                    <div className="flex items-start justify-between gap-3">
                      <h2 className="font-semibold text-white">{r.topicName}</h2>
                      <AmMasteryBadge level={level ?? 'Pending'} />
                    </div>
                    {level ? <AmMasteryBar className="mt-4" value={r.prediction.mastery_probability} label="Mastery" /> : null}
                    <p className="mt-3 text-sm text-slate-400">
                      Score:{' '}
                      <span className="font-semibold text-slate-200">
                        {r.score.correct_answers}/{r.score.total_questions}
                      </span>{' '}
                      ({Math.round(r.score.accuracy * 100)}%)
                    </p>
                    {r.error ? (
                      <div className="mt-3">
                        <p role="alert" className="text-sm text-rose-300">
                          {r.error}
                        </p>
                        <AmButton variant="secondary" size="sm" icon={RotateCcw} className="mt-2" onClick={() => retry(r.topicId)}>
                          Retry
                        </AmButton>
                      </div>
                    ) : amIsDone(r) ? (
                      <p className="mt-3 flex items-center gap-1.5 text-sm text-emerald-300">
                        <CheckCircle2 className="size-4" aria-hidden /> Saved
                      </p>
                    ) : null}
                  </AmCard>
                </li>
              );
            })}
          </ul>
        </div>
      ) : null}
    </div>
  );
}
