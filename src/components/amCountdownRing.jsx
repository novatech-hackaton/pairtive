/**
 * Circular countdown (seconds left inside). `progress` 1 -> 0.
 * Pass `className` with size utilities (e.g. "size-12 sm:size-16") for a responsive ring;
 * otherwise it renders at a fixed `size` in px. The SVG scales via viewBox either way.
 */
export function AmCountdownRing({ secondsLeft, total, size = 64, className = '' }) {
  const r = (size - 8) / 2;
  const c = 2 * Math.PI * r;
  const progress = Math.max(0, Math.min(1, secondsLeft / total));
  const urgent = secondsLeft <= 5;
  return (
    <div
      className={`relative shrink-0 ${className}`}
      style={className ? undefined : { width: size, height: size }}
      role="timer"
      aria-label={`${Math.ceil(secondsLeft)} seconds left to decide`}
    >
      <svg viewBox={`0 0 ${size} ${size}`} className="size-full -rotate-90" aria-hidden>
        <defs>
          <linearGradient id="am-ring" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor="#6366f1" />
            <stop offset="1" stopColor="#22d3ee" />
          </linearGradient>
        </defs>
        <circle cx={size / 2} cy={size / 2} r={r} stroke="rgba(255,255,255,0.1)" strokeWidth="6" fill="none" />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          stroke={urgent ? '#fb7185' : 'url(#am-ring)'}
          strokeWidth="6"
          strokeLinecap="round"
          fill="none"
          strokeDasharray={c}
          strokeDashoffset={c * (1 - progress)}
          style={{ transition: 'stroke-dashoffset 0.25s linear' }}
        />
      </svg>
      <span className={`absolute inset-0 grid place-items-center font-display text-base font-bold sm:text-lg ${urgent ? 'text-rose-300' : 'text-white'}`} aria-hidden>
        {Math.ceil(secondsLeft)}
      </span>
    </div>
  );
}
