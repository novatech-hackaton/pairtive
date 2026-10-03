// POST /api/amPredict { topic_id, responses: [{ is_correct, difficulty? }] } -> Prediction_Result
// Runs the Node BKT port (shared/amBkt.js) for a signed-in learner. Stores nothing.
import { amBktParamsFor, amBktPredict, amValidatePredictBody } from '../shared/amBkt.js';
import { AmHttpError, amAdmin, amDbError, amHandler, amRequireUser } from '../server/amServer.js';

export const AM_PREDICT_MAX_BYTES = 10 * 1024; // same limit as dsprediction_api.py

const AM_PREDICT_INVALID = 'Invalid response sequence.';

/**
 * Validate the body, resolve the topic with the service-role client and run BKT.
 * Returns `{ predicted_label, confidence, probabilities, mastery_probability }`.
 * Throws 400 with `fields` for invalid bodies and unknown topics.
 */
export async function amPredictTopic(admin, body) {
  const v = amValidatePredictBody(body);
  if (!v.ok) throw new AmHttpError(400, AM_PREDICT_INVALID, { fields: v.errors });

  const { data: topic, error } = await admin.from('topics').select('id, topic_name').eq('id', v.topicId).maybeSingle();
  amDbError(error);
  if (!topic) throw new AmHttpError(400, AM_PREDICT_INVALID, { fields: ['topic_id: unknown topic'] });

  return amBktPredict(v.responses, amBktParamsFor(topic.topic_name));
}

/** Build the handler; `getAdmin` is injectable so tests can pass a fake client. */
export function amCreatePredictHandler(getAdmin = amAdmin) {
  return amHandler(
    async ({ req, body }) => {
      const admin = getAdmin();
      await amRequireUser(req, admin);
      return amPredictTopic(admin, body);
    },
    { maxBodyBytes: AM_PREDICT_MAX_BYTES },
  );
}

export default amCreatePredictHandler();
