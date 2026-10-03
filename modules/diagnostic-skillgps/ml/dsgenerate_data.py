"""Synthetic BKT training-data generator for the Diagnostic/SkillGPS pipeline.

TEST-ONLY DATA. This script produces ``data/dstraining_data.csv``, an
artificially generated placeholder dataset of ordered per-response sequences.
The data does NOT reflect real student learning, and BKT parameters fit to it
do not reflect real-world mastery. Replace this file with real diagnostic
response data (exported from the Supabase ``diagnostic_answers`` table, ordered
by ``created_at`` within each attempt/topic) before drawing any conclusions.

Why sequences instead of aggregated rows: Bayesian Knowledge Tracing consumes
an ORDERED stream of correct/incorrect answers per skill and updates a mastery
probability after each one. The previous aggregated schema (one row per attempt
with accuracy/counts) carried no ordering, so it is replaced here.

CSV schema (UTF-8, one header row), one row PER ANSWER:

    student_id, topic_id, sequence_index, is_correct, difficulty, mastery_label

  * student_id      synthetic learner id (unique per simulated sequence)
  * topic_id        the skill id (1..NUM_TOPICS); each topic is one BKT skill
  * sequence_index  0-based position of the answer within the student's topic
                    sequence; rows for one (student_id, topic_id) in ascending
                    sequence_index form the ordered observation stream
  * is_correct      1 if the answer was correct, else 0
  * difficulty      question difficulty 1..3 (carried for future difficulty-
                    aware models; v1 BKT uses correctness only)
  * mastery_label   the ground-truth label the sequence was simulated under
                    (Weak/Developing/Proficient) -- used for bucket evaluation,
                    not required by BKT fitting

Each sequence is simulated from a per-label BKT parameter profile so a fitter
can be checked against the known generating parameters. The generator is
deterministic (fixed seed) so re-running reproduces the same file.
"""

from __future__ import annotations

import argparse
import csv
import os
import random
from dataclasses import dataclass

# Column order is fixed; keep in sync with the training pipeline and docs.
HEADER = [
    "student_id",
    "topic_id",
    "sequence_index",
    "is_correct",
    "difficulty",
    "mastery_label",
]

SEED = 42
QUESTIONS_PER_SEQUENCE = 20  # answers per topic sitting (matches the diagnostic)
NUM_TOPICS = 49  # 7 subjects x 7 topics in the seed data
SEQUENCES_PER_LABEL = 1200  # ~24 sequences per skill after spreading over 49 topics


@dataclass(frozen=True)
class LabelProfile:
    """Generating BKT parameters for one ground-truth mastery label.

    The profiles are ordered so that simulated Weak sequences answer correctly
    least often and Proficient most often, which keeps mean accuracy ordered
    Weak < Developing < Proficient (a sanity check preserved from the old
    generator).
    """

    label: str
    p_init: float
    p_transit: float
    p_slip: float
    p_guess: float


# Non-overlapping learning dynamics per label. Proficient learners start closer
# to mastery and learn fast with low slip; Weak learners rarely master.
PROFILES = [
    LabelProfile("Weak", p_init=0.05, p_transit=0.03, p_slip=0.20, p_guess=0.20),
    LabelProfile("Developing", p_init=0.20, p_transit=0.12, p_slip=0.15, p_guess=0.22),
    LabelProfile("Proficient", p_init=0.55, p_transit=0.30, p_slip=0.08, p_guess=0.25),
]


def simulate_sequence(profile: LabelProfile, rng: random.Random) -> list[int]:
    """Simulate one ordered correct/incorrect sequence from a BKT profile.

    Walks the hidden mastery state forward: at each step the learner answers
    correctly with P(correct) depending on whether the skill is currently
    mastered (1 - slip) or not (guess), then may transition to mastered.
    Returns a list of 0/1 ints of length ``QUESTIONS_PER_SEQUENCE``.
    """
    mastered = rng.random() < profile.p_init
    answers: list[int] = []
    for _ in range(QUESTIONS_PER_SEQUENCE):
        if mastered:
            correct = rng.random() >= profile.p_slip
        else:
            correct = rng.random() < profile.p_guess
        answers.append(1 if correct else 0)
        if not mastered and rng.random() < profile.p_transit:
            mastered = True
    return answers


def generate_rows(rng: random.Random) -> list[list]:
    """Build all CSV data rows (without the header), one row per answer."""
    rows: list[list] = []
    student_counter = 0
    for profile in PROFILES:
        for _ in range(SEQUENCES_PER_LABEL):
            student_counter += 1
            student_id = f"stu_{student_counter:05d}"
            topic_id = rng.randint(1, NUM_TOPICS)
            answers = simulate_sequence(profile, rng)
            for index, is_correct in enumerate(answers):
                difficulty = rng.randint(1, 3)
                rows.append(
                    [
                        student_id,
                        topic_id,
                        index,
                        is_correct,
                        difficulty,
                        profile.label,
                    ]
                )
    return rows


def write_csv(path: str, rows: list[list]) -> None:
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(HEADER)
        writer.writerows(rows)


def default_output_path() -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(here)
    return os.path.join(project_root, "data", "dstraining_data.csv")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate the synthetic, test-only BKT training dataset."
    )
    parser.add_argument("--out", default=default_output_path())
    parser.add_argument("--seed", type=int, default=SEED)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    rows = generate_rows(rng)
    write_csv(args.out, rows)

    # Report per-label mean accuracy as a sanity check (ordered ascending).
    by_label: dict[str, list[int]] = {}
    for row in rows:
        by_label.setdefault(row[5], []).append(row[3])
    print(f"Wrote {len(rows)} answer rows to {args.out}")
    for label in ("Weak", "Developing", "Proficient"):
        vals = by_label.get(label, [])
        mean = sum(vals) / len(vals) if vals else 0.0
        n_seq = len(vals) // QUESTIONS_PER_SEQUENCE
        print(f"  {label}: {n_seq} sequences, mean accuracy {mean:.4f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
