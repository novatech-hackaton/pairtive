import { useNavigate } from 'react-router-dom';
import { amSupabase } from '../lib/amSupabase.js';
import { amApi } from '../lib/amApi.js';
import { useAmPostgresChanges } from '../lib/amRealtime.js';
import { amToast } from './amToast.jsx';

/** Global: shows "X wants to study again" when a Reconnect invite arrives, and new warnings. */
export function AmInviteListener({ userId }) {
  const navigate = useNavigate();

  useAmPostgresChanges(
    'invites',
    [{ event: 'INSERT', table: 'session_invites' }],
    async ({ new: invite }) => {
      if (!invite || invite.from_user === userId || window.location.pathname.startsWith('/session/')) return;
      const { data: from } = await amSupabase.from('profiles').select('name').eq('id', invite.from_user).maybeSingle();
      amToast(`${from?.name ?? 'Your study buddy'} wants to study again`, {
        id: `invite-${invite.id}`,
        description: 'Join a video session right now?',
        duration: 60_000,
        action: {
          label: 'Join',
          onClick: async () => {
            try {
              const { data: status, error } = await amSupabase.rpc('am_respond_invite', { p_invite: invite.id, p_accept: true });
              if (error) throw error;
              if (status !== 'accepted') {
                amToast.error('This invite is no longer active.');
                return;
              }
              const { sessionId } = await amApi('amStartSession', { inviteId: invite.id });
              navigate(`/session/${sessionId}`);
            } catch (err) {
              amToast.error(err.message);
            }
          },
        },
        cancel: {
          label: 'Not now',
          onClick: () => amSupabase.rpc('am_respond_invite', { p_invite: invite.id, p_accept: false }),
        },
      });
    },
    !!userId,
  );

  useAmPostgresChanges(
    'warnings',
    [{ event: 'INSERT', table: 'warnings', filter: `user_id=eq.${userId}` }],
    ({ new: w }) => amToast.warning('Community warning', { description: w?.message, duration: 15_000 }),
    !!userId,
  );

  return null;
}
