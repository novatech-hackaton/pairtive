"""Tests for the BKT parameter fitter (ml/dsbkt_fit.py)."""

from __future__ import annotations

import os
import random
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dsbkt import DEFAULT_PARAMS, BKTParams  # noqa: E402
from dsbkt_fit import MIN_SEQUENCES_TO_FIT, fit_all_skills, fit_skill  # noqa: E402


def _simulate(params: BKTParams, n_seq: int, length: int, rng: random.Random):
    seqs = []
    for _ in range(n_seq):
        mastered = rng.random() < params.p_init
        row = []
        for _ in range(length):
            if mastered:
                correct = rng.random() >= params.p_slip
            else:
                correct = rng.random() < params.p_guess
            row.append(1 if correct else 0)
            if not mastered and rng.random() < params.p_transit:
                mastered = True
        seqs.append(row)
    return seqs


def test_backoff_to_defaults_when_too_few():
    fit = fit_skill([[1, 0, 1]] * (MIN_SEQUENCES_TO_FIT - 1))
    assert fit.method == "defaults"
    assert fit.params == DEFAULT_PARAMS


def test_em_recovers_known_params_roughly():
    rng = random.Random(7)
    true = BKTParams(p_init=0.25, p_transit=0.20, p_slip=0.10, p_guess=0.20)
    seqs = _simulate(true, n_seq=400, length=20, rng=rng)
    fit = fit_skill(seqs)
    assert fit.method == "em"
    # EM on synthetic data should land near the generating params.
    assert abs(fit.params.p_slip - true.p_slip) < 0.08
    assert abs(fit.params.p_guess - true.p_guess) < 0.08
    assert abs(fit.params.p_transit - true.p_transit) < 0.12
    # Predictive accuracy should be clearly better than chance.
    assert fit.predictive_accuracy > 0.6


def test_fit_is_deterministic():
    rng1 = random.Random(1)
    seqs = _simulate(DEFAULT_PARAMS, n_seq=50, length=20, rng=rng1)
    f1 = fit_skill(seqs)
    f2 = fit_skill(seqs)
    assert f1.params.as_dict() == f2.params.as_dict()


def test_fitted_params_are_valid():
    rng = random.Random(3)
    seqs = _simulate(DEFAULT_PARAMS, n_seq=60, length=20, rng=rng)
    fit = fit_skill(seqs)
    # Constructing a BKTParams validates ranges and slip+guess<1; fit.params is
    # already a BKTParams, so just assert the identifiability bound holds.
    assert fit.params.p_slip + fit.params.p_guess < 1.0
    assert 0.0 <= fit.params.p_init <= 1.0


def test_fit_all_skills_groups():
    rng = random.Random(5)
    data = {
        "10": _simulate(DEFAULT_PARAMS, 30, 20, rng),
        "11": _simulate(DEFAULT_PARAMS, 3, 20, rng),  # too few -> defaults
    }
    fits = fit_all_skills(data)
    assert fits["10"].method == "em"
    assert fits["11"].method == "defaults"
