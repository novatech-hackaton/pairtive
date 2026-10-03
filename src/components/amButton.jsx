import { forwardRef } from 'react';
import { LoaderCircle } from 'lucide-react';

const AM_VARIANTS = {
  primary:
    'bg-brand text-white shadow-glow hover:brightness-110 active:brightness-95 disabled:opacity-50 disabled:shadow-none',
  secondary: 'glass text-slate-100 hover:bg-white/10 active:bg-white/5 disabled:opacity-50',
  ghost: 'text-slate-300 hover:text-white hover:bg-white/5 disabled:opacity-40',
  danger: 'bg-rose-500/90 text-white hover:bg-rose-500 shadow-[0_10px_30px_-10px_rgb(244_63_94/0.6)] disabled:opacity-50',
  success: 'bg-emerald-500/90 text-white hover:bg-emerald-500 shadow-[0_10px_30px_-10px_rgb(16_185_129/0.6)] disabled:opacity-50',
};

const AM_SIZES = {
  sm: 'h-9 px-3.5 text-sm gap-1.5 rounded-xl',
  md: 'h-11 px-5 text-[0.95rem] gap-2 rounded-2xl',
  lg: 'h-14 px-7 text-base gap-2.5 rounded-2xl font-semibold',
  xl: 'h-16 px-9 text-lg gap-3 rounded-3xl font-semibold',
};

export const AmButton = forwardRef(function AmButton(
  { as: Comp = 'button', variant = 'primary', size = 'md', icon: Icon, iconRight: IconRight, loading = false, className = '', children, disabled, ...rest },
  ref,
) {
  const isButton = Comp === 'button';
  return (
    <Comp
      ref={ref}
      className={`inline-flex select-none items-center justify-center font-medium whitespace-nowrap transition duration-200 ${AM_VARIANTS[variant]} ${AM_SIZES[size]} ${className}`}
      disabled={isButton ? disabled || loading : undefined}
      aria-busy={loading || undefined}
      {...(isButton && !rest.type ? { type: 'button' } : {})}
      {...rest}
    >
      {loading ? <LoaderCircle className="size-[1.1em] animate-spin" aria-hidden /> : Icon ? <Icon className="size-[1.15em]" aria-hidden /> : null}
      {children}
      {IconRight && !loading ? <IconRight className="size-[1.1em]" aria-hidden /> : null}
    </Comp>
  );
});

/**
 * Round icon-only button with an accessible label and a tooltip.
 * `active=false` renders the "off" (muted) style for toggles like mic/camera.
 */
export const AmIconButton = forwardRef(function AmIconButton(
  { icon: Icon, label, active = true, tone = 'default', size = 'md', className = '', tooltip = true, pressed, badge, ...rest },
  ref,
) {
  const sizes = { sm: 'size-9', md: 'size-12', lg: 'size-14' };
  const tones = {
    default: active ? 'glass text-white hover:bg-white/12' : 'bg-rose-500/90 text-white hover:bg-rose-500',
    brand: 'bg-brand text-white shadow-glow hover:brightness-110',
    danger: 'bg-rose-500 text-white hover:bg-rose-400',
    ghost: 'text-slate-300 hover:text-white hover:bg-white/8',
    rec: 'bg-rose-500/15 text-rose-300 ring-1 ring-rose-400/50 hover:bg-rose-500/25',
  };
  return (
    <span className="group relative inline-flex">
      <button
        ref={ref}
        type="button"
        aria-label={label}
        aria-pressed={pressed}
        className={`inline-flex items-center justify-center rounded-full transition duration-200 disabled:opacity-40 ${sizes[size]} ${tones[tone]} ${className}`}
        {...rest}
      >
        <Icon className={size === 'sm' ? 'size-4' : 'size-5'} aria-hidden />
        {badge ? (
          <span className="absolute -top-0.5 -right-0.5 grid min-w-5 place-items-center rounded-full bg-brand-cyan px-1 text-[0.65rem] font-bold text-ink-950">
            {badge}
          </span>
        ) : null}
      </button>
      {tooltip ? (
        <span
          role="tooltip"
          className="pointer-events-none absolute bottom-full left-1/2 z-30 mb-2 -translate-x-1/2 translate-y-1 rounded-lg bg-ink-700/95 px-2.5 py-1 text-xs font-medium whitespace-nowrap text-white opacity-0 shadow-lg ring-1 ring-white/10 transition group-hover:translate-y-0 group-hover:opacity-100 group-has-[:focus-visible]:translate-y-0 group-has-[:focus-visible]:opacity-100"
        >
          {label}
        </span>
      ) : null}
    </span>
  );
});
