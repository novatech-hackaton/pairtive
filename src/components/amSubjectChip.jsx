import { BookOpen, Code2, FlaskConical, Landmark, Languages, Sigma, Check } from 'lucide-react';
import { AM_SUBJECT_META } from '../../shared/amSubjects.js';

const AM_SUBJECT_ICONS = { Math: Sigma, English: BookOpen, Science: FlaskConical, Filipino: Languages, History: Landmark, Programming: Code2 };

export function AmSubjectIcon({ subject, className = 'size-4' }) {
  const Icon = AM_SUBJECT_ICONS[subject] ?? BookOpen;
  return <Icon className={className} style={{ color: AM_SUBJECT_META[subject]?.color }} aria-hidden />;
}

/** Static subject pill. */
export function AmSubjectChip({ subject, size = 'md', className = '' }) {
  const meta = AM_SUBJECT_META[subject] ?? { color: '#a5b4fc', soft: 'rgba(165,180,252,0.15)' };
  const sizes = { sm: 'h-7 px-2.5 text-xs gap-1.5', md: 'h-9 px-3.5 text-sm gap-2', lg: 'h-11 px-4 text-base gap-2' };
  return (
    <span
      className={`inline-flex items-center rounded-full font-medium text-white ring-1 ${sizes[size]} ${className}`}
      style={{ background: meta.soft, '--tw-ring-color': `${meta.color}55` }}
    >
      <AmSubjectIcon subject={subject} className={size === 'sm' ? 'size-3.5' : 'size-4'} />
      {subject}
    </span>
  );
}

/** Selectable subject tile used in onboarding / profile. */
export function AmSubjectToggle({ subject, selected, disabled, onToggle, hint }) {
  const meta = AM_SUBJECT_META[subject];
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={selected}
      disabled={disabled}
      onClick={onToggle}
      className={`group relative flex items-center gap-3 rounded-2xl p-3.5 text-left ring-1 transition duration-200 ${
        selected ? 'bg-white/10 ring-2' : 'bg-white/[0.03] ring-white/10 hover:bg-white/[0.07]'
      } disabled:opacity-40`}
      style={selected ? { '--tw-ring-color': meta.color, boxShadow: `0 10px 30px -14px ${meta.color}` } : undefined}
    >
      <span className="grid size-10 shrink-0 place-items-center rounded-xl" style={{ background: meta.soft }}>
        <AmSubjectIcon subject={subject} className="size-5" />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block font-semibold text-white">{subject}</span>
        {hint ? <span className="block truncate text-xs text-slate-400">{hint}</span> : null}
      </span>
      <span
        className={`grid size-6 place-items-center rounded-full transition ${selected ? 'text-ink-950' : 'ring-1 ring-white/20'}`}
        style={selected ? { background: meta.color } : undefined}
        aria-hidden
      >
        {selected ? <Check className="size-4" strokeWidth={3} /> : null}
      </span>
    </button>
  );
}
