"""Tests for the BKT Predictor (ml/dspredict.py)."""

from __future__ import annotations

import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dsbkt import DEFAULT_PARAMS, BKTError, LEVELS  # noqa: E402
import dspredict  # noqa: E402


def _bundle():
    return {
        "engine": "bkt",
        "skill_params": {"5": {"p_init": 0.3, "p_transit": 0.2, "p_slip": 0.1, "p_guess": 0.2}},
        "default_params": DEFAULT_PARAMS.as_dict(),
    }


def test_predict_known_topic_uses_skill_params():
    result = dspredict.predict([1, 1, 1, 1], "5", _bundle())
    assert set(result) == {"predicted_label", "confidence", "probabilities", "mastery_probability"}
    assert 0.0 <= result["mastery_probability"] <= 1.0
    assert result["predicted_label"] in LEVELS


def test_predict_unknown_topic_falls_back_to_default():
    r1 = dspredict.predict([1, 0, 1], "999", _bundle())
    assert 0.0 <= r1["mastery_probability"] <= 1.0


def test_predict_rejects_invalid_sequence():
    with pytest.raises(BKTError):
        dspredict.predict([], "5", _bundle())
    with pytest.raises(BKTError):
        dspredict.predict([1] * 21, "5", _bundle())


def test_predict_deterministic():
    seq = [1, 0, 1, 1, 0]
    assert dspredict.predict(seq, "5", _bundle()) == dspredict.predict(seq, "5", _bundle())


def test_probabilities_sum_to_one():
    result = dspredict.predict([1, 0, 1], "5", _bundle())
    assert abs(sum(result["probabilities"].values()) - 1.0) < 1e-9


def test_load_bundle_missing_raises():
    with pytest.raises(dspredict.PredictorError):
        dspredict.load_bundle(os.path.join(os.path.dirname(__file__), "nope_missing.pkl"))


def test_parse_responses_tokens():
    assert dspredict._parse_responses("1,0 true false yes no") == [1, 0, 1, 0, 1, 0]
    with pytest.raises(ValueError):
        dspredict._parse_responses("maybe")
