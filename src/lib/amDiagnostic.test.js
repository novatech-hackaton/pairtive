import { beforeEach, describe, expect, it, vi } from 'vitest';

// Recording fake for the amSupabase query builder: every chained call is logged and
// awaiting a builder resolves to the response queued for its table.
const am = vi.hoisted(() => {
  const state = { calls: [], responses: {}, rpc: [] };
  function builder(table) {
    const entry = { table, ops: [] };
    state.calls.push(entry);
    const b = {};
    for (const op of ['select', 'insert', 'update', 'upsert', 'eq', 'in', 'order', 'limit']) {
      b[op] = (...args) => {
        entry.ops.push([op, ...args]);
        return b;
      };
    }
    b.then = (resolve, reject) => {
      const queue = state.responses[table] ?? [];
      return Promise.resolve(queue.length ? queue.shift() : { data: null, error: null }).then(resolve, reject);
    };
    return b;
  }
  const client = {
    from: (table) => builder(table),
    rpc: (name, args) => {
      state.rpc.push([name, args]);
      return Promise.resolve(state.rpcResponse ?? { data: null, error: null });
    },
  };
  return { state, client, api: vi.fn() };
});

vi.mock('./amSupabase.js', async (importOriginal) => ({ ...(await importOriginal()), amSupabase: am.client }));
vi.mock('./amApi.js', () => ({ amApi: am.api }));

const {
  amFetchTopics,
  amFetchQuestions,
  amStartAttempts,
  amSaveAnswers,
  amPredictTopic,
  amCompleteAttempt,
  amUpsertMastery,
  amApplyBridge,
} = await import('./amDiagnostic.js');

const USER = { id: '11111111-1111-4111-8111-111111111111' };
const answers = [
  { question_id: 'q1', selected_answer: 'A', correct_answer: 'A', difficulty: 2, response_time: 4, sequence_index: 0, user_id: 'evil' },
  { question_id: 'q2', selected_answer: 'B', correct_answer: 'C', difficulty: 3, response_time: 0, sequence_index: 1 },
];
const prediction = { predicted_label: 'Proficient', confidence: 0.6, mastery_probability: 0.82 };
const op = (table, name) => am.state.calls.find((c) => c.table === table)?.ops.find((o) => o[0] === name);

beforeEach(() => {
  am.state.calls = [];
  am.state.responses = {};
  am.state.rpc = [];
  am.state.rpcResponse = undefined;
  am.api.mockReset();
});

describe('amDiagnostic data access', () => {
  it('amFetchTopics attaches question counts', async () => {
    am.state.responses.topics = [{ data: [{ id: 't1', topic_name: 'A' }, { id: 't2', topic_name: 'B' }], error: null }];
    am.state.responses.diagnostic_questions = [{ data: [{ topic_id: 't1' }, { topic_id: 't1' }], error: null }];
    const topics = await amFetchTopics('s1');
    expect(topics.map((t) => t.questionCount)).toEqual([2, 0]);
  });

  it('amFetchQuestions caps each topic at 20 questions and throws on error', async () => {
    const rows = Array.from({ length: 25 }, (_, i) => ({ id: 'q' + i, topic_id: 't1' }));
    am.state.responses.diagnostic_questions = [{ data: rows, error: null }, { data: null, error: { message: 'boom' } }];
    expect(await amFetchQuestions(['t1'])).toHaveLength(20);
    await expect(amFetchQuestions(['t1'])).rejects.toThrow('boom');
  });

  it('amStartAttempts inserts one attempt per topic owned by the passed user', async () => {
    am.state.responses.diagnostic_attempts = [{ data: [{ id: 'a1', topic_id: 't1' }, { id: 'a2', topic_id: 't2' }], error: null }];
    const map = await amStartAttempts(USER, { subjectId: 's1', topicIds: ['t1', 't2'] });
    expect(map).toEqual({ t1: 'a1', t2: 'a2' });
    const [, rows] = op('diagnostic_attempts', 'insert');
    expect(rows).toEqual([
      { user_id: USER.id, subject_id: 's1', topic_id: 't1' },
      { user_id: USER.id, subject_id: 's1', topic_id: 't2' },
    ]);
  });

  it('writes require a signed-in user', async () => {
    await expect(amStartAttempts(null, { subjectId: 's1', topicIds: ['t1'] })).rejects.toThrow('Not signed in.');
    await expect(amUpsertMastery({}, { topicId: 't1', answers, prediction })).rejects.toThrow('Not signed in.');
    expect(am.state.calls).toHaveLength(0);
  });

  it('amSaveAnswers upserts graded answers with the user id and ignoreDuplicates', async () => {
    await amSaveAnswers(USER, { attemptId: 'a1', topicId: 't1', answers });
    const [, rows, opts] = op('diagnostic_answers', 'upsert');
    expect(opts).toEqual({ onConflict: 'attempt_id,question_id', ignoreDuplicates: true });
    expect(rows.every((r) => r.user_id === USER.id && r.attempt_id === 'a1' && r.topic_id === 't1')).toBe(true);
    expect(rows.map((r) => r.is_correct)).toEqual([true, false]);
    expect(rows[1].response_time).toBeGreaterThan(0);
  });

  it('amPredictTopic posts the ordered response sequence to amPredict', async () => {
    am.api.mockResolvedValue(prediction);
    await expect(amPredictTopic({ topicId: 't1', answers })).resolves.toBe(prediction);
    expect(am.api).toHaveBeenCalledWith('amPredict', {
      topic_id: 't1',
      responses: [{ is_correct: true, difficulty: 2 }, { is_correct: false, difficulty: 3 }],
    });
  });

  it('amCompleteAttempt updates totals and level scoped to the user', async () => {
    await amCompleteAttempt(USER, { attemptId: 'a1', answers, prediction });
    const entry = am.state.calls.find((c) => c.table === 'diagnostic_attempts');
    const [, patch] = entry.ops.find((o) => o[0] === 'update');
    expect(patch).toMatchObject({ total_questions: 2, correct_answers: 1, accuracy: 0.5, mastery_probability: 0.82, mastery_level: 'Proficient' });
    expect(entry.ops).toContainEqual(['eq', 'id', 'a1']);
    expect(entry.ops).toContainEqual(['eq', 'user_id', USER.id]);
  });

  it('amUpsertMastery upserts on (user_id, topic_id) with the user id', async () => {
    await amUpsertMastery(USER, { topicId: 't1', answers, prediction });
    const [, row, opts] = op('student_topic_mastery', 'upsert');
    expect(opts).toEqual({ onConflict: 'user_id,topic_id' });
    expect(row).toMatchObject({
      user_id: USER.id,
      topic_id: 't1',
      mastery_level: 'Proficient',
      ml_predicted_label: 'Proficient',
      ml_confidence: 0.6,
      total_questions: 2,
      correct_answers: 1,
    });
  });

  it('amUpsertMastery surfaces database errors', async () => {
    am.state.responses.student_topic_mastery = [{ data: null, error: { message: 'denied' } }];
    await expect(amUpsertMastery(USER, { topicId: 't1', answers, prediction })).rejects.toThrow('denied');
  });

  it('amApplyBridge calls the am_apply_mastery_bridge RPC', async () => {
    am.state.rpcResponse = { data: [{ out_strong: ['Loops'], out_weak: [] }], error: null };
    await expect(amApplyBridge()).resolves.toEqual({ strong: ['Loops'], weak: [] });
    expect(am.state.rpc).toEqual([['am_apply_mastery_bridge', undefined]]);
  });
});
