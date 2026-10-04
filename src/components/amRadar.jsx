import { AmAvatar } from './amAvatar.jsx';
import { AmSubjectIcon } from './amSubjectChip.jsx';

/** Pulsing radar shown while searching. Decorative; status text is announced separately. */
export function AmRadar({ name, avatarUrl, subjects = [] }) {
  return (
    // Scales with the available width (max 14rem on phones, 18rem from sm:), insets are relative so rings keep proportion.
    <div className="relative mx-auto grid aspect-square w-full max-w-56 place-items-center sm:max-w-72" aria-hidden>
      {[0, 0.8, 1.6].map((delay) => (
        <span key={delay} className="absolute inset-0 animate-radar rounded-full border-2 border-brand-violet/60" style={{ animationDelay: `${delay}s` }} />
      ))}
      <span className="absolute inset-[12%] rounded-full bg-[conic-gradient(from_0deg,rgba(34,211,238,0.35),transparent_35%)] motion-safe:animate-[spin_3s_linear_infinite]" />
      <span className="absolute inset-0 rounded-full ring-1 ring-white/10" />
      <span className="absolute inset-[22%] rounded-full ring-1 ring-white/10" />
      {subjects.slice(0, 4).map((s, i) => {
        const angle = (i / Math.max(1, subjects.length)) * Math.PI * 2 - Math.PI / 2;
        return (
          <span
            key={s}
            className="glass absolute grid size-10 animate-float place-items-center rounded-full"
            style={{ left: `calc(50% + ${Math.cos(angle) * 42}% - 1.25rem)`, top: `calc(50% + ${Math.sin(angle) * 42}% - 1.25rem)`, animationDelay: `${i * 0.7}s` }}
          >
            <AmSubjectIcon subject={s} className="size-5" />
          </span>
        );
      })}
      <span className="relative rounded-full p-1.5 shadow-glow-cyan">
        <AmAvatar name={name} src={avatarUrl} size="xl" />
      </span>
    </div>
  );
}
