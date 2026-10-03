"""BKT Training_Pipeline for the diagnostic SkillGPS system.

Loads ordered response sequences from the Training_Dataset CSV, validates and
cleans them, splits by sequence (80/20, seed 42), fits per-skill BKT parameters
by EM (backing off to documented defaults for thin skills), evaluates on the
held-out split, and saves a BKT Model_Bundle to ``ml/dsmodel.pkl`` (joblib)
alongside the held-out test CSV. Prints fit metrics to four decimal places and
exits 0 on success.

Run it with::

    python ml/dstrain_model.py [--data PATH]

The dataset is read from ``--data`` or ``data/dstraining_data.csv``. The CSV has
one row per answer with columns (any order; extra columns ignored):

    student_id, topic_id, sequence_index, is_correct, difficulty, mastery_label

Rows for one (student_id, topic_id) in ascending sequence_index form one ordered
observation stream for that skill (topic). Each topic is one BKT skill.

Cleaning (counts reported): drop rows whose is_correct is not 0/1, whose
sequence_index is not a non-negative integer, or that duplicate an earlier row
on (student_id, topic_id, sequence_index). Sequences with no valid rows are
dropped. The pipeline exits non-zero (leaving any existing bundle/test set
unchanged) when the file is missing/unreadable, required columns are missing,
or fewer than the minimum sequences/skills remain.

Requirements covered (BKT revision): 15.1-15.14.
"""

from __future__ import annotations

import argparse
import csv
import os
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Sequence

import joblib

try:  # support "run from ml/" and "import as ml.dstrain_model"
    from dsbkt import DEFAULT_PARAMS, BKTParams
    from dsbkt_fit import SkillFit, fit_all_skills
except ImportError:  # pragma: no cover
    from ml.dsbkt import DEFAULT_PARAMS, BKTParams
    from ml.dsbkt_fit import SkillFit, fit_all_skills

REQUIRED_COLUMNS: tuple[str, ...] = (
    "student_id",
    "topic_id",
    "sequence_index",
    "is_correct",
)
VALID_LABELS: tuple[str, ...] = ("Weak", "Developing", "Proficient")

MIN_SEQUENCES = 20
MIN_SKILLS = 1
TRAIN_FRACTION = 0.8
SPLIT_SEED = 42

DEFAULT_MODEL_PATH_NAME = "dsmodel.pkl"
DEFAULT_TESTSET_NAME = "dstest_sequences.csv"


class TrainingDataError(Exception):
    """Fatal data problem; the pipeline prints it and exits non-zero."""


@dataclass
class LoadResult:
    """Grouped, cleaned sequences keyed by (student_id, topic_id)."""

    # key -> {"topic_id": str, "label": str, "answers": [(index, is_correct)]}
    sequences: dict[tuple[str, str], dict] = field(default_factory=dict)
    bad_value_dropped: int = 0
    duplicate_dropped: int = 0

    @property
    def n_sequences(self) -> int:
        return len(self.sequences)

    @property
    def skills(self) -> set[str]:
        return {s["topic_id"] for s in self.sequences.values()}


def default_data_path() -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(os.path.dirname(here), "data", "dstraining_data.csv")


def default_model_path() -> str:
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), DEFAULT_MODEL_PATH_NAME)


def default_testset_path() -> str:
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), DEFAULT_TESTSET_NAME)


def load_rows(path: str) -> tuple[list[str], list[dict[str, str]]]:
    if not os.path.isfile(path):
        raise TrainingDataError(
            f"No Training_Dataset file was found at: {path}. "
            "Provide a CSV with --data or run ml/dsgenerate_data.py."
        )
    try:
        with open(path, "r", newline="", encoding="utf-8-sig") as handle:
            reader = csv.DictReader(handle)
            fieldnames = list(reader.fieldnames or [])
            rows = [dict(r) for r in reader]
    except (OSError, csv.Error, UnicodeDecodeError) as exc:
        raise TrainingDataError(
            f"The Training_Dataset at {path} could not be read as CSV: {exc}"
        ) from exc
    if not fieldnames:
        raise TrainingDataError(
            f"The Training_Dataset at {path} has no header row."
        )
    return fieldnames, rows


def validate_columns(fieldnames: Sequence[str]) -> None:
    present = {name.strip() for name in fieldnames if name is not None}
    missing = [c for c in REQUIRED_COLUMNS if c not in present]
    if missing:
        raise TrainingDataError(
            "The Training_Dataset is missing required column(s): " + ", ".join(missing)
        )


def _parse_int(value) -> int | None:
    try:
        text = str(value).strip()
        number = float(text)
    except (ValueError, TypeError):
        return None
    if number != int(number):
        return None
    return int(number)


def clean_and_group(rows: Sequence[dict[str, str]]) -> LoadResult:
    """Validate rows, group them into ordered per-(student,topic) sequences."""
    result = LoadResult()
    seen: set[tuple[str, str, int]] = set()
    staged: dict[tuple[str, str], dict] = defaultdict(
        lambda: {"topic_id": "", "label": "", "answers": []}
    )

    for row in rows:
        student = (row.get("student_id") or "").strip()
        topic = (row.get("topic_id") or "").strip()
        idx = _parse_int(row.get("sequence_index"))
        correct = _parse_int(row.get("is_correct"))
        label = (row.get("mastery_label") or "").strip()

        if not student or not topic or idx is None or idx < 0 or correct not in (0, 1):
            result.bad_value_dropped += 1
            continue

        key = (student, topic, idx)
        if key in seen:
            result.duplicate_dropped += 1
            continue
        seen.add(key)

        skey = (student, topic)
        staged[skey]["topic_id"] = topic
        if label in VALID_LABELS:
            staged[skey]["label"] = label
        staged[skey]["answers"].append((idx, correct))

    # Order each sequence by sequence_index and keep non-empty ones.
    for skey, data in staged.items():
        if not data["answers"]:
            continue
        data["answers"].sort(key=lambda pair: pair[0])
        result.sequences[skey] = data
    return result


def check_minimums(result: LoadResult) -> None:
    if result.n_sequences < MIN_SEQUENCES or len(result.skills) < MIN_SKILLS:
        raise TrainingDataError(
            "Not enough usable training data after cleaning: "
            f"{result.n_sequences} sequence(s) across {len(result.skills)} skill(s). "
            f"At least {MIN_SEQUENCES} sequences and {MIN_SKILLS} skill(s) required."
        )


def split_sequences(result: LoadResult) -> tuple[list[tuple], list[tuple]]:
    """Deterministic 80/20 split of sequence keys (seed 42)."""
    import random

    keys = sorted(result.sequences.keys())
    rng = random.Random(SPLIT_SEED)
    rng.shuffle(keys)
    cut = int(round(len(keys) * TRAIN_FRACTION))
    # Guarantee at least one sequence in each split.
    cut = max(1, min(cut, len(keys) - 1)) if len(keys) >= 2 else len(keys)
    return keys[:cut], keys[cut:]


def sequences_by_skill(result: LoadResult, keys: Sequence[tuple]) -> dict[str, list[list[int]]]:
    grouped: dict[str, list[list[int]]] = defaultdict(list)
    for key in keys:
        data = result.sequences[key]
        grouped[data["topic_id"]].append([c for _, c in data["answers"]])
    return dict(grouped)


def evaluate(fits: dict[str, SkillFit], test_by_skill: dict[str, list[list[int]]]) -> dict:
    """One-step-ahead accuracy and bucket agreement on the held-out split."""
    try:
        from dsbkt import apply_transition, posterior_given_answer, run_sequence
        from dsbkt import DEVELOPING_THRESHOLD, PROFICIENT_THRESHOLD
    except ImportError:  # pragma: no cover
        from ml.dsbkt import apply_transition, posterior_given_answer, run_sequence
        from ml.dsbkt import DEVELOPING_THRESHOLD, PROFICIENT_THRESHOLD

    correct = 0
    total = 0
    for skill, seqs in test_by_skill.items():
        params = fits[skill].params if skill in fits else DEFAULT_PARAMS
        for seq in seqs:
            prior = params.p_init
            for obs in seq:
                p_correct = prior * (1 - params.p_slip) + (1 - prior) * params.p_guess
                predicted = 1 if p_correct >= 0.5 else 0
                correct += int(predicted == obs)
                total += 1
                post = posterior_given_answer(prior, bool(obs), params)
                prior = apply_transition(post, params)
    return {"accuracy": (correct / total) if total else float("nan"), "n_obs": total}


def build_bundle(fits: dict[str, SkillFit], metrics: dict) -> dict:
    em_skills = sum(1 for f in fits.values() if f.method == "em")
    return {
        "engine": "bkt",
        "skill_params": {sid: f.params.as_dict() for sid, f in fits.items()},
        "default_params": DEFAULT_PARAMS.as_dict(),
        "fit_method": "em" if em_skills else "defaults",
        "skills_fit_by_em": em_skills,
        "skills_total": len(fits),
        "metrics": metrics,
        "feature_names": None,
    }


def write_test_set(path: str, result: LoadResult, test_keys: Sequence[tuple]) -> None:
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["student_id", "topic_id", "sequence_index", "is_correct", "mastery_label"])
        for key in test_keys:
            data = result.sequences[key]
            student, _ = key
            for idx, correct in data["answers"]:
                writer.writerow([student, data["topic_id"], idx, correct, data["label"]])


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fit and save a BKT Model_Bundle.")
    parser.add_argument("--data", default=None)
    parser.add_argument("--model-out", default=None)
    parser.add_argument("--testset-out", default=None)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    data_path = args.data or default_data_path()
    model_path = args.model_out or default_model_path()
    testset_path = args.testset_out or default_testset_path()

    try:
        fieldnames, rows = load_rows(data_path)
        validate_columns(fieldnames)
        result = clean_and_group(rows)
        print("Cleaning summary:")
        print(f"  Dropped (bad value row):   {result.bad_value_dropped}")
        print(f"  Dropped (duplicate row):   {result.duplicate_dropped}")
        print(f"  Sequences:                 {result.n_sequences}")
        print(f"  Skills (topics):           {len(result.skills)}")
        check_minimums(result)
    except TrainingDataError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    train_keys, test_keys = split_sequences(result)
    train_by_skill = sequences_by_skill(result, train_keys)
    test_by_skill = sequences_by_skill(result, test_keys)

    # Fit on the training split only (no leakage).
    fits = fit_all_skills(train_by_skill, DEFAULT_PARAMS)
    metrics = evaluate(fits, test_by_skill)
    bundle = build_bundle(fits, metrics)

    # Persist (bundle first, then test set). Both written only after a clean fit.
    joblib.dump(bundle, model_path)
    write_test_set(testset_path, result, test_keys)

    print("Training complete.")
    print(f"  Skills fit by EM:          {bundle['skills_fit_by_em']} / {bundle['skills_total']}")
    print(f"  Held-out accuracy:         {metrics['accuracy']:.4f}")
    print(f"  Held-out observations:     {metrics['n_obs']}")
    print(f"  Model_Bundle saved to:     {model_path}")
    print(f"  Held_Out_Test_Set saved:   {testset_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
