import { useEffect, useRef, useState } from 'react';

export function useAmMediaQuery(query) {
  const get = () => (typeof window !== 'undefined' && window.matchMedia ? window.matchMedia(query).matches : false);
  const [matches, setMatches] = useState(get);
  useEffect(() => {
    const mql = window.matchMedia(query);
    const onChange = () => setMatches(mql.matches);
    onChange();
    mql.addEventListener('change', onChange);
    return () => mql.removeEventListener('change', onChange);
  }, [query]);
  return matches;
}

export const useAmIsDesktop = () => useAmMediaQuery('(min-width: 1024px)');

export function useAmInterval(fn, ms) {
  const saved = useRef(fn);
  useEffect(() => {
    saved.current = fn;
  }, [fn]);
  useEffect(() => {
    if (ms == null) return undefined;
    const id = setInterval(() => saved.current(), ms);
    return () => clearInterval(id);
  }, [ms]);
}

/** Re-render every `ms` (for countdowns / elapsed timers). */
export function useAmNow(ms = 1000) {
  const [now, setNow] = useState(() => Date.now());
  useAmInterval(() => setNow(Date.now()), ms);
  return now;
}

export function useAmLatest(value) {
  const ref = useRef(value);
  ref.current = value;
  return ref;
}
