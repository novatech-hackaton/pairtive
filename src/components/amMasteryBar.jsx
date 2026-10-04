import { useId } from 'react';

/** Coerce a mastery probability (number or numeric string) to [0, 1]; non-finite → 0. */
export function amClampProbability(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return 0;
  return Math.min(1, Math.max(0, n));
}

/**
 * Accessible mastery progress bar (Req 7.2, 7.4).
 * `value` is a mastery_probability in [0, 1]; ARIA values are exposed as 0–100 percent.
 * Pass `label` for a visible label (wired via aria-labelledby), or `ariaLabel` for a hidden one.
 */
export function AmMasteryBar({ value, label, ariaLabel, showValue = true, className = '' }) {
  const labelId = useId();
  const pct = Math.round(amClampProbability(value) * 100);
  const hasLabel = label != null && label !== '';

  return (
    <div className={className}>
      {hasLabel || showValue ? (
        <div className="mb-1.5 flex items-center justify-between gap-3 text-sm">
          {hasLabel ? (
            <span id={labelId} className="min-w-0 truncate font-medium text-slate-200">
              {label}
            </span>
          ) : (
            <span />
          )}
          {showValue ? <span className="shrink-0 tabular-nums text-slate-400">{pct}%</span> : null}
        </div>
      ) : null}
      <div
        role="progressbar"
        aria-valuenow={pct}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuetext={`${pct}%`}
        aria-labelledby={hasLabel ? labelId : undefined}
        aria-label={hasLabel ? undefined : ariaLabel ?? 'Mastery'}
        className="h-2 w-full overflow-hidden rounded-full bg-white/[0.06] ring-1 ring-inset ring-white/10"
      >
        <div className="h-full rounded-full bg-brand transition-[width] duration-500" style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}
