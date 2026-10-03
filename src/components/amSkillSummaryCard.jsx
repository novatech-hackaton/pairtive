// Home SkillGPS summary (Req 4.1–4.3, 4.5, 4.6): overall mastery % and level counts
// with a "Retake Diagnostic" button when the user has Mastery_Records, otherwise a
// "Take Diagnostic" call to action. Both go to /diagnostic.
import { useNavigate } from 'react-router-dom';
import { ClipboardCheck, Gauge, RefreshCw, RotateCcw } from 'lucide-react';
import { useAmMastery } from '../lib/amMastery.jsx';
import { amSummarizeMastery } from '../../shared/amMasterySummary.js';
import { AmButton } from './amButton.jsx';
import { AmCard, AmCardTitle } from './amCard.jsx';
import { AmMasteryBar } from './amMasteryBar.jsx';

const AM_LEVELS = [
  { key: 'proficient', label: 'Proficient' },
  { key: 'developing', label: 'Developing' },
  { key: 'weak', label: 'Weak' },
];

function amTopics(n) {
  return `${n} ${n === 1 ? 'topic' : 'topics'}`;
}

export function AmSkillSummaryCard() {
  const { records, count, loading, error, refresh } = useAmMastery();
  const navigate = useNavigate();
  const goDiagnostic = () => navigate('/diagnostic');

  if (loading) {
    return (
      <AmCard as="section" aria-busy="true" aria-labelledby="am-skill-summary-title">
        <AmCardTitle icon={Gauge} title={<span id="am-skill-summary-title">Your SkillGPS</span>} subtitle="Loading your results…" />
        <div className="space-y-3" aria-hidden>
          <div className="h-4 w-1/3 animate-pulse rounded bg-white/[0.06]" />
          <div className="h-2 w-full animate-pulse rounded-full bg-white/[0.06]" />
          <div className="h-2 w-2/3 animate-pulse rounded-full bg-white/[0.06]" />
        </div>
      </AmCard>
    );
  }

  if (error && count === 0) {
    return (
      <AmCard as="section" aria-labelledby="am-skill-summary-title">
        <AmCardTitle icon={Gauge} title={<span id="am-skill-summary-title">Your SkillGPS</span>} />
        <p role="alert" className="text-sm text-rose-300">
          We couldn&apos;t load your diagnostic results.
        </p>
        <AmButton className="mt-4" size="sm" variant="secondary" icon={RefreshCw} onClick={() => refresh()}>
          Try again
        </AmButton>
      </AmCard>
    );
  }

  if (count === 0) {
    return (
      <AmCard as="section" aria-labelledby="am-skill-summary-title">
        <AmCardTitle
          icon={ClipboardCheck}
          title={<span id="am-skill-summary-title">Find your strengths</span>}
          subtitle="A short diagnostic sets up your SkillGPS"
        />
        <p className="text-sm text-slate-300">
          Answer a few questions per topic and we&apos;ll measure what you&apos;re great at and where you need help, then use it for matching.
        </p>
        <AmButton className="mt-4" icon={ClipboardCheck} onClick={goDiagnostic}>
          Take Diagnostic
        </AmButton>
      </AmCard>
    );
  }

  const summary = amSummarizeMastery(records);

  return (
    <AmCard as="section" aria-labelledby="am-skill-summary-title">
      <AmCardTitle
        icon={Gauge}
        title={<span id="am-skill-summary-title">Your SkillGPS</span>}
        subtitle={`${amTopics(summary.total)} assessed`}
        action={
          <AmButton size="sm" variant="secondary" icon={RotateCcw} onClick={goDiagnostic}>
            Retake Diagnostic
          </AmButton>
        }
      />
      <AmMasteryBar value={summary.overallPct / 100} label="Overall mastery" />
      <ul className="mt-4 grid gap-3 sm:grid-cols-3" aria-label="Topics by mastery level">
        {AM_LEVELS.map(({ key, label }) => (
          <li key={key}>
            <AmMasteryBar
              value={summary.total ? summary[key] / summary.total : 0}
              label={`${label}: ${amTopics(summary[key])}`}
              showValue={false}
            />
          </li>
        ))}
      </ul>
      {error ? (
        <p role="alert" className="mt-4 flex flex-wrap items-center gap-2 text-sm text-rose-300">
          Couldn&apos;t refresh your results.
          <button type="button" className="underline hover:text-white" onClick={() => refresh()}>
            Try again
          </button>
        </p>
      ) : null}
    </AmCard>
  );
}
