// Collaborative notes: a Yjs document synced over a private Supabase Realtime
// broadcast channel (session:<id>), with a periodic text snapshot persisted to the DB.
import * as Y from 'yjs';
import { amSupabase } from './amSupabase.js';

function b64FromBytes(bytes) {
  let s = '';
  for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
  return btoa(s);
}
function bytesFromB64(b64) {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

/**
 * Wires a Y.Doc to a Realtime channel. Returns { doc, text, destroy, onLocalChange }.
 * On join we request a sync and reply with our full state so late joiners converge.
 */
export function amCreateNotesSync(sessionId, userId, { onUpdate } = {}) {
  const doc = new Y.Doc();
  const text = doc.getText('notes');
  const channel = amSupabase.channel('session:' + sessionId, { config: { broadcast: { self: false } } });
  let ready = false;

  const broadcast = (event, payload) => channel.send({ type: 'broadcast', event, payload });

  doc.on('update', (update, origin) => {
    if (origin === 'remote') return;
    broadcast('yupdate', { b64: b64FromBytes(update), from: userId });
    onUpdate?.(text.toString());
  });

  channel
    .on('broadcast', { event: 'yupdate' }, ({ payload }) => {
      if (payload?.from === userId) return;
      Y.applyUpdate(doc, bytesFromB64(payload.b64), 'remote');
      onUpdate?.(text.toString());
    })
    .on('broadcast', { event: 'ysync-request' }, () => {
      broadcast('ysync-state', { b64: b64FromBytes(Y.encodeStateAsUpdate(doc)), from: userId });
    })
    .on('broadcast', { event: 'ysync-state' }, ({ payload }) => {
      if (payload?.from === userId) return;
      Y.applyUpdate(doc, bytesFromB64(payload.b64), 'remote');
      onUpdate?.(text.toString());
    })
    .subscribe((status) => {
      if (status === 'SUBSCRIBED' && !ready) {
        ready = true;
        broadcast('ysync-request', { from: userId });
      }
    });

  return {
    doc,
    text,
    getText: () => text.toString(),
    setFromInput(nextValue) {
      const current = text.toString();
      if (current === nextValue) return;
      // Minimal diff: replace the changed suffix to keep cursors sane for simple edits.
      let start = 0;
      while (start < current.length && start < nextValue.length && current[start] === nextValue[start]) start++;
      let endOld = current.length;
      let endNew = nextValue.length;
      while (endOld > start && endNew > start && current[endOld - 1] === nextValue[endNew - 1]) {
        endOld--;
        endNew--;
      }
      doc.transact(() => {
        if (endOld > start) text.delete(start, endOld - start);
        if (endNew > start) text.insert(start, nextValue.slice(start, endNew));
      });
    },
    seed(initial) {
      if (initial && text.toString().length === 0) text.insert(0, initial);
    },
    destroy() {
      amSupabase.removeChannel(channel);
      doc.destroy();
    },
  };
}

export async function amPersistNotes(sessionId, userId, content) {
  await amSupabase.from('session_notes').upsert(
    { session_id: sessionId, content: content.slice(0, 50000), updated_by: userId, updated_at: new Date().toISOString() },
    { onConflict: 'session_id' },
  );
}
