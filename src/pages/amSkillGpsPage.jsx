// SkillGPS_Page (Req 3.6, 4.4, 7.2): overall mastery %, level counts, a per-topic skill
// map and local recommendations, plus "Continue to match". Ported from the module's
// pages/dsSkillGPS.jsx and re-skinned with AmCard / AmButton (ds-* → main mapping).
// Records come from useAmMastery(); nothing is fetched here.
import { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'motion/react';
import { ArrowRight, ClipboardCheck, Compass, Info, Lightbulb, Map as MapIcon, RefreshCw, RotateCcw } from 'lucide-react';
import { useAmMastery } from '../lib/amMastery.jsx';
import { amSummarizeMastery } from '../../shared/amMasterySummary.js';
import { amBuildRecommendations } from '../../shared/amRecommendations.js';
import { amBridgeMastery } from '../../shared/amMasteryBridge.js';
import { AmButton } from '../components/amButton.jsx';
import { AmCard, AmCardTitle } from '../components/amCard.jsx';
import { AmEmptyState } from '../components/amEmptyState.jsx';
import { AmSpinner } from '../components/amLogo.jsx';
import { AmMasteryBar, amClampProbability } from '../components/amMasteryBar.jsx';
import { AmMasteryBadge } from '../components/amMasteryBadge.jsx';

const AM_STATS = [
  { key: 'proficient', label: 'Proficient', tone: 'text-emerald-300' },
  { key: 'developing', label: 'Developing', tone: 'text-amber-300' },
  { key: 'weak', label: 'Weak', tone: 'text-rose-300' },
];

/** Normalize a Mastery_Record: numeric p in [0, 1] and a display name. */
function amNormalizeRecord(r) {
  return {
    ...r,
    topic_name: r.topic_name ?? `Topic ${r.topic_id}`,
    mastery_probability: amClampProbability(r.mastery_probability),
  };
}

function AmPageHeader({ onRetake }) {
  return (
    <div className="flex flex-wrap items-end justify-between gap-4">
      <div>
        <p className="text-sm font-medium text-brand-cyan">Your learning map</p>
        <h1 id="am-skillgps-title" className="mt-1 text-2xl font-extrabold text-white sm:text-3xl">
          <span className="text-gradient">SkillGPS</span> dashboard
        </h1>
      </div>
      {onRetake ? (
        <AmButton size="sm" variant="secondary" icon={RotateCcw} onClick={onRetake}>
          Retake Diagnostic
        </AmButton>
      ) : null}
    </div>
  );
}

export default function AmSkillGpsPage() {
  const { records, count, loading, error, refresh } = useAmMastery();
  const navigate = useNavigate();
  const goDiagnostic = () => navigate('/diagnostic');

  const view = useMemo(() => {
    const rows = (records ?? []).map(amNormalizeRecord);
    const bridged = amBridgeMastery(rows);
    return {
      summary: amSummarizeMastery(rows),
      // Skill map: weakest first, as in the module.
      skillMap: rows
        .slice()
        .sort((a, b) => a.mastery_probability - b.mastery_probability || String(a.topic_name).localeCompare(String(b.topic_name))),
      recommendations: amBuildRecommendations(rows),
      allDeveloping: rows.length > 0 && bridged.strong.length === 0 && bridged.weak.length === 0,
    };
  }, [records]);

  if (loading) {
    return (
      <div className="grid place-items-center py-20">
        <AmSpinner label="Loading your mastery" />
      </div>
    );
  }

  if (error && count === 0) {
    return (
      <div className="mx-auto max-w-4xl">
        <AmPageHeader />
        <AmCard className="mt-6">
          <p role="alert" className="text-rose-300">
            We couldn&apos;t load your diagnostic results.
          </p>
          <AmButton className="mt-4" size="sm" variant="secondary" icon={RefreshCw} onClick={() => refresh()}>
            Try again
          </AmButton>
        </AmCard>
      </div>
    );
  }

  if (count === 0) {
    return (
      <div className="mx-auto max-w-4xl">
        <AmPageHeader />
        <AmCard className="mt-6">
          <AmEmptyState
            icon={Compass}
            title="No mastery data yet"
            description="Take the diagnostic to build your skill map. We use it to find your strengths, the topics you need help with, and your matches."
            action={
              <AmButton size="lg" icon={ClipboardCheck} onClick={goDiagnostic}>
                Take Diagnostic
              </AmButton>
            }
          />
        </AmCard>
      </div>
    );
  }

  const { summary, skillMap, recommendations, allDeveloping } = view;

  return (
    <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="mx-auto max-w-4xl space-y-6">
      <AmPageHeader onRetake={goDiagnostic} />

      {error ? (
        <p role="alert" className="flex flex-wrap items-center gap-2 text-sm text-rose-300">
          Couldn&apos;t refresh your results.
          <button type="button" className="underline hover:text-white" onClick={() => refresh()}>
            Try again
          </button>
        </p>
      ) : null}

      <section aria-labelledby="am-skillgps-overview">
        <h2 id="am-skillgps-overview" className="sr-only">
          Overview
        </h2>
        <dl className="grid gap-3 sm:grid-cols-4">
          <div className="glass rounded-2xl p-4">
            <dt className="text-xs text-slate-400">Overall mastery</dt>
            <dd className="mt-1 text-3xl font-extrabold text-gradient">{summary.overallPct}%</dd>
          </div>
          {AM_STATS.map(({ key, label, tone }) => (
            <div key={key} className="glass rounded-2xl p-4">
              <dt className="text-xs text-slate-400">{label}</dt>
              <dd className={`mt-1 text-3xl font-extrabold ${tone}`}>
                {summary[key]}
                <span className="sr-only"> {summary[key] === 1 ? 'topic' : 'topics'}</span>
              </dd>
            </div>
          ))}
        </dl>
      </section>

      {allDeveloping ? (
        <div role="status" className="glass flex items-start gap-3 rounded-2xl p-4 ring-1 ring-amber-400/30">
          <Info className="mt-0.5 size-5 shrink-0 text-amber-300" aria-hidden />
          <p className="text-sm text-slate-200">
            All topics are Developing, so matching needs at least one strong or weak topic. Once a topic reaches
            Proficient or Weak, we&apos;ll use it to find study partners. Retake to update.
          </p>
        </div>
      ) : null}

      <AmCard as="section" aria-labelledby="am-skillgps-map">
        <AmCardTitle
          icon={MapIcon}
          title={<span id="am-skillgps-map">Skill map</span>}
          subtitle={`${summary.total} ${summary.total === 1 ? 'topic' : 'topics'} assessed`}
        />
        <ul className="space-y-4">
          {skillMap.map((r) => (
            <li key={r.topic_id} className="flex items-end gap-3">
              <AmMasteryBar className="min-w-0 flex-1" value={r.mastery_probability} label={r.topic_name} />
              <AmMasteryBadge level={r.mastery_level} size="sm" />
            </li>
          ))}
        </ul>
      </AmCard>

      <AmCard as="section" aria-labelledby="am-skillgps-recs">
        <AmCardTitle icon={Lightbulb} title={<span id="am-skillgps-recs">Recommendations</span>} subtitle="Start with the topics that need the most work" />
        <ul className="space-y-3">
          {recommendations.map((rec) => (
            <li key={rec.topicId} className="rounded-2xl bg-white/[0.03] p-4 ring-1 ring-white/10">
              <div className="mb-1 flex items-center justify-between gap-3">
                <h3 className="font-semibold text-white">{rec.topicName}</h3>
                <AmMasteryBadge level={rec.masteryLevel} size="sm" />
              </div>
              <p className="text-sm leading-relaxed text-slate-300">{rec.recommendationContent}</p>
            </li>
          ))}
        </ul>
      </AmCard>

      <div className="flex justify-end">
        <AmButton size="lg" iconRight={ArrowRight} onClick={() => navigate('/match')}>
          Continue to match
        </AmButton>
      </div>
    </motion.div>
  );
}
