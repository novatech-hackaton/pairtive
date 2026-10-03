import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MessageCircle, Search } from 'lucide-react';
import { useAmAuth } from '../lib/amAuth.jsx';
import { amSupabase } from '../lib/amSupabase.js';
import { useAmPostgresChanges } from '../lib/amRealtime.js';
import { amTimeAgo } from '../lib/amFormat.js';
import { AmAvatar, AmAvatarStack } from '../components/amAvatar.jsx';
import { AmEmptyState } from '../components/amEmptyState.jsx';
import { AmButton } from '../components/amButton.jsx';
import { AmSpinner } from '../components/amLogo.jsx';

export default function AmMessagesPage() {
  const { user } = useAmAuth();
  const navigate = useNavigate();
  const [threads, setThreads] = useState(null);

  const load = useCallback(async () => {
    const { data } = await amSupabase.rpc('am_list_conversations');
    setThreads(data ?? []);
  }, []);
  useEffect(() => { load(); }, [load]);
  useAmPostgresChanges('messages-list', [{ event: 'INSERT', table: 'messages' }], load, true);

  if (!threads) return <div className="grid place-items-center py-20"><AmSpinner label="Loading your chats" /></div>;

  if (threads.length === 0) {
    return (
      <AmEmptyState
        icon={MessageCircle}
        title="No chats yet"
        description="Find your first study buddy. Once you message someone, your conversation shows up here."
        action={<AmButton size="lg" icon={Search} onClick={() => navigate('/match')}>Find a match</AmButton>}
      />
    );
  }

  return (
    <div className="mx-auto max-w-2xl">
      <h1 className="mb-5 text-2xl font-bold text-white">Messages</h1>
      <ul className="space-y-2">
        {threads.map((t) => {
          const others = t.members ?? [];
          const title = others.map((m) => m.name).join(', ') || 'Conversation';
          const preview = t.last_body || (t.last_attachment_type ? (t.last_attachment_type.startsWith('image/') ? '📷 Photo' : '📎 Attachment') : '');
          const mine = t.last_sender_id === user.id;
          return (
            <li key={t.id}>
              <button
                onClick={() => navigate('/messages/' + t.id)}
                className="flex w-full items-center gap-3 rounded-2xl p-3 text-left ring-1 ring-white/8 transition hover:bg-white/5"
              >
                {others.length > 1 ? <AmAvatarStack people={others} /> : <AmAvatar name={others[0]?.name ?? ''} src={others[0]?.avatar_url} />}
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <p className="truncate font-semibold text-white">{title}</p>
                    <span className="shrink-0 text-xs text-slate-500">{amTimeAgo(t.last_message_at)}</span>
                  </div>
                  <p className={'truncate text-sm ' + (t.unread > 0 ? 'font-medium text-white' : 'text-slate-400')}>
                    {mine ? 'You: ' : ''}{preview}
                  </p>
                </div>
                {t.unread > 0 ? <span className="grid size-5 shrink-0 place-items-center rounded-full bg-brand-cyan text-[0.65rem] font-bold text-ink-950">{t.unread}</span> : null}
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
