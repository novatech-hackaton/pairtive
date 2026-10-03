import { useCallback, useEffect, useState } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import { TriangleAlert, X } from 'lucide-react';
import { amSupabase } from '../lib/amSupabase.js';
import { useAmPostgresChanges } from '../lib/amRealtime.js';

export function AmWarningsBanner({ userId }) {
  const [warnings, setWarnings] = useState([]);
  const load = useCallback(async () => {
    const { data } = await amSupabase
      .from('warnings')
      .select('id, message, created_at')
      .eq('user_id', userId)
      .is('seen_at', null)
      .order('created_at', { ascending: false })
      .limit(3);
    setWarnings(data ?? []);
  }, [userId]);
  useEffect(() => {
    load();
  }, [load]);
  useAmPostgresChanges('warn-banner', [{ event: 'INSERT', table: 'warnings', filter: `user_id=eq.${userId}` }], load, !!userId);

  async function dismiss(id) {
    setWarnings((w) => w.filter((x) => x.id !== id));
    await amSupabase.from('warnings').update({ seen_at: new Date().toISOString() }).eq('id', id);
  }

  return (
    <AnimatePresence>
      {warnings.map((w) => (
        <motion.div
          key={w.id}
          role="alert"
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, height: 0, marginBottom: 0 }}
          className="mb-4 flex items-start gap-3 rounded-2xl bg-amber-400/10 p-4 text-amber-100 ring-1 ring-amber-300/30"
        >
          <TriangleAlert className="mt-0.5 size-5 shrink-0 text-amber-300" aria-hidden />
          <div className="flex-1 text-sm">
            <p className="font-semibold">Community warning</p>
            <p className="text-amber-100/80">{w.message}</p>
          </div>
          <button type="button" onClick={() => dismiss(w.id)} aria-label="Dismiss warning" className="rounded-full p-1 hover:bg-white/10">
            <X className="size-4" aria-hidden />
          </button>
        </motion.div>
      ))}
    </AnimatePresence>
  );
}
