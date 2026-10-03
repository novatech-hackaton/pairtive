import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { predict, PredictionError } from './dsPredictionClient.js';

const VALID = {
  predicted_label: 'Proficient',
  confidence: 0.84,
  probabilities: { Weak: 0.0, Developing: 0.16, Proficient: 0.84 },
  mastery_probability: 0.99,
};

beforeEach(() => {
  vi.stubEnv('VITE_PREDICTION_API_URL', 'http://127.0.0.1:8000');
});
afterEach(() => {
  vi.unstubAllEnvs();
  vi.restoreAllMocks();
});

function okFetch(body) {
  return vi.fn().mockResolvedValue({
    ok: true,
    status: 200,
    json: () => Promise.resolve(body),
  });
}

describe('Prediction_Client.predict', () => {
  it('posts the sequence and returns a valid Prediction_Result', async () => {
    const fetchImpl = okFetch(VALID);
    const result = await predict([{ is_correct: true }], '5', { fetchImpl });
    expect(result.mastery_probability).toBe(0.99);
    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe('http://127.0.0.1:8000/predict');
    expect(JSON.parse(init.body)).toEqual({ topic_id: '5', responses: [{ is_correct: true }] });
  });

  it('throws unreachable when the URL is not configured', async () => {
    vi.stubEnv('VITE_PREDICTION_API_URL', '');
    await expect(predict([{ is_correct: true }], '5', { fetchImpl: okFetch(VALID) }))
      .rejects.toMatchObject({ kind: 'unreachable' });
  });

  it('maps a 400 with fields to an invalid error', async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: false,
      status: 400,
      json: () => Promise.resolve({ error: 'bad', fields: ['responses: empty'] }),
    });
    await expect(predict([], '5', { fetchImpl })).rejects.toMatchObject({
      kind: 'invalid',
      fields: ['responses: empty'],
    });
  });

  it('reports a timeout when the request aborts', async () => {
    const fetchImpl = vi.fn().mockImplementation((_u, init) =>
      new Promise((_resolve, reject) => {
        init.signal.addEventListener('abort', () => {
          const e = new Error('aborted');
          e.name = 'AbortError';
          reject(e);
        });
      }),
    );
    await expect(predict([{ is_correct: true }], '5', { fetchImpl, timeoutMs: 5 }))
      .rejects.toMatchObject({ kind: 'timeout' });
  });

  it('reports unreachable when fetch rejects (network down)', async () => {
    const fetchImpl = vi.fn().mockRejectedValue(new Error('network'));
    await expect(predict([{ is_correct: true }], '5', { fetchImpl }))
      .rejects.toMatchObject({ kind: 'unreachable' });
  });

  it('rejects an invalid result body', async () => {
    const fetchImpl = okFetch({ predicted_label: 'Proficient' }); // missing mastery_probability
    await expect(predict([{ is_correct: true }], '5', { fetchImpl }))
      .rejects.toMatchObject({ kind: 'invalid' });
  });
});
