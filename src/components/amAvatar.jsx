import { useState } from 'react';
import { amInitials } from '../lib/amFormat.js';

const AM_AVATAR_GRADIENTS = [
  'from-indigo-500 to-violet-500',
  'from-violet-500 to-fuchsia-500',
  'from-cyan-500 to-indigo-500',
  'from-emerald-500 to-cyan-500',
  'from-amber-500 to-pink-500',
  'from-pink-500 to-violet-500',
];

function amHash(str = '') {
  let h = 0;
  for (let i = 0; i < str.length; i++) h = (h * 31 + str.charCodeAt(i)) | 0;
  return Math.abs(h);
}

const AM_SIZES = { xs: 'size-7 text-[0.65rem]', sm: 'size-9 text-xs', md: 'size-11 text-sm', lg: 'size-16 text-lg', xl: 'size-24 text-2xl' };

/** Circle avatar with image fallback to gradient initials. */
export function AmAvatar({ name = '', src, size = 'md', ring = false, online, className = '' }) {
  const [failed, setFailed] = useState(false);
  const gradient = AM_AVATAR_GRADIENTS[amHash(name) % AM_AVATAR_GRADIENTS.length];
  return (
    <span className={`relative inline-flex shrink-0 ${className}`}>
      <span
        className={`inline-grid place-items-center overflow-hidden rounded-full bg-linear-to-br font-semibold text-white ${gradient} ${AM_SIZES[size]} ${
          ring ? 'ring-2 ring-white/20 ring-offset-2 ring-offset-ink-900' : ''
        }`}
      >
        {src && !failed ? (
          <img src={src} alt="" className="size-full object-cover" onError={() => setFailed(true)} loading="lazy" />
        ) : (
          <span aria-hidden>{amInitials(name)}</span>
        )}
      </span>
      <span className="am-sr-only">{name}</span>
      {online != null ? (
        <span
          className={`absolute right-0 bottom-0 size-3 rounded-full ring-2 ring-ink-900 ${online ? 'bg-emerald-400' : 'bg-slate-500'}`}
          aria-hidden
        />
      ) : null}
    </span>
  );
}

/** Overlapping avatars for group threads. */
export function AmAvatarStack({ people = [], size = 'sm', max = 3 }) {
  const shown = people.slice(0, max);
  const extra = people.length - shown.length;
  return (
    <span className="flex -space-x-2.5">
      {shown.map((p) => (
        <span key={p.id ?? p.name} className="rounded-full ring-2 ring-ink-900">
          <AmAvatar name={p.name} src={p.avatar_url} size={size} />
        </span>
      ))}
      {extra > 0 ? (
        <span className={`grid place-items-center rounded-full bg-ink-600 font-semibold text-white ring-2 ring-ink-900 ${AM_SIZES[size]}`}>
          +{extra}
        </span>
      ) : null}
    </span>
  );
}
