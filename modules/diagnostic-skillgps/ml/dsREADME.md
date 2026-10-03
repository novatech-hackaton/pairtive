# ML — Bayesian Knowledge Tracing (BKT) mastery engine

This directory implements the Diagnostic mastery engine using **Bayesian
Knowledge Tracing** instead of a feature-vector classifier. BKT processes a
student''s answers to a topic **one at a time, in order**, and after each answer
updates the probability that the topic is mastered. That final probability is
the `mastery_probability` the rest of the system already consumes, so BKT is a
drop-in replacement for the previous classifier''s output.

> The shipped data and fitted parameters are **synthetic and test-only** — they
> do not reflect real student learning. Replace the training data with real
> diagnostic responses before drawing conclusions.

## The model

One BKT **skill per topic** (49 skills). Each skill has four parameters:

| Param | Symbol | Meaning |
|-------|--------|---------|
| `p_init`    | P(L0) | prior probability the skill is already mastered |
| `p_transit` | P(T)  | chance of moving unmastered -> mastered per answer |
| `p_slip`    | P(S)  | chance of answering wrong despite mastery |
| `p_guess`   | P(G)  | chance of answering right without mastery |

Update per answer (given prior mastery P(L) before the answer):

```
correct : posterior = P(L)(1-slip) / [ P(L)(1-slip) + (1-P(L))guess ]
wrong   : posterior = P(L)(slip)   / [ P(L)(slip)   + (1-P(L))(1-guess) ]
next prior = posterior + (1 - posterior) * transit
```

`mastery_probability` is the posterior after the final answer. Constraint:
`p_slip + p_guess < 1` (and fitters clamp slip/guess to <= 0.5) so a mastered
learner is always more likely to answer correctly than an unmastered one.

### Output contract (unchanged)

The Predictor and API return the same `Prediction_Result` as before:

```json
{ "predicted_label": "Weak|Developing|Proficient",
  "confidence": 0.0,
  "probabilities": { "Weak": 0.0, "Developing": 0.0, "Proficient": 0.0 },
  "mastery_probability": 0.0 }
```

Because BKT estimates a single mastery probability, the three-level
`probabilities` are derived deterministically from `mastery_probability` by a
triangular membership anchored on the 0.40 / 0.70 thresholds
(`probabilities_from_mastery` in `dsbkt.py`). `probabilities` sum to 1,
`predicted_label` is their argmax (ties -> lower level), and `confidence` is
their max. The authoritative stored Mastery_Level is still derived on the
frontend from `mastery_probability` via the same thresholds.

## Files

| File | Role |
|------|------|
| `dsbkt.py` | Pure BKT engine (stdlib only): params, update, sequence run, probability shaping, Prediction_Result assembly, sequence validation. Independently testable. |
| `dsbkt_fit.py` | EM parameter fitting from response sequences, per skill, with default-parameter backoff for thin skills. |
| `dsgenerate_data.py` | Generates the synthetic, test-only sequence dataset. |
| `dstrain_model.py` | Loads/cleans sequences, 80/20 split (seed 42), fits per-skill params, evaluates, saves the Model_Bundle + held-out test set. |
| `dsevaluate_model.py` | Scores the held-out set and prints metrics + a mastery-bucket confusion matrix. |
| `dspredict.py` | Predictor + CLI: run BKT on a response sequence. |
| `dsprediction_api.py` | Flask HTTP service: `GET /health`, `POST /predict`. |

## Model_Bundle (`dsmodel.pkl`, joblib)

```
{ "engine": "bkt",
  "skill_params": { "<topic_id>": {p_init,p_transit,p_slip,p_guess}, ... },
  "default_params": {p_init,p_transit,p_slip,p_guess},
  "fit_method": "em" | "defaults",
  "skills_fit_by_em": <int>, "skills_total": <int>,
  "metrics": { "accuracy": <float>, "n_obs": <int> },
  "feature_names": null }
```

## Run it

```bash
# 1. (Re)generate the synthetic sequence dataset
python ml/dsgenerate_data.py

# 2. Fit per-skill BKT params and save the bundle + held-out test set
python ml/dstrain_model.py

# 3. Evaluate on the held-out split
python ml/dsevaluate_model.py

# 4. Predict from the command line (1 = correct, 0 = wrong)
python ml/dspredict.py --responses "0,0,1,1,1,1,1,1" --topic 5
python ml/dspredict.py          # runs built-in samples

# 5. Serve predictions over HTTP (dev server)
#    reads MODEL_PATH, ALLOWED_ORIGINS, PORT from the environment / ml/.env
python ml/dsprediction_api.py
```

### Prediction_API requests

```bash
curl http://127.0.0.1:8000/health
# {"engine":"bkt","loaded":true,"skills_count":49}

curl -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d ''{"topic_id":"5","responses":[{"is_correct":false},{"is_correct":true},{"is_correct":true}]}''
# {"predicted_label":"...","confidence":...,"probabilities":{...},"mastery_probability":...}
```

Errors: `400` invalid JSON / invalid sequence (lists bad fields), `413` body
over 10 KB, `503` bundle not loaded, `500` unexpected (no stack traces). CORS is
restricted to `ALLOWED_ORIGINS` and never uses `*`. The service holds no
Supabase credentials and stores nothing.

## Parameter fitting and defaults

`dsbkt_fit.py` fits each skill by Expectation-Maximization over its response
sequences (deterministic from a fixed EM start). A skill with fewer than
`MIN_SEQUENCES_TO_FIT` (10) sequences backs off to `DEFAULT_PARAMS`
(`p_init=0.20, p_transit=0.15, p_slip=0.10, p_guess=0.20`), a documented
literature-style default. Fitted params are clamped into identifiable bounds.

## Using real data

Export per-answer rows from the Supabase `diagnostic_answers` table ordered by
`created_at` within each `(attempt_id, topic_id)`, shaped to the CSV columns in
`../data/dsREADME.md`, and point `dstrain_model.py` at them with `--data`. No
code change is needed.

## Tests

```bash
python -m pytest ml/tests/ -q
```

Covers the engine (update/monotonicity/determinism/validation), the fitter
(parameter recovery, backoff, determinism), the Predictor, and the API
(health, predict, 400/413/503, strict CORS).

## A note on the confusion matrix

In held-out evaluation, "Developing" sequences often map to Proficient because
BKT estimates mastery **after all 20 answers** — a still-learning student is
frequently near mastery by the end. The label is the generating profile, not
the end state, so bucket-vs-label disagreement there is expected. The
one-step-ahead predictive accuracy is the more meaningful BKT metric.
