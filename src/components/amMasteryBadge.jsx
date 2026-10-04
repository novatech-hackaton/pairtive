/**
 * Mastery level pill (replaces the module's ds-badge-* classes, Req 7.2).
 * The level is always shown as text so it never relies on color alone (Req 7.4).
 */
const AM_MASTERY_TONES = {
  Weak: 'bg-rose-400/15 text-rose-300 ring-rose-400/30',
  Developing: 'bg-amber-400/15 text-amber-300 ring-amber-400/30',
  Proficient: 'bg-emerald-400/15 text-emerald-300 ring-emerald-400/30',
};
const AM_MASTERY_TONE_UNKNOWN = 'bg-slate-400/15 text-slate-300 ring-slate-400/30';

/** Tailwind tone classes for a mastery level; unknown levels fall back to slate. */
export function amMasteryTone(level) {
  return AM_MASTERY_TONES[level] ?? AM_MASTERY_TONE_UNKNOWN;
}

export function AmMasteryBadge({ level, size = 'md', className = '' }) {
  const label = typeof level === 'string' && level.trim() ? level : 'Pending';
  const sizes = { sm: 'h-6 px-2 text-[11px]', md: 'h-7 px-2.5 text-xs' };
  return (
    <span
      className={`inline-flex shrink-0 items-center rounded-full font-semibold ring-1 ring-inset ${sizes[size] ?? sizes.md} ${amMasteryTone(level)} ${className}`}
    >
      {label}
    </span>
  );
}
