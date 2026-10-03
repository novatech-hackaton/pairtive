import { useCallback, useEffect, useMemo, useState } from 'react';
import { getSupabase, getUserId } from '../lib/dsSupabaseClient.js';
import { scoreTopic } from '../lib/dsScorer.js';
import { buildResponseSequence } from '../lib/dsResponseSequence.js';
import { predict, PredictionError } from '../lib/dsPredictionClient.js';
import { classify, isClassificationError } from '../lib/dsMasteryClassifier.js';

const BSCS_PROGRAM_CODE = 'BSCS';
const LETTERS = ['A', 'B', 'C', 'D'];

async function fetchBscsSubjects(supabase) {
  const { data: programs, error: programError } = await supabase
    .from('programs').select('id').eq('program_code', BSCS_PROGRAM_CODE).limit(1);
  if (programError) throw programError;
  const program = programs?.[0];
  if (!program) return [];
  const { data: subjects, error: subjectsError } = await supabase
    .from('subjects').select('id, subject_name').eq('program_id', program.id)
    .order('subject_name', { ascending: true });
  if (subjectsError) throw subjectsError;
  return subjects ?? [];
}

async function fetchTopicsWithCounts(supabase, subjectId) {
  const { data: topics, error: topicsError } = await supabase
    .from('topics').select('id, topic_name, description').eq('subject_id', subjectId)
    .order('topic_name', { ascending: true });
  if (topicsError) throw topicsError;
  const topicList = topics ?? [];
  if (topicList.length === 0) return [];
  const topicIds = topicList.map((t) => t.id);
  const { data: questions, error: questionsError } = await supabase
    .from('diagnostic_questions').select('topic_id').in('topic_id', topicIds);
  if (questionsError) throw questionsError;
  const countByTopicId = new Map();
  for (const row of questions ?? []) {
    countByTopicId.set(row.topic_id, (countByTopicId.get(row.topic_id) ?? 0) + 1);
  }
  return topicList.map((t) => ({ ...t, questionCount: countByTopicId.get(t.id) ?? 0 }));
}

async function fetchQuestionsForTopics(supabase, topicIds) {
  const { data, error } = await supabase
    .from('diagnostic_questions')
    .select('id, topic_id, question, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty')
    .in('topic_id', topicIds).limit(20 * topicIds.length);
  if (error) throw error;
  return data ?? [];
}

function badgeClass(level) {
  if (level === 'Weak') return 'ds-badge ds-badge-weak';
  if (level === 'Developing') return 'ds-badge ds-badge-developing';
  if (level === 'Proficient') return 'ds-badge ds-badge-proficient';
  return 'ds-badge ds-badge-pending';
}

/**
 * Persist a topic's mastery for the current user, if one is available.
 *
 * Integration seam: the owning user id comes from getUserId() (host app / Supabase
 * session). When no user id is available (standalone/demo), persistence is skipped
 * and the diagnostic still shows results. Idempotent on (user_id, topic_id).
 */
async function persistMastery({ supabase, userId, topicId, score, masteryProbability, masteryLevel, predictedLabel, confidence, answers }) {
  if (!supabase || !userId) return { saved: false, reason: 'no-user' };
  const avgRt = answers.length
    ? answers.reduce((a, b) => a + (Number(b.response_time) || 0), 0) / answers.length
    : null;
  const row = {
    user_id: userId,
    topic_id: topicId,
    mastery_probability: masteryProbability,
    mastery_level: masteryLevel,
    ml_predicted_label: predictedLabel ?? masteryLevel,
    ml_confidence: confidence ?? null,
    total_questions: score.total_questions,
    correct_answers: score.correct_answers,
    accuracy: score.accuracy,
    average_response_time: avgRt && avgRt > 0 ? avgRt : null,
    updated_at: new Date().toISOString(),
  };
  try {
    const { error } = await supabase
      .from('student_topic_mastery')
      .upsert(row, { onConflict: 'user_id,topic_id' });
    if (error) return { saved: false, reason: 'db-error' };
    return { saved: true };
  } catch {
    return { saved: false, reason: 'db-error' };
  }
}

function Shell({ children }) {
  return (
    <main className="ds-app-bg">
      <header className="sticky top-0 z-10 border-b border-white/10 bg-slate-950/40 backdrop-blur-xl">
        <div className="mx-auto flex max-w-4xl items-center justify-between px-6 py-4">
          <h1 className="text-xl font-extrabold tracking-tight">
            <span className="ds-gradient-text">Diagnostic</span>
          </h1>
          <nav className="flex items-center gap-2 text-sm">
            <a href="/diagnostic" className="rounded-lg px-3 py-1.5 font-semibold text-white bg-white/10">Diagnostic</a>
            <a href="/skillgps" className="rounded-lg px-3 py-1.5 font-medium text-slate-300 hover:bg-white/5">SkillGPS</a>
          </nav>
        </div>
      </header>
      <div className="mx-auto max-w-4xl px-6 py-8">{children}</div>
    </main>
  );
}

export default function DsDiagnostic() {
  const [phase, setPhase] = useState('select');
  const [subjects, setSubjects] = useState([]);
  const [subjectsLoading, setSubjectsLoading] = useState(true);
  const [subjectsError, setSubjectsError] = useState('');
  const [selectedSubjectId, setSelectedSubjectId] = useState(null);
  const [topics, setTopics] = useState([]);
  const [topicsLoading, setTopicsLoading] = useState(false);
  const [topicsError, setTopicsError] = useState('');
  const [selectedTopicIds, setSelectedTopicIds] = useState(() => new Set());
  const [questions, setQuestions] = useState([]);
  const [current, setCurrent] = useState(0);
  const [selections, setSelections] = useState(() => new Map());
  const [questionStart, setQuestionStart] = useState(0);
  const [elapsed, setElapsed] = useState(() => new Map());
  const [startError, setStartError] = useState('');
  const [results, setResults] = useState([]);
  const [submitting, setSubmitting] = useState(false);

  const loadSubjects = useCallback(async () => {
    const supabase = getSupabase();
    if (!supabase) { setSubjectsLoading(false); setSubjectsError('Could not load subjects. Please refresh the page and try again.'); return; }
    setSubjectsLoading(true); setSubjectsError('');
    try { setSubjects(await fetchBscsSubjects(supabase)); }
    catch { setSubjectsError('Could not load subjects. Please refresh the page and try again.'); }
    finally { setSubjectsLoading(false); }
  }, []);
  useEffect(() => { loadSubjects(); }, [loadSubjects]);

  const loadTopics = useCallback(async (subjectId) => {
    const supabase = getSupabase();
    if (!supabase) { setTopicsLoading(false); setTopicsError('Could not load topics. Please try selecting the subject again.'); return; }
    setTopicsLoading(true); setTopicsError('');
    try { setTopics(await fetchTopicsWithCounts(supabase, subjectId)); }
    catch { setTopics([]); setTopicsError('Could not load topics. Please try selecting the subject again.'); }
    finally { setTopicsLoading(false); }
  }, []);

  function handleSelectSubject(subjectId) {
    setSelectedSubjectId(subjectId); setSelectedTopicIds(new Set());
    setTopics([]); setTopicsError(''); loadTopics(subjectId);
  }
  function handleToggleTopic(topic) {
    if (topic.questionCount === 0) return;
    setSelectedTopicIds((prev) => {
      const next = new Set(prev);
      if (next.has(topic.id)) next.delete(topic.id); else next.add(topic.id);
      return next;
    });
  }

  const startEnabled = selectedTopicIds.size > 0;
  const selectedSubject = useMemo(() => subjects.find((s) => s.id === selectedSubjectId) ?? null, [subjects, selectedSubjectId]);
  const topicNameById = useMemo(() => { const m = new Map(); for (const t of topics) m.set(t.id, t.topic_name); return m; }, [topics]);

  async function handleStart() {
    const supabase = getSupabase();
    if (!supabase) { setStartError('Could not start the diagnostic. Please refresh and try again.'); return; }
    setStartError('');
    const topicIds = Array.from(selectedTopicIds);
    let loaded;
    try { loaded = await fetchQuestionsForTopics(supabase, topicIds); }
    catch { setStartError('Could not load questions. Please try again.'); return; }
    const byTopic = new Map();
    for (const q of loaded) {
      if (!byTopic.has(q.topic_id)) byTopic.set(q.topic_id, []);
      const arr = byTopic.get(q.topic_id); if (arr.length < 20) arr.push(q);
    }
    const flat = [];
    for (const tid of topicIds) for (const q of byTopic.get(tid) ?? []) flat.push(q);
    if (flat.length === 0) { setStartError('No questions are available for the selected topics.'); return; }
    setQuestions(flat); setCurrent(0); setSelections(new Map()); setElapsed(new Map());
    setQuestionStart(Date.now()); setPhase('answer');
  }

  function recordElapsed(questionId) {
    const seconds = Math.max(0.1, (Date.now() - questionStart) / 1000);
    setElapsed((prev) => { const next = new Map(prev); next.set(questionId, (next.get(questionId) ?? 0) + seconds); return next; });
  }
  function handleSelectAnswer(questionId, letter) {
    setSelections((prev) => { const next = new Map(prev); next.set(questionId, letter); return next; });
  }
  function goTo(index) { const q = questions[current]; if (q) recordElapsed(q.id); setCurrent(index); setQuestionStart(Date.now()); }

  const answeredCount = selections.size;
  const allAnswered = questions.length > 0 && answeredCount === questions.length;

  async function handleSubmit() {
    const q = questions[current]; if (q) recordElapsed(q.id);
    setSubmitting(true);
    const elapsedNow = new Map(elapsed);
    if (q) { const extra = Math.max(0.1, (Date.now() - questionStart) / 1000); elapsedNow.set(q.id, (elapsedNow.get(q.id) ?? 0) + extra); }
    const byTopic = new Map();
    questions.forEach((question, idx) => {
      const sel = selections.get(question.id) ?? null;
      const answer = { question, selected_answer: sel, correct_answer: question.correct_answer,
        is_correct: sel != null && sel === question.correct_answer,
        response_time: elapsedNow.get(question.id) ?? 1, sequence_index: idx };
      if (!byTopic.has(question.topic_id)) byTopic.set(question.topic_id, []);
      byTopic.get(question.topic_id).push(answer);
    });
    // Resolve the owning user once (host-provided or Supabase session; null in
    // standalone demo). Persistence is skipped when no user id is available.
    const supabase = getSupabase();
    const userId = await getUserId();

    const out = [];
    for (const [topicId, answers] of byTopic.entries()) {
      const score = scoreTopic(answers);
      let masteryLevel = null, masteryProbability = null, pending = false, message = '', saved = false;
      try {
        const sequence = buildResponseSequence(answers);
        const result = await predict(sequence, String(topicId));
        masteryProbability = result.mastery_probability;
        const level = classify(masteryProbability);
        masteryLevel = isClassificationError(level) ? null : level;
        if (masteryLevel == null) {
          pending = true; message = 'The mastery result could not be classified.';
        } else {
          const res = await persistMastery({
            supabase, userId, topicId, score, masteryProbability, masteryLevel,
            predictedLabel: result.predicted_label, confidence: result.confidence, answers,
          });
          saved = res.saved;
        }
      } catch (err) {
        pending = true;
        message = err instanceof PredictionError ? 'The prediction service could not be reached. You can retry.' : 'Could not compute mastery. You can retry.';
      }
      out.push({ topicId, topicName: topicNameById.get(topicId) ?? `Topic ${topicId}`, answers, score, masteryLevel, masteryProbability, pending, message, saved });
    }
    setResults(out); setSubmitting(false); setPhase('results');
  }

  async function handleRetry(topicId) {
    setResults((prev) => prev.map((r) => (r.topicId === topicId ? { ...r, pending: true, message: 'Retrying…' } : r)));
    const target = results.find((r) => r.topicId === topicId); if (!target) return;
    try {
      const sequence = buildResponseSequence(target.answers);
      const result = await predict(sequence, String(topicId));
      const level = classify(result.mastery_probability);
      const masteryLevel = isClassificationError(level) ? null : level;
      setResults((prev) => prev.map((r) => (r.topicId === topicId ? { ...r, masteryProbability: result.mastery_probability, masteryLevel, pending: masteryLevel == null, message: masteryLevel == null ? 'Could not classify the result.' : '' } : r)));
    } catch {
      setResults((prev) => prev.map((r) => (r.topicId === topicId ? { ...r, pending: true, message: 'The prediction service could not be reached. You can retry.' } : r)));
    }
  }

  function handleRestart() { setPhase('select'); setQuestions([]); setResults([]); setSelections(new Map()); setElapsed(new Map()); }

  const q = questions[current];
  const progressPct = questions.length ? Math.round(((current + 1) / questions.length) * 100) : 0;

  return (
    <Shell>
      {phase === 'select' ? (
        <div className="ds-animate-in space-y-8">
          <div>
            <p className="text-sm font-medium uppercase tracking-widest text-indigo-300/80">Bayesian Knowledge Tracing</p>
            <h2 className="mt-1 text-3xl font-extrabold tracking-tight text-white">Start a diagnostic</h2>
            <p className="mt-2 max-w-2xl text-slate-400">Pick a subject and the topics you want to be assessed on. Each topic runs up to 20 questions and estimates your mastery.</p>
          </div>

          <section aria-labelledby="ds-subjects-heading" className="ds-card p-6">
            <h3 id="ds-subjects-heading" className="mb-4 text-sm font-semibold uppercase tracking-wider text-slate-300">1 · Choose a subject</h3>
            {subjectsLoading ? (
              <p className="text-sm text-slate-400">Loading subjects…</p>
            ) : subjectsError ? (
              <div role="alert" className="text-sm text-rose-300">
                <p className="mb-2">{subjectsError}</p>
                <button type="button" onClick={loadSubjects} className="ds-btn-ghost">Retry</button>
              </div>
            ) : subjects.length === 0 ? (
              <p className="text-sm text-slate-400">No subjects are available yet.</p>
            ) : (
              <ul className="flex flex-wrap gap-2.5">
                {subjects.map((subject) => {
                  const isSelected = subject.id === selectedSubjectId;
                  return (
                    <li key={subject.id}>
                      <button type="button" aria-pressed={isSelected} onClick={() => handleSelectSubject(subject.id)} className={isSelected ? 'ds-chip ds-chip-active' : 'ds-chip'}>
                        {subject.subject_name}
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}
          </section>

          {selectedSubjectId !== null ? (
            <section aria-labelledby="ds-topics-heading" className="ds-card ds-animate-in p-6">
              <h3 id="ds-topics-heading" className="mb-4 text-sm font-semibold uppercase tracking-wider text-slate-300">
                2 · {selectedSubject ? `Topics in ${selectedSubject.subject_name}` : 'Choose topics'}
              </h3>
              {topicsLoading ? (
                <p className="text-sm text-slate-400">Loading topics…</p>
              ) : topicsError ? (
                <div role="alert" className="text-sm text-rose-300">
                  <p className="mb-2">{topicsError}</p>
                  <button type="button" onClick={() => loadTopics(selectedSubjectId)} className="ds-btn-ghost">Retry</button>
                </div>
              ) : topics.length === 0 ? (
                <p className="text-sm text-slate-400">This subject has no topics yet.</p>
              ) : (
                <ul className="grid gap-2.5 sm:grid-cols-2">
                  {topics.map((topic) => {
                    const unavailable = topic.questionCount === 0;
                    const isSelected = selectedTopicIds.has(topic.id);
                    const cls = unavailable ? 'ds-option ds-option-disabled' : isSelected ? 'ds-option ds-option-active' : 'ds-option';
                    return (
                      <li key={topic.id}>
                        <button type="button" role="checkbox" aria-checked={isSelected} aria-disabled={unavailable} disabled={unavailable} onClick={() => handleToggleTopic(topic)} className={cls}>
                          <span className="flex items-center justify-between gap-3">
                            <span className="font-semibold text-white">{topic.topic_name}</span>
                            {unavailable ? (<span className="ds-badge ds-badge-pending">Unavailable</span>) : isSelected ? (<span className="ds-badge ds-badge-proficient">Selected</span>) : null}
                          </span>
                          {topic.description ? (<span className="mt-1 block text-sm text-slate-400">{topic.description}</span>) : null}
                        </button>
                      </li>
                    );
                  })}
                </ul>
              )}
            </section>
          ) : null}

          {startError ? (<p role="alert" className="text-sm text-rose-300">{startError}</p>) : null}
          <div className="flex items-center gap-4">
            <button type="button" onClick={handleStart} disabled={!startEnabled} className="ds-btn-primary">Start diagnostic</button>
            {selectedTopicIds.size > 0 ? (<span className="text-sm text-slate-400">{selectedTopicIds.size} topic{selectedTopicIds.size > 1 ? 's' : ''} selected</span>) : null}
          </div>
        </div>
      ) : null}

      {phase === 'answer' && q ? (
        <div className="ds-animate-in">
          <div className="mb-6">
            <div className="mb-2 flex items-center justify-between text-sm text-slate-400">
              <span>Question {current + 1} of {questions.length}</span>
              <span>{answeredCount} answered</span>
            </div>
            <div className="h-2 w-full overflow-hidden rounded-full bg-white/10">
              <div className="h-full rounded-full bg-gradient-to-r from-indigo-500 to-emerald-400 transition-all duration-300" style={{ width: `${progressPct}%` }} />
            </div>
          </div>

          <div className="ds-card p-6 sm:p-8">
            <h2 className="mb-6 text-xl font-bold leading-snug text-white">{q.question}</h2>
            <ul className="space-y-3">
              {LETTERS.map((letter) => {
                const text = q[`choice_${letter.toLowerCase()}`];
                const chosen = selections.get(q.id) === letter;
                return (
                  <li key={letter}>
                    <button type="button" aria-pressed={chosen} onClick={() => handleSelectAnswer(q.id, letter)} className={chosen ? 'ds-option ds-option-active flex items-center gap-3' : 'ds-option flex items-center gap-3'}>
                      <span className={'flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-sm font-bold ' + (chosen ? 'bg-indigo-500 text-white' : 'bg-white/10 text-slate-300')}>{letter}</span>
                      <span className="text-slate-100">{text}</span>
                    </button>
                  </li>
                );
              })}
            </ul>
          </div>

          <div className="mt-6 flex items-center justify-between gap-3">
            <button type="button" onClick={() => goTo(Math.max(0, current - 1))} disabled={current === 0} className="ds-btn-ghost">Previous</button>
            {current < questions.length - 1 ? (
              <button type="button" onClick={() => goTo(current + 1)} className="ds-btn-primary">Next</button>
            ) : (
              <button type="button" onClick={handleSubmit} disabled={!allAnswered || submitting} className="ds-btn-success">{submitting ? 'Submitting…' : 'Submit diagnostic'}</button>
            )}
          </div>
          {!allAnswered && current === questions.length - 1 ? (<p className="mt-3 text-sm text-amber-300">Answer all questions before submitting ({questions.length - answeredCount} left).</p>) : null}
        </div>
      ) : null}

      {phase === 'results' ? (
        <div className="ds-animate-in space-y-6">
          <div>
            <h2 className="text-3xl font-extrabold tracking-tight text-white">Your results</h2>
            <p className="mt-1 text-slate-400">Mastery estimated by Bayesian Knowledge Tracing from your answer sequence.</p>
          </div>
          <ul className="grid gap-4 sm:grid-cols-2">
            {results.map((r) => (
              <li key={r.topicId} className="ds-card ds-card-hover p-5">
                <div className="flex items-start justify-between gap-3">
                  <span className="font-semibold text-white">{r.topicName}</span>
                  <span className={r.pending ? badgeClass(null) : badgeClass(r.masteryLevel)}>{r.pending ? 'Pending' : r.masteryLevel}</span>
                </div>
                {!r.pending && r.masteryProbability != null ? (
                  <div className="mt-4">
                    <div className="mb-1 flex items-center justify-between text-xs text-slate-400">
                      <span>Mastery</span><span>{Math.round(r.masteryProbability * 100)}%</span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-white/10">
                      <div className="h-full rounded-full bg-gradient-to-r from-indigo-500 to-emerald-400" style={{ width: `${Math.round(r.masteryProbability * 100)}%` }} />
                    </div>
                  </div>
                ) : null}
                <p className="mt-3 text-sm text-slate-400">Score: <span className="font-semibold text-slate-200">{r.score.correct_answers}/{r.score.total_questions}</span> ({Math.round(r.score.accuracy * 100)}%)</p>
                {r.pending ? (
                  <div className="mt-3">
                    <p className="mb-2 text-sm text-rose-300">{r.message}</p>
                    <button type="button" onClick={() => handleRetry(r.topicId)} className="ds-btn-ghost">Retry</button>
                  </div>
                ) : null}
              </li>
            ))}
          </ul>
          <button type="button" onClick={handleRestart} className="ds-btn-primary">Take another diagnostic</button>
        </div>
      ) : null}
    </Shell>
  );
}
