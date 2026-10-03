import { useCallback, useEffect, useMemo, useState } from 'react';
import { getSupabase } from '../lib/dsSupabaseClient.js';
import { classify, isClassificationError } from '../lib/dsMasteryClassifier.js';
import { buildRecommendations } from '../lib/dsRecommendationEngine.js';
import { requestWording } from '../lib/dsRecommendationServiceClient.js';

function levelOf(p) {
  const l = classify(p);
  return isClassificationError(l) ? 'Developing' : l;
}

function badgeClass(level) {
  if (level === 'Weak') return 'ds-badge ds-badge-weak';
  if (level === 'Developing') return 'ds-badge ds-badge-developing';
  if (level === 'Proficient') return 'ds-badge ds-badge-proficient';
  return 'ds-badge ds-badge-pending';
}

function Header() {
  return (
    <header className="sticky top-0 z-10 border-b border-white/10 bg-slate-950/40 backdrop-blur-xl">
      <div className="mx-auto flex max-w-4xl items-center justify-between px-6 py-4">
        <h1 className="text-xl font-extrabold tracking-tight"><span className="ds-gradient-text">SkillGPS</span></h1>
        <nav className="flex items-center gap-2 text-sm">
          <a href="/diagnostic" className="rounded-lg px-3 py-1.5 font-medium text-slate-300 hover:bg-white/5">Diagnostic</a>
          <a href="/skillgps" className="rounded-lg px-3 py-1.5 font-semibold text-white bg-white/10">SkillGPS</a>
        </nav>
      </div>
    </header>
  );
}

export default function DsSkillGPS() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [topics, setTopics] = useState([]);
  const [recs, setRecs] = useState([]);

  const load = useCallback(async () => {
    const supabase = getSupabase();
    if (!supabase) { setLoading(false); setError('Could not connect. Please refresh and try again.'); return; }
    setLoading(true); setError('');
    try {
      const { data: mastery, error: mErr } = await supabase
        .from('student_topic_mastery')
        .select('topic_id, mastery_probability, topics(topic_name)')
        .not('mastery_probability', 'is', null);
      if (mErr) throw mErr;
      const rows = (mastery ?? []).map((r) => {
        const p = Number(r.mastery_probability);
        return {
          topicId: r.topic_id,
          topicName: r.topics?.topic_name ?? `Topic ${r.topic_id}`,
          masteryProbability: p,
          masteryLevel: levelOf(p),
        };
      });
      setTopics(rows);

      const entries = buildRecommendations(rows);
      let wordingMap = new Map();
      try { wordingMap = await requestWording(entries); } catch { wordingMap = new Map(); }
      setRecs(entries.map((e) => ({ ...e, wording: wordingMap.get(String(e.topicId)) ?? e.recommendationContent })));
    } catch {
      setError('Could not load your mastery data. Please try again.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const stats = useMemo(() => {
    if (topics.length === 0) return null;
    const probs = topics.map((t) => t.masteryProbability);
    return {
      overall: Math.round((probs.reduce((a, b) => a + b, 0) / probs.length) * 100),
      strengths: topics.filter((t) => t.masteryLevel === 'Proficient').length,
      developing: topics.filter((t) => t.masteryLevel === 'Developing').length,
      weak: topics.filter((t) => t.masteryLevel === 'Weak').length,
    };
  }, [topics]);

  return (
    <main className="ds-app-bg">
      <Header />
      <div className="mx-auto max-w-4xl px-6 py-10">
        <div className="ds-animate-in">
          <p className="text-sm font-medium uppercase tracking-widest text-emerald-300/80">Your learning map</p>
          <h2 className="mt-1 text-3xl font-extrabold tracking-tight text-white">SkillGPS dashboard</h2>
        </div>

        {loading ? (
          <p className="mt-8 text-slate-400">Loading your mastery…</p>
        ) : error ? (
          <div className="ds-card mt-8 p-6" role="alert">
            <p className="text-rose-300">{error}</p>
            <button type="button" onClick={load} className="ds-btn-ghost mt-3">Retry</button>
          </div>
        ) : topics.length === 0 ? (
          <div className="ds-card mt-8 p-8 text-center">
            <p className="text-slate-300">No mastery data yet. Take a diagnostic to start building your map.</p>
            <a href="/diagnostic" className="ds-btn-primary mt-4">Take a diagnostic</a>
          </div>
        ) : (
          <div className="ds-animate-in mt-8 space-y-8">
            <div className="grid gap-4 sm:grid-cols-4">
              <div className="ds-card p-5"><p className="text-sm text-slate-400">Overall mastery</p><p className="mt-1 text-3xl font-extrabold ds-gradient-text">{stats.overall}%</p></div>
              <div className="ds-card p-5"><p className="text-sm text-slate-400">Strengths</p><p className="mt-1 text-3xl font-extrabold text-emerald-300">{stats.strengths}</p></div>
              <div className="ds-card p-5"><p className="text-sm text-slate-400">Developing</p><p className="mt-1 text-3xl font-extrabold text-amber-300">{stats.developing}</p></div>
              <div className="ds-card p-5"><p className="text-sm text-slate-400">Needs work</p><p className="mt-1 text-3xl font-extrabold text-rose-300">{stats.weak}</p></div>
            </div>

            <section className="ds-card p-6">
              <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-slate-300">Skill map</h3>
              <ul className="space-y-3">
                {topics.slice().sort((a, b) => a.masteryProbability - b.masteryProbability).map((t) => (
                  <li key={t.topicId}>
                    <div className="mb-1 flex items-center justify-between gap-3 text-sm">
                      <span className="font-medium text-white">{t.topicName}</span>
                      <span className={badgeClass(t.masteryLevel)}>{t.masteryLevel} · {Math.round(t.masteryProbability * 100)}%</span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-white/10">
                      <div className="h-full rounded-full bg-gradient-to-r from-indigo-500 to-emerald-400" style={{ width: `${Math.round(t.masteryProbability * 100)}%` }} />
                    </div>
                  </li>
                ))}
              </ul>
            </section>

            <section className="ds-card p-6">
              <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider text-slate-300">Recommendations</h3>
              <ul className="space-y-4">
                {recs.map((r) => (
                  <li key={r.topicId} className="rounded-xl border border-white/10 bg-white/5 p-4">
                    <div className="mb-1 flex items-center justify-between gap-3">
                      <span className="font-semibold text-white">{r.topicName}</span>
                      <span className={badgeClass(r.masteryLevel)}>{r.masteryLevel}</span>
                    </div>
                    <p className="text-sm leading-relaxed text-slate-300">{r.wording}</p>
                  </li>
                ))}
              </ul>
            </section>
          </div>
        )}
      </div>
    </main>
  );
}
