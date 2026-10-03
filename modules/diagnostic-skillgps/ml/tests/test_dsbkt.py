"""Tests for the pure BKT core engine (ml/dsbkt.py)."""

from __future__ import annotations

import math
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from ml.dsbkt import (  # noqa: E402
    DEFAULT_PARAMS,
    LEVELS,
    BKTError,
    BKTParams,
    apply_transition,
    build_prediction_result,
    mastery_trajectory,
    posterior_given_answer,
    predict_sequence,
    probabilities_from_mastery,
    run_sequence,
    validate_response_sequence,
)


def test_params_reject_out_of_range():
    with pytest.raises(BKTError):
        BKTParams(p_init=-0.1, p_transit=0.1, p_slip=0.1, p_guess=0.1)
    with pytest.raises(BKTError):
        BKTParams(p_init=0.1, p_transit=1.2, p_slip=0.1, p_guess=0.1)


def test_params_reject_slip_plus_guess_ge_one():
    with pytest.raises(BKTError) as exc:
        BKTParams(p_init=0.2, p_transit=0.1, p_slip=0.6, p_guess=0.6)
    assert any("p_slip + p_guess" in e for e in exc.value.errors)


def test_params_reject_nonfinite():
    with pytest.raises(BKTError):
        BKTParams(p_init=float("nan"), p_transit=0.1, p_slip=0.1, p_guess=0.1)


def test_from_mapping_reports_missing():
    with pytest.raises(BKTError) as exc:
        BKTParams.from_mapping({"p_init": 0.2, "p_transit": 0.1})
    assert any("p_slip" in e for e in exc.value.errors)


def test_posterior_in_unit_interval():
    params = DEFAULT_PARAMS
    for prior in (0.0, 0.3, 0.5, 0.9, 1.0):
        for correct in (True, False):
            post = posterior_given_answer(prior, correct, params)
            assert 0.0 <= post <= 1.0


def test_correct_answer_raises_mastery_estimate():
    # A correct answer should never lower the posterior relative to the prior
    # (for sane params where mastered learners answer correctly more often).
    params = BKTParams(p_init=0.3, p_transit=0.0, p_slip=0.1, p_guess=0.2)
    prior = params.p_init
    post_correct = posterior_given_answer(prior, True, params)
    post_wrong = posterior_given_answer(prior, False, params)
    assert post_correct >= prior
    assert post_wrong <= prior


def test_run_sequence_monotonic_in_correctness():
    # More correct answers -> higher final mastery.
    params = DEFAULT_PARAMS
    all_wrong = run_sequence([False] * 10, params)
    mixed = run_sequence([True, False] * 5, params)
    all_right = run_sequence([True] * 10, params)
    assert all_wrong <= mixed <= all_right
    assert 0.0 <= all_wrong <= 1.0
    assert 0.0 <= all_right <= 1.0


def test_run_sequence_empty_returns_prior():
    params = DEFAULT_PARAMS
    assert run_sequence([], params) == pytest.approx(params.p_init)


def test_run_sequence_deterministic():
    params = DEFAULT_PARAMS
    seq = [True, False, True, True, False, True]
    assert run_sequence(seq, params) == run_sequence(seq, params)


def test_run_sequence_order_sensitive():
    # BKT is sequential: a late streak of correct answers vs an early one can
    # differ because of the learning transition.
    params = BKTParams(p_init=0.1, p_transit=0.4, p_slip=0.1, p_guess=0.2)
    front = run_sequence([True, True, True, False, False, False], params)
    back = run_sequence([False, False, False, True, True, True], params)
    assert front != back


def test_trajectory_length_matches():
    params = DEFAULT_PARAMS
    seq = [True, False, True]
    traj = mastery_trajectory(seq, params)
    assert len(traj) == len(seq)
    assert all(0.0 <= p <= 1.0 for p in traj)


def test_probabilities_sum_to_one():
    for p in (0.0, 0.1, 0.4, 0.55, 0.7, 0.9, 1.0):
        probs = probabilities_from_mastery(p)
        assert set(probs) == set(LEVELS)
        assert math.isclose(sum(probs.values()), 1.0, abs_tol=1e-9)
        assert all(v >= 0.0 for v in probs.values())


def test_prediction_result_contract():
    result = build_prediction_result(0.85)
    assert set(result) == {
        "predicted_label",
        "confidence",
        "probabilities",
        "mastery_probability",
    }
    assert result["mastery_probability"] == pytest.approx(0.85)
    assert math.isclose(sum(result["probabilities"].values()), 1.0, abs_tol=1e-9)
    assert result["predicted_label"] in LEVELS
    assert result["confidence"] == pytest.approx(max(result["probabilities"].values()))


def test_prediction_result_argmax_extremes():
    assert build_prediction_result(0.98)["predicted_label"] == "Proficient"
    assert build_prediction_result(0.02)["predicted_label"] == "Weak"


def test_validate_sequence_accepts_forms():
    assert validate_response_sequence([True, False, 1, 0]) == [True, False, True, False]
    assert validate_response_sequence(
        [{"is_correct": True, "difficulty": 2}, {"isCorrect": False}]
    ) == [True, False]


def test_validate_sequence_rejects_empty_and_long():
    with pytest.raises(BKTError):
        validate_response_sequence([])
    with pytest.raises(BKTError):
        validate_response_sequence([True] * 21)


def test_validate_sequence_rejects_bad_difficulty_and_missing():
    with pytest.raises(BKTError) as exc:
        validate_response_sequence([{"is_correct": True, "difficulty": 5}])
    assert any("difficulty" in e for e in exc.value.errors)
    with pytest.raises(BKTError) as exc2:
        validate_response_sequence([{"foo": 1}])
    assert any("is_correct" in e for e in exc2.value.errors)


def test_validate_sequence_rejects_string():
    with pytest.raises(BKTError):
        validate_response_sequence("1010")


def test_predict_sequence_end_to_end():
    result = predict_sequence([True, True, True, True], DEFAULT_PARAMS)
    assert 0.0 <= result["mastery_probability"] <= 1.0
    assert result["predicted_label"] in LEVELS


def test_apply_transition_increases_or_equal():
    params = DEFAULT_PARAMS
    for post in (0.0, 0.3, 0.8, 1.0):
        assert apply_transition(post, params) >= post
