"""Predictor and command-line prediction for the BKT engine.

``predict(responses, topic_id, bundle)`` validates an ordered response sequence,
runs BKT with the bundle's per-skill parameters (falling back to the bundle's
default parameters for an unknown topic), and returns a Prediction_Result:

    { predicted_label, confidence, probabilities{Weak,Developing,Proficient},
      mastery_probability }

The CLI maps ``--responses`` (a comma/space list of 1/0 or true/false) and an
optional ``--topic`` to a prediction and prints a human-readable line. With no
arguments it runs several built-in sample sequences so the engine can be
demonstrated on its own.

Requirements covered (BKT revision): 17.1-17.13.
"""

from __future__ import annotations

import argparse
import os
import sys
from typing import Any, Sequence

import joblib

try:
    from dsbkt import DEFAULT_PARAMS, BKTError, BKTParams, predict_sequence
except ImportError:  # pragma: no cover
    from ml.dsbkt import DEFAULT_PARAMS, BKTError, BKTParams, predict_sequence


class PredictorError(RuntimeError):
    """Raised when the Model_Bundle is missing or cannot be loaded."""


def default_model_path() -> str:
    return os.environ.get(
        "MODEL_PATH",
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "dsmodel.pkl"),
    )


def load_bundle(path: str | None = None) -> dict:
    path = path or default_model_path()
    if not os.path.isfile(path):
        raise PredictorError(
            f"Model_Bundle is unavailable at {path}. Run ml/dstrain_model.py first."
        )
    try:
        bundle = joblib.load(path)
    except Exception as exc:  # noqa: BLE001 - surface a clean message
        raise PredictorError(f"Model_Bundle at {path} could not be loaded: {exc}") from exc
    if not isinstance(bundle, dict) or bundle.get("engine") != "bkt":
        raise PredictorError(f"{path} is not a BKT Model_Bundle.")
    return bundle


def params_for(bundle: dict, topic_id: Any) -> BKTParams:
    """Return the BKT params for a topic, defaulting when unknown."""
    skill_params = bundle.get("skill_params", {})
    key = None if topic_id is None else str(topic_id)
    if key is not None and key in skill_params:
        return BKTParams.from_mapping(skill_params[key])
    return BKTParams.from_mapping(bundle.get("default_params", DEFAULT_PARAMS.as_dict()))


def predict(responses: Any, topic_id: Any, bundle: dict) -> dict[str, Any]:
    """Validate a response sequence and return a Prediction_Result.

    Raises ``BKTError`` on an invalid sequence (reporting every invalid field).
    """
    params = params_for(bundle, topic_id)
    return predict_sequence(responses, params)


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #

def _parse_responses(text: str) -> list[int]:
    tokens = [t for t in text.replace(",", " ").split() if t]
    out: list[int] = []
    for tok in tokens:
        low = tok.strip().lower()
        if low in ("1", "t", "true", "y", "yes", "c", "correct"):
            out.append(1)
        elif low in ("0", "f", "false", "n", "no", "w", "wrong", "incorrect"):
            out.append(0)
        else:
            raise ValueError(f"unrecognized response token: {tok!r}")
    return out


def _format(result: dict[str, Any]) -> str:
    pct = round(result["confidence"] * 100)
    mp = round(result["mastery_probability"] * 100)
    return (
        f"Predicted Mastery: {result['predicted_label']}, "
        f"Confidence: {pct}% (mastery probability {mp}%)"
    )


SAMPLES = [
    ("mostly wrong", [0, 0, 0, 1, 0, 0, 1, 0, 0, 0]),
    ("improving", [0, 0, 1, 0, 1, 1, 1, 1, 1, 1]),
    ("mostly correct", [1, 1, 1, 0, 1, 1, 1, 1, 1, 1]),
]


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a BKT prediction from a response sequence.")
    parser.add_argument("--responses", default=None, help="e.g. '1,0,1,1,0' (1/0 or true/false)")
    parser.add_argument("--topic", default=None, help="topic/skill id (optional)")
    parser.add_argument("--model", default=None, help="path to the Model_Bundle")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        bundle = load_bundle(args.model)
    except PredictorError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    if args.responses:
        try:
            responses = _parse_responses(args.responses)
            result = predict(responses, args.topic, bundle)
        except (ValueError, BKTError) as exc:
            print(f"Error: {exc}", file=sys.stderr)
            return 1
        print(_format(result))
        return 0

    # No responses: run the built-in samples.
    print("No --responses given; running built-in samples:\n")
    for name, seq in SAMPLES:
        result = predict(seq, args.topic, bundle)
        print(f"  [{name}] {''.join(str(c) for c in seq)}")
        print(f"      {_format(result)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
