export function AmCard({ as: Comp = 'div', className = '', glow = false, children, ...rest }) {
  return (
    <Comp className={`glass rounded-3xl p-5 sm:p-6 ${glow ? 'shadow-glow' : 'shadow-[0_20px_60px_-30px_rgb(0_0_0/0.8)]'} ${className}`} {...rest}>
      {children}
    </Comp>
  );
}

export function AmCardTitle({ icon: Icon, title, subtitle, action }) {
  return (
    <div className="mb-4 flex items-start justify-between gap-3">
      <div className="flex items-center gap-3">
        {Icon ? (
          <span className="grid size-10 shrink-0 place-items-center rounded-2xl bg-white/6 ring-1 ring-white/10">
            <Icon className="size-5 text-brand-cyan" aria-hidden />
          </span>
        ) : null}
        <div>
          <h2 className="text-lg font-semibold text-white">{title}</h2>
          {subtitle ? <p className="text-sm text-slate-400">{subtitle}</p> : null}
        </div>
      </div>
      {action}
    </div>
  );
}
