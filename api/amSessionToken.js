// POST /api/amSessionToken { sessionId } -> { token, url } (members only)
import { AmHttpError, amAdmin, amCreateDailyToken, amDbError, amHandler, amIsUuid, amRequireUser } from '../server/amServer.js';

export async function amIssueSessionToken(admin, userId, sessionId, createToken = amCreateDailyToken) {
  if (!amIsUuid(sessionId)) throw new AmHttpError(400, 'sessionId is required');

  const { data: member, error } = await admin
    .from('session_members')
    .select('user_id, left_at')
    .eq('session_id', sessionId)
    .eq('user_id', userId)
    .maybeSingle();
  amDbError(error);
  if (!member) throw new AmHttpError(403, "You're not part of this session");
  if (member.left_at) throw new AmHttpError(410, 'You already left this session');

  const { data: session, error: sErr } = await admin
    .from('sessions')
    .select('id, daily_room_name, daily_room_url, ended_at')
    .eq('id', sessionId)
    .single();
  amDbError(sErr);
  if (session.ended_at) throw new AmHttpError(410, 'This session has ended');

  const { data: profile } = await admin.from('profiles').select('name, status, suspended_until').eq('id', userId).single();
  if (profile?.status === 'suspended' && new Date(profile.suspended_until) > new Date()) {
    throw new AmHttpError(403, 'Your account is suspended');
  }

  const token = await createToken({ roomName: session.daily_room_name, userId, userName: profile?.name });
  return { token, url: session.daily_room_url };
}

export default amHandler(async ({ req, body }) => {
  const admin = amAdmin();
  const user = await amRequireUser(req, admin);
  return amIssueSessionToken(admin, user.id, body.sessionId);
});
