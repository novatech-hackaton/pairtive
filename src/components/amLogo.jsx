export function AmLogo({ className = '', withText = true }) {
  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`}>
      <svg viewBox="0 0 64 64" className="size-9 drop-shadow-[0_6px_18px_rgba(99,102,241,0.55)]" aria-hidden>
        <defs>
          <linearGradient id="am-logo-g" x1="0" y1="0" x2="64" y2="64" gradientUnits="userSpaceOnUse">
            <stop offset="0" stopColor="#6366f1" />
            <stop offset="0.55" stopColor="#8b5cf6" />
            <stop offset="1" stopColor="#22d3ee" />
          </linearGradient>
        </defs>
        <rect width="64" height="64" rx="18" fill="#12122e" />
        <circle cx="25" cy="32" r="12.5" stroke="url(#am-logo-g)" strokeWidth="6" fill="none" />
        <circle cx="39" cy="32" r="12.5" stroke="url(#am-logo-g)" strokeWidth="6" fill="none" opacity="0.85" />
      </svg>
      {withText ? <span className="font-display text-xl font-bold tracking-tight text-white">pairtive</span> : null}
    </span>
  );
}

export function AmSpinner({ label = 'Loading', className = '' }) {
  return (
    <span role="status" className={`inline-flex items-center gap-3 text-slate-400 ${className}`}>
      <span className="relative size-6" aria-hidden>
        <span className="absolute inset-0 rounded-full border-2 border-white/10" />
        <span className="absolute inset-0 animate-spin rounded-full border-2 border-transparent border-t-brand-cyan border-r-brand-violet" />
      </span>
      <span className="text-sm">{label}</span>
    </span>
  );
}

export function AmFullScreenLoader({ label = 'Loading Pairtive' }) {
  return (
    <div className="grid min-h-dvh place-items-center">
      <div className="flex flex-col items-center gap-6">
        <AmLogo />
        <AmSpinner label={label} />
      </div>
    </div>
  );
}
