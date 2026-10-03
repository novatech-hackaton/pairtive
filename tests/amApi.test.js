// @vitest-environment node
import { describe, expect, it, vi } from 'vitest';
import { amIssueSessionToken } from '../api/amSessionToken.js';
import { amEnforce, amScoreReport } from '../api/amReportVerify.js';
import { amHandler, amRequireUser } from '../server/amServer.js';
import { amFakeAdmin } from './amFakeAdmin.js';

const S = '11111111-1111-4111-8111-111111111111';
const A = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const B = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const C = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

function amFakeRes() {
  const res = { statusCode: 200, headers: {}, body: null };
  res.setHeader = (k, v) => (res.headers[k] = v);
  res.status = (c) => ((res.statusCode = c), res);
  res.json = (b) => ((res.body = b), res);
  return res;
}

describe('api plumbing', () => {
  it('rejects non-POST and hides internal errors', async () => {
    const h = amHandler(async () => {
      throw new Error('secret stack');
    });
    const r1 = amFakeRes();
    await h({ method: 'GET' }, r1);
    expect(r1.statusCode).toBe(405);
    const r2 = amFakeRes();
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
    await h({ method: 'POST', body: {} }, r2);
    spy.mockRestore();
    expect(r2.statusCode).toBe(500);
    expect(r2.body.error).not.toMatch(/secret/);
  });

  it('requires a bearer token', async () => {
    await expect(amRequireUser({ headers: {} }, amFakeAdmin())).rejects.toMatchObject({ status: 401 });
    await expect(amRequireUser({ headers: { authorization: 'Bearer bad' } }, amFakeAdmin())).rejects.toMatchObject({ status: 401 });
  });
});

describe('amSessionToken', () => {
  const tables = () => ({
    session_members: [{ session_id: S, user_id: A, left_at: null }],
    sessions: [{ id: S, daily_room_name: 'pt-x', daily_room_url: 'https://x.daily.co/pt-x', ended_at: null }],
    profiles: [{ id: A, name: 'Ana', status: 'active' }, { id: B, name: 'Ben', status: 'active' }],
  });

  it('rejects non-members', async () => {
    const createToken = vi.fn();
    await expect(amIssueSessionToken(amFakeAdmin(tables()), B, S, createToken)).rejects.toMatchObject({ status: 403 });
    expect(createToken).not.toHaveBeenCalled();
  });

  it('issues a token for members', async () => {
    const createToken = vi.fn(async () => 'tok');
    const out = await amIssueSessionToken(amFakeAdmin(tables()), A, S, createToken);
    expect(out).toEqual({ token: 'tok', url: 'https://x.daily.co/pt-x' });
    expect(createToken).toHaveBeenCalledWith({ roomName: 'pt-x', userId: A, userName: 'Ana' });
  });

  it('rejects ended sessions and suspended users', async () => {
    const t = tables();
    t.sessions[0].ended_at = new Date().toISOString();
    await expect(amIssueSessionToken(amFakeAdmin(t), A, S, vi.fn())).rejects.toMatchObject({ status: 410 });
    const t2 = tables();
    t2.profiles[0] = { id: A, name: 'Ana', status: 'suspended', suspended_until: new Date(Date.now() + 3600e3).toISOString() };
    await expect(amIssueSessionToken(amFakeAdmin(t2), A, S, vi.fn())).rejects.toMatchObject({ status: 403 });
  });
});

describe('amReportVerify scoring (mocked models)', () => {
  const deps = {
    classifyFrames: vi.fn(async (imgs) => imgs.map(() => ({ predictions: [{ className: 'Porn', probability: 0.92 }] }))),
    classifyText: vi.fn(async () => [{ label: 'insult', results: [{ probabilities: [0.4, 0.6] }] }]),
    decodeLuminance: vi.fn(async (bufs) => bufs.map(() => 3)),
  };

  it('uses frames for inappropriate reports', async () => {
    const admin = amFakeAdmin({ messages: [] }, { 'report-evidence/r/0.jpg': Buffer.from('x') });
    const out = await amScoreReport(admin, { id: 'r', reason: 'inappropriate', reported_id: B, session_id: S, evidence_paths: ['r/0.jpg'] }, deps);
    expect(out.score).toBeCloseTo(0.92);
  });

  it('stores inappropriate reports with no visual evidence', async () => {
    const out = await amScoreReport(amFakeAdmin({ messages: [] }), { id: 'r', reason: 'inappropriate', reported_id: B, session_id: S }, deps);
    expect(out.score).toBeNull();
  });

  it('reads harassment messages server-side for the reported user only', async () => {
    const admin = amFakeAdmin({
      messages: [
        { sender_id: B, session_id: S, body: 'you are dumb', created_at: '2026-01-01' },
        { sender_id: A, session_id: S, body: 'reporter text', created_at: '2026-01-01' },
      ],
    });
    const out = await amScoreReport(admin, { id: 'r', reason: 'harassment', reported_id: B, session_id: S }, deps);
    expect(deps.classifyText).toHaveBeenCalledWith(['you are dumb']);
    expect(out.score).toBeCloseTo(0.6);
  });

  it('no-show: short stay + dark frames', async () => {
    const now = Date.now();
    const admin = amFakeAdmin(
      { session_members: [{ session_id: S, user_id: B, joined_at: new Date(now - 10_000).toISOString(), left_at: new Date(now).toISOString() }] },
      { 'report-evidence/r/0.jpg': Buffer.from('x') },
    );
    const out = await amScoreReport(admin, { id: 'r', reason: 'no_show', reported_id: B, session_id: S, evidence_paths: ['r/0.jpg'] }, deps);
    expect(out.score).toBeGreaterThanOrEqual(0.8);
  });
});

describe('amEnforce', () => {
  const base = () => ({
    strikes: [],
    reports: [],
    profiles: [{ id: B, status: 'active', suspended_until: null }],
    warnings: [],
    match_queue: [{ user_id: B }],
  });

  it('confirmed: strike + 24h suspension + removed from queue', async () => {
    const t = base();
    const report = { id: 'r1', reporter_id: A, reported_id: B, created_at: new Date().toISOString() };
    t.reports.push({ ...report, ai_verdict: 'confirmed', counted_in_strike: false });
    const admin = amFakeAdmin(t);
    const d = await amEnforce(admin, report, 'confirmed');
    expect(d.strike).toBe(true);
    expect(admin.db.strikes).toHaveLength(1);
    expect(admin.db.profiles[0].status).toBe('suspended');
    expect(new Date(admin.db.profiles[0].suspended_until).getTime() - Date.now()).toBeGreaterThan(23 * 3600e3);
    expect(admin.db.match_queue).toHaveLength(0);
  });

  it('uncertain: warning only', async () => {
    const t = base();
    const report = { id: 'r1', reporter_id: A, reported_id: B, created_at: new Date().toISOString() };
    t.reports.push({ ...report, ai_verdict: 'uncertain', counted_in_strike: false });
    const admin = amFakeAdmin(t);
    await amEnforce(admin, report, 'uncertain');
    expect(admin.db.warnings).toHaveLength(1);
    expect(admin.db.profiles[0].status).toBe('active');
  });

  it('safety net: 3 distinct reporters -> suspended even when rejected', async () => {
    const t = base();
    const now = new Date().toISOString();
    t.reports.push(
      { id: 'r1', reporter_id: A, reported_id: B, created_at: now, ai_verdict: 'rejected', counted_in_strike: false },
      { id: 'r2', reporter_id: C, reported_id: B, created_at: now, ai_verdict: 'rejected', counted_in_strike: false },
      { id: 'r3', reporter_id: S, reported_id: B, created_at: now, ai_verdict: 'rejected', counted_in_strike: false },
    );
    const admin = amFakeAdmin(t);
    const d = await amEnforce(admin, t.reports[2], 'rejected');
    expect(d.safetyNet).toBe(true);
    expect(admin.db.profiles[0].status).toBe('suspended');
    expect(admin.db.strikes).toHaveLength(0);
  });
});
