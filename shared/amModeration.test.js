import { describe, expect, it } from 'vitest';
import {
  AM_DAY,
  amAggregateFrameScores,
  amDecideEnforcement,
  amNoShowScore,
  amNsfwFrameScore,
  amSpamScore,
  amToxicityScore,
  amVerdictFromScore,
} from './amModeration.js';

const NOW = 1_800_000_000_000;

describe('verdict mapping', () => {
  it('maps scores to verdicts', () => {
    expect(amVerdictFromScore(0.95)).toBe('confirmed');
    expect(amVerdictFromScore(0.8)).toBe('confirmed');
    expect(amVerdictFromScore(0.5)).toBe('uncertain');
    expect(amVerdictFromScore(0.4)).toBe('uncertain');
    expect(amVerdictFromScore(0.1)).toBe('rejected');
    expect(amVerdictFromScore(null)).toBe('stored');
  });
});

describe('model output scoring (mocked)', () => {
  it('scores NSFW predictions', () => {
    const explicit = [{ className: 'Porn', probability: 0.9 }, { className: 'Neutral', probability: 0.1 }];
    const safe = [{ className: 'Neutral', probability: 0.97 }, { className: 'Sexy', probability: 0.02 }];
    expect(amNsfwFrameScore(explicit)).toBeCloseTo(0.9);
    expect(amNsfwFrameScore(safe)).toBeLessThan(0.05);
    expect(amAggregateFrameScores([0.9, 0.85, 0.1])).toBeCloseTo(0.875);
    expect(amAggregateFrameScores([])).toBeNull();
  });
  it('scores toxicity output', () => {
    const out = [
      { label: 'insult', results: [{ probabilities: [0.1, 0.9] }, { probabilities: [0.99, 0.01] }] },
      { label: 'threat', results: [{ probabilities: [0.7, 0.3] }, { probabilities: [0.98, 0.02] }] },
    ];
    expect(amToxicityScore(out)).toBeCloseTo(0.9);
    expect(amToxicityScore([])).toBeNull();
  });
});

describe('rule-based checks', () => {
  it('flags link spam and repeats', () => {
    const t = (s) => new Date(NOW + s * 1000).toISOString();
    const links = Array.from({ length: 4 }, (_, i) => ({ body: `buy now www.cheap${i}.com`, created_at: t(i * 20) }));
    expect(amSpamScore(links)).toBeGreaterThanOrEqual(0.8);
    const repeats = Array.from({ length: 5 }, (_, i) => ({ body: 'hello??', created_at: t(i * 30) }));
    expect(amSpamScore(repeats)).toBeGreaterThanOrEqual(0.8);
    const normal = [{ body: 'Can you explain fractions?', created_at: t(0) }, { body: 'Thanks!', created_at: t(60) }];
    expect(amSpamScore(normal)).toBeLessThan(0.4);
  });
  it('flags no-shows', () => {
    expect(amNoShowScore({ durationMs: 10_000 })).toBeGreaterThanOrEqual(0.8);
    expect(amNoShowScore({ durationMs: 45_000 })).toBeCloseTo(0.6);
    expect(amNoShowScore({ durationMs: 600_000, darkFrameRatio: 1 })).toBeGreaterThanOrEqual(0.8);
    expect(amNoShowScore({ durationMs: 600_000, darkFrameRatio: 0 })).toBeLessThan(0.4);
  });
});

describe('enforcement', () => {
  const base = { reporterId: 'r1', now: NOW, priorStrikes: [], openUncertain: [], recentReports: [{ reporter_id: 'r1', created_at: NOW }] };

  it('rejected = no action', () => {
    const d = amDecideEnforcement({ ...base, verdict: 'rejected' });
    expect(d).toMatchObject({ strike: false, warning: false, suspendUntil: null });
  });

  it('strike ladder: 24h, 7d (2nd within 30d), 30d (3rd)', () => {
    const first = amDecideEnforcement({ ...base, verdict: 'confirmed' });
    expect(first.strike).toBe(true);
    expect(first.suspendUntil).toBe(NOW + AM_DAY);

    const second = amDecideEnforcement({ ...base, verdict: 'confirmed', priorStrikes: [{ created_at: NOW - 10 * AM_DAY }] });
    expect(second.suspendUntil).toBe(NOW + 7 * AM_DAY);

    const secondLate = amDecideEnforcement({ ...base, verdict: 'confirmed', priorStrikes: [{ created_at: NOW - 40 * AM_DAY }] });
    expect(secondLate.suspendUntil).toBe(NOW + AM_DAY);

    const third = amDecideEnforcement({
      ...base,
      verdict: 'confirmed',
      priorStrikes: [{ created_at: NOW - 100 * AM_DAY }, { created_at: NOW - 50 * AM_DAY }],
    });
    expect(third.suspendUntil).toBe(NOW + 30 * AM_DAY);
  });

  it('first uncertain = warning only', () => {
    const d = amDecideEnforcement({ ...base, verdict: 'uncertain' });
    expect(d.warning).toBe(true);
    expect(d.strike).toBe(false);
    expect(d.suspendUntil).toBeNull();
  });

  it('two uncertain reports from different reporters within 7 days = strike', () => {
    const d = amDecideEnforcement({
      ...base,
      verdict: 'uncertain',
      openUncertain: [{ id: 'old', reporter_id: 'r2', created_at: NOW - 2 * AM_DAY }],
    });
    expect(d.strike).toBe(true);
    expect(d.consumeUncertainIds).toEqual(['old']);
    expect(d.suspendUntil).toBe(NOW + AM_DAY);
  });

  it('same reporter twice does not make a strike', () => {
    const d = amDecideEnforcement({
      ...base,
      verdict: 'uncertain',
      openUncertain: [{ id: 'old', reporter_id: 'r1', created_at: NOW - AM_DAY }],
    });
    expect(d.strike).toBe(false);
    expect(d.warning).toBe(true);
  });

  it('safety net: 3 distinct reporters in 7 days suspends 24h even if AI rejected', () => {
    const d = amDecideEnforcement({
      ...base,
      verdict: 'rejected',
      recentReports: [
        { reporter_id: 'r1', created_at: NOW },
        { reporter_id: 'r2', created_at: NOW - AM_DAY },
        { reporter_id: 'r3', created_at: NOW - 3 * AM_DAY },
      ],
    });
    expect(d.safetyNet).toBe(true);
    expect(d.suspendUntil).toBe(NOW + AM_DAY);
  });

  it('safety net ignores reports older than 7 days', () => {
    const d = amDecideEnforcement({
      ...base,
      verdict: 'rejected',
      recentReports: [
        { reporter_id: 'r1', created_at: NOW },
        { reporter_id: 'r2', created_at: NOW - AM_DAY },
        { reporter_id: 'r3', created_at: NOW - 8 * AM_DAY },
      ],
    });
    expect(d.safetyNet).toBe(false);
  });

  it('never shortens an existing suspension', () => {
    const d = amDecideEnforcement({ ...base, verdict: 'confirmed', currentSuspendedUntil: NOW + 20 * AM_DAY });
    expect(d.strike).toBe(true);
    expect(d.suspendUntil).toBeNull();
  });
});
