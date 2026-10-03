"""Evaluator for the BKT Model_Bundle.

Loads the saved Model_Bundle (``ml/dsmodel.pkl``) and the Held_Out_Test_Set
(``ml/dstest_sequences.csv``), scores the held-out sequences WITHOUT refitting,
and prints predictive metrics plus a 3x3 mastery-bucket confusion matrix. Exits
0 on success; exits non-zero with guidance when the bundle or test set is
missing or unreadable.

Run with::

    python ml/dsevaluate_model.py [--model PATH] [--testset PATH]

Metrics:
  * one-step-ahead predictive accuracy (does the model's P(correct) >= 0.5
    agree with the actual next answer?), to four decimal places;
  * confusion matrix of the ground-truth mastery_label (from the test CSV)
    versus the Mastery_Level the final BKT mastery probability maps to via the
    0.40 / 0.70 thresholds.

Requirements covered (BKT revision): 16.1-16.7.
"""

from __future__ import annotations

import argparse
import csv
import os
import sys
from collections import defaultdict
from typing import Sequence

import joblib

try:
    from dsbkt import (
        DEFAULT_PARAMS,
        DEVELOPING_THRESHOLD,
        LEVELS,
        PROFICIENT_THRESHOLD,
        BKTParams,
        apply_transition,
        posterior_given_answer,
        run_sequence,
    )
except ImportError:  # pragma: no cover
    from ml.dsbkt import (
        DEFAULT_PARAMS,
        DEVELOPING_THRESHOLD,
        LEVELS,
        PROFICIENT_THRESHOLD,
        BKTParams,
        apply_transition,
        posterior_given_answer,
        run_sequence,
    )


def default_model_path() -> str:
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "dsmodel.pkl")


def default_testset_path() -> str:
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "dstest_sequences.csv")


def level_of(mastery: float) -> str:
    if mastery < DEVELOPING_THRESHOLD:
        return "Weak"
    if mastery < PROFICIENT_THRESHOLD:
        return "Developing"
    return "Proficient"


def load_bundle(path: str) -> dict:
    if not os.path.isfile(path):
        raise FileNotFoundError(
            f"Model_Bundle not found at {path}. Run ml/dstrain_model.py first."
        )
    bundle = joblib.load(path)
    if not isinstance(bundle, dict) or bundle.get("engine") != "bkt":
        raise ValueError(f"{path} is not a BKT Model_Bundle.")
    return bundle


def load_testset(path: str) -> dict[tuple[str, str], dict]:
    if not os.path.isfile(path):
        raise FileNotFoundError(
            f"Held_Out_Test_Set not found at {path}. Run ml/dstrain_model.py first."
        )
    staged: dict[tuple[str, str], dict] = defaultdict(
        lambda: {"topic_id": "", "label": "", "answers": []}
    )
    with open(path, "r", newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            student = (row.get("student_id") or "").strip()
            topic = (row.get("topic_id") or "").strip()
            try:
                idx = int(float(row.get("sequence_index")))
                correct = int(float(row.get("is_correct")))
            except (TypeError, ValueError):
                continue
            key = (student, topic)
            staged[key]["topic_id"] = topic
            staged[key]["label"] = (row.get("mastery_label") or "").strip()
            staged[key]["answers"].append((idx, correct))
    for data in staged.values():
        data["answers"].sort(key=lambda p: p[0])
    return dict(staged)


def params_for(bundle: dict, topic_id: str) -> BKTParams:
    skill_params = bundle.get("skill_params", {})
    if topic_id in skill_params:
        return BKTParams.from_mapping(skill_params[topic_id])
    return BKTParams.from_mapping(bundle.get("default_params", DEFAULT_PARAMS.as_dict()))


def evaluate(bundle: dict, testset: dict[tuple[str, str], dict]) -> dict:
    correct = 0
    total = 0
    # Confusion matrix indexed [true_level][pred_level].
    matrix = {t: {p: 0 for p in LEVELS} for t in LEVELS}
    for key, data in testset.items():
        params = params_for(bundle, data["topic_id"])
        seq = [c for _, c in data["answers"]]
        if not seq:
            continue
        prior = params.p_init
        for obs in seq:
            p_correct = prior * (1 - params.p_slip) + (1 - prior) * params.p_guess
            predicted = 1 if p_correct >= 0.5 else 0
            correct += int(predicted == obs)
            total += 1
            post = posterior_given_answer(prior, bool(obs), params)
            prior = apply_transition(post, params)
        final_mastery = run_sequence(seq, params)
        pred_level = level_of(final_mastery)
        true_level = data["label"] if data["label"] in LEVELS else None
        if true_level is not None:
            matrix[true_level][pred_level] += 1
    return {
        "accuracy": (correct / total) if total else float("nan"),
        "n_obs": total,
        "n_sequences": len(testset),
        "matrix": matrix,
    }


def print_report(metrics: dict) -> None:
    print("BKT held-out evaluation")
    print(f"  Sequences evaluated:       {metrics['n_sequences']}")
    print(f"  One-step predictive acc:   {metrics['accuracy']:.4f}")
    print(f"  Observations:              {metrics['n_obs']}")
    print()
    print("  Confusion matrix (rows = true label, cols = predicted level):")
    header = "    {:<12}".format("") + "".join(f"{l:>12}" for l in LEVELS)
    print(header)
    for true_level in LEVELS:
        row = metrics["matrix"][true_level]
        line = "    {:<12}".format(true_level) + "".join(f"{row[p]:>12}" for p in LEVELS)
        print(line)


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Evaluate the BKT Model_Bundle.")
    parser.add_argument("--model", default=None)
    parser.add_argument("--testset", default=None)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    model_path = args.model or default_model_path()
    testset_path = args.testset or default_testset_path()
    try:
        bundle = load_bundle(model_path)
        testset = load_testset(testset_path)
    except (FileNotFoundError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    metrics = evaluate(bundle, testset)
    print_report(metrics)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
