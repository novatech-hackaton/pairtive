import { forwardRef, useId } from 'react';

export const AmField = forwardRef(function AmField({ label, hint, error, icon: Icon, className = '', as = 'input', ...rest }, ref) {
  const id = useId();
  const Comp = as;
  return (
    <div className={className}>
      {label ? (
        <label htmlFor={id} className="mb-1.5 block text-sm font-medium text-slate-200">
          {label}
        </label>
      ) : null}
      <div className="relative">
        {Icon ? <Icon className="pointer-events-none absolute top-1/2 left-3.5 size-4.5 -translate-y-1/2 text-slate-500" aria-hidden /> : null}
        <Comp
          ref={ref}
          id={id}
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? `${id}-err` : hint ? `${id}-hint` : undefined}
          className={`w-full rounded-2xl bg-white/[0.04] px-4 text-[0.95rem] text-white ring-1 transition placeholder:text-slate-500 focus:bg-white/[0.07] focus:outline-none focus:ring-2 focus:ring-brand-violet ${
            as === 'textarea' ? 'min-h-24 py-3' : 'h-12'
          } ${Icon ? 'pl-10' : ''} ${error ? 'ring-rose-400/70' : 'ring-white/10'}`}
          {...rest}
        />
      </div>
      {error ? (
        <p id={`${id}-err`} className="mt-1.5 text-sm text-rose-300" role="alert">
          {error}
        </p>
      ) : hint ? (
        <p id={`${id}-hint`} className="mt-1.5 text-xs text-slate-500">
          {hint}
        </p>
      ) : null}
    </div>
  );
});

/** Multi-select pill group (languages, tags). */
export function AmPillGroup({ label, options, value = [], onChange, max, error, hint }) {
  const id = useId();
  const toggle = (opt) => {
    if (value.includes(opt)) onChange(value.filter((v) => v !== opt));
    else if (!max || value.length < max) onChange([...value, opt]);
  };
  return (
    <fieldset aria-describedby={error ? `${id}-err` : undefined}>
      {label ? <legend className="mb-2 block text-sm font-medium text-slate-200">{label}</legend> : null}
      <div className="flex flex-wrap gap-2">
        {options.map((opt) => {
          const on = value.includes(opt);
          return (
            <button
              key={opt}
              type="button"
              role="checkbox"
              aria-checked={on}
              onClick={() => toggle(opt)}
              className={`h-9 rounded-full px-3.5 text-sm font-medium transition ${
                on ? 'bg-brand text-white shadow-glow' : 'bg-white/[0.05] text-slate-300 ring-1 ring-white/10 hover:bg-white/10'
              }`}
            >
              {opt}
            </button>
          );
        })}
      </div>
      {error ? (
        <p id={`${id}-err`} className="mt-1.5 text-sm text-rose-300" role="alert">
          {error}
        </p>
      ) : hint ? (
        <p className="mt-1.5 text-xs text-slate-500">{hint}</p>
      ) : null}
    </fieldset>
  );
}

export function AmSwitch({ checked, onChange, label, description }) {
  const id = useId();
  return (
    <div className="flex items-center justify-between gap-4">
      <div>
        <label htmlFor={id} className="text-sm font-medium text-white">
          {label}
        </label>
        {description ? <p className="text-xs text-slate-400">{description}</p> : null}
      </div>
      <button
        id={id}
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={`relative h-7 w-12 shrink-0 rounded-full transition ${checked ? 'bg-brand shadow-glow' : 'bg-white/15'}`}
      >
        <span className={`absolute top-1 size-5 rounded-full bg-white shadow transition-all ${checked ? 'left-6' : 'left-1'}`} aria-hidden />
      </button>
    </div>
  );
}
