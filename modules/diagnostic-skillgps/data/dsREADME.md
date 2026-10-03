# data/ — training data for the BKT mastery engine

## `dstraining_data.csv` (synthetic, test-only)

**This dataset is artificially generated and does not reflect real student
learning.** A model fit to it does not reflect real-world mastery. Replace it
with real diagnostic responses before drawing any conclusions.

Bayesian Knowledge Tracing consumes an **ordered sequence** of correct/incorrect
answers per skill, so this file stores **one row per answer** (not one row per
attempt). Rows for one `(student_id, topic_id)` in ascending `sequence_index`
form that student''s ordered observation stream for that topic. Each topic is one
BKT skill.

### Columns (UTF-8, one header row)

| Column | Meaning |
|--------|---------|
| `student_id` | synthetic learner id, unique per simulated sequence |
| `topic_id` | the skill id (1..49); each topic is one BKT skill |
| `sequence_index` | 0-based position of the answer within the student''s topic sequence |
| `is_correct` | `1` if the answer was correct, else `0` |
| `difficulty` | question difficulty `1..3` (carried for future difficulty-aware models; v1 BKT uses correctness only) |
| `mastery_label` | ground-truth label the sequence was simulated under (`Weak`/`Developing`/`Proficient`); used for bucket evaluation, not required by BKT fitting |

Required by the training pipeline: `student_id`, `topic_id`, `sequence_index`,
`is_correct`. Extra columns are ignored; `mastery_label` is used only for the
evaluation confusion matrix.

### Regenerate

```bash
python ml/dsgenerate_data.py            # deterministic (seed 42)
```

The generator simulates each sequence from a per-label BKT profile so a fitter
can be checked against the known generating parameters. Mean accuracy is ordered
Weak < Developing < Proficient as a sanity check.

### Replacing with real data

Export from the Supabase `diagnostic_answers` table, ordered by `created_at`
within each `(attempt_id, topic_id)`:

- `student_id`      <- `user_id`
- `topic_id`        <- `topic_id`
- `sequence_index`  <- rank of `created_at` within the attempt/topic (0-based)
- `is_correct`      <- `is_correct` (1/0)
- `difficulty`      <- joined from `diagnostic_questions.difficulty`
- `mastery_label`   <- optional; omit if unknown

Point the pipeline at it: `python ml/dstrain_model.py --data path/to/real.csv`.
