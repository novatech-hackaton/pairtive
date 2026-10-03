import { CircleHelp } from 'lucide-react';
import { AM_MATCH_CONFIG } from '../../shared/amMatchScore.js';

const AM_FACTORS = [
  { key: 'reciprocity', label: 'You can teach each other', color: '#8b5cf6' },
  { key: 'rating', label: 'Good ratings', color: '#fbbf24' },
  { key: 'success', label: 'Finishes sessions', color: '#34d399' },
  { key: 'wait', label: 'Waiting longest', color: '#22d3ee' },
  { key: 'language', label: 'Shared language', color: '#f472b6' },
];

export function AmHowMatchingWorks() {
  return (
    <details className="group glass rounded-2xl px-4 py-3">
      <summary className="flex cursor-pointer list-none items-center gap-2 text-sm text-slate-300 [&::-webkit-details-marker]:hidden">
        <CircleHelp className="size-4 text-brand-cyan" aria-hidden />
        <span>How matching works</span>
        <span className="ml-auto text-xs text-slate-500 group-open:hidden">Show</span>
        <span className="ml-auto hidden text-xs text-slate-500 group-open:inline">Hide</span>
      </summary>
      <div className="mt-3 space-y-4 text-sm text-slate-300">
        <p>
          We pair you with someone <strong className="text-white">strong where you&apos;re weak</strong>, who needs help with what you&apos;re good at. Better ratings and a
          shared language help. You won&apos;t see the same person again for 24 hours.
        </p>
        <ol className="list-decimal space-y-1.5 pl-5 text-slate-400">
          <li>Only people in the same mode who are online right now can match.</li>
          <li>At least one subject must line up. Blocked or reported people never match.</li>
          <li>For the first 30 seconds we look for a two-way swap. After that, one-way help is allowed too.</li>
          <li>&quot;Same school only&quot; is respected if either of you turned it on.</li>
          <li>Hitting Next or ignoring a match also keeps you apart for 24 hours (or until you&apos;ve both had 5 other matches).</li>
        </ol>
        <div>
          <p className="mb-2 text-xs tracking-wide text-slate-500 uppercase">What matters most</p>
          <ul className="space-y-1.5">
            {AM_FACTORS.map((f) => {
              const pct = Math.round(AM_MATCH_CONFIG.weights[f.key] * 100);
              return (
                <li key={f.key} className="flex items-center gap-3">
                  <span className="w-40 shrink-0 text-xs text-slate-300">{f.label}</span>
                  <span className="h-2 flex-1 overflow-hidden rounded-full bg-white/8" aria-hidden>
                    <span className="block h-full rounded-full" style={{ width: `${pct * 2.5}%`, background: f.color }} />
                  </span>
                  <span className="w-9 text-right text-xs font-semibold text-white">{pct}%</span>
                </li>
              );
            })}
          </ul>
          <p className="mt-2 text-xs text-slate-500">New here? You start with an average score, so you&apos;re never ranked last.</p>
        </div>
      </div>
    </details>
  );
}
