import { useId, useState } from 'react';
import { Star } from 'lucide-react';

const AM_STAR_LABELS = ['', 'Not helpful', 'Could be better', 'Okay', 'Great', 'Amazing'];

/** Accessible 1-5 star input (radio group, arrow keys work natively). */
export function AmStarInput({ value, onChange, label = 'Rating' }) {
  const [hover, setHover] = useState(0);
  const name = useId();
  const shown = hover || value;
  return (
    <fieldset>
      <legend className="am-sr-only">{label}</legend>
      <div className="flex items-center gap-1" onMouseLeave={() => setHover(0)}>
        {[1, 2, 3, 4, 5].map((n) => (
          <label key={n} className="cursor-pointer rounded-lg p-0.5 has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-brand-cyan" onMouseEnter={() => setHover(n)}>
            <input type="radio" name={name} value={n} checked={value === n} onChange={() => onChange(n)} className="am-sr-only" />
            <span className="am-sr-only">
              {n} star{n > 1 ? 's' : ''}, {AM_STAR_LABELS[n]}
            </span>
            <Star
              aria-hidden
              className={`size-9 transition duration-150 ${n <= shown ? 'scale-110 fill-amber-300 text-amber-300 drop-shadow-[0_0_10px_rgba(252,211,77,0.55)]' : 'text-slate-600'}`}
            />
          </label>
        ))}
        <span className="ml-2 min-w-24 text-sm text-slate-300" aria-live="polite">
          {AM_STAR_LABELS[shown] || ''}
        </span>
      </div>
    </fieldset>
  );
}

export function AmRatingBadge({ avg, count, className = '' }) {
  return (
    <span className={`inline-flex items-center gap-1 rounded-full bg-amber-300/10 px-2 py-0.5 text-xs font-semibold text-amber-200 ring-1 ring-amber-300/25 ${className}`}>
      <Star className="size-3.5 fill-amber-300 text-amber-300" aria-hidden />
      {count ? (
        <>
          {Number(avg).toFixed(1)}
          <span className="font-normal text-amber-200/70">({count})</span>
        </>
      ) : (
        'New'
      )}
      <span className="am-sr-only">{count ? ` average rating from ${count} ratings` : ' no ratings yet'}</span>
    </span>
  );
}
