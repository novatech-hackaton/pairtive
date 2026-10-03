"""BKT parameter fitting from ordered response sequences.

Given a collection of ordered correct/incorrect sequences for a single skill,
``fit_skill`` estimates the four BKT parameters by Expectation-Maximization
(EM) on the hidden-mastery chain (a two-state HMM with tied emission). For a
skill with too few sequences to fit stably, the caller backs off to a supplied
default parameter set. ``fit_all_skills`` groups a dataset by topic and fits
each skill, recording per-skill fit metrics.

This module depends on numpy only (no network, no scikit-learn). It is
deterministic for a given input and seed: EM is initialized from fixed starting
points, so repeated runs on the same data return the same parameters.

Fitted parameters are clamped into identifiable, non-degenerate bounds
(``dsbkt.SLIP_GUESS_MAX`` on slip/guess) so a bad local optimum cannot produce a
model where guessing beats mastery.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from typing import Iterable, Mapping, Sequence

import numpy as np

try:  # support both "run from ml/" and "import as ml.dsbkt_fit"
    from dsbkt import DEFAULT_PARAMS, SLIP_GUESS_MAX, BKTParams
except ImportError:  # pragma: no cover
    from ml.dsbkt import DEFAULT_PARAMS, SLIP_GUESS_MAX, BKTParams

# A skill needs at least this many sequences before we trust an EM fit; below
# it we back off to the default parameters.
MIN_SEQUENCES_TO_FIT = 10
# EM controls.
MAX_EM_ITERS = 200
EM_TOLERANCE = 1e-5
_EPS = 1e-9


@dataclass
class SkillFit:
    """The result of fitting (or defaulting) one skill."""

    params: BKTParams
    method: str  # "em" or "defaults"
    n_sequences: int
    log_likelihood: float = float("nan")
    predictive_accuracy: float = float("nan")


def _clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, value))


def _clamp_params(p_init, p_transit, p_slip, p_guess) -> BKTParams:
    """Clamp raw estimates into valid, identifiable bounds."""
    p_init = _clamp(p_init, _EPS, 1.0 - _EPS)
    p_transit = _clamp(p_transit, 0.0, 1.0 - _EPS)
    p_slip = _clamp(p_slip, _EPS, SLIP_GUESS_MAX)
    p_guess = _clamp(p_guess, _EPS, SLIP_GUESS_MAX)
    # Final guard: ensure slip + guess < 1 (clamping to 0.5 each already does).
    if p_slip + p_guess >= 1.0:
        scale = (1.0 - 2 * _EPS) / (p_slip + p_guess)
        p_slip *= scale
        p_guess *= scale
    return BKTParams(p_init=p_init, p_transit=p_transit, p_slip=p_slip, p_guess=p_guess)


def _forward_backward(seq: np.ndarray, params: BKTParams):
    """Run forward-backward over one 0/1 sequence under the current params.

    Returns (gamma, xi, loglik) where gamma[t] = P(mastered at t | seq) and
    xi captures the unmastered->mastered transitions needed for the M-step.
    States: 0 = not mastered, 1 = mastered.
    """
    T = len(seq)
    pi = np.array([1.0 - params.p_init, params.p_init])
    # Transition: from not-mastered -> mastered with p_transit; mastered is
    # absorbing (no forgetting in standard BKT).
    A = np.array(
        [[1.0 - params.p_transit, params.p_transit], [0.0, 1.0]]
    )
    # Emission P(correct | state): not-mastered -> guess; mastered -> 1 - slip.
    b_correct = np.array([params.p_guess, 1.0 - params.p_slip])
    b_wrong = 1.0 - b_correct

    def emis(t):
        return b_correct if seq[t] == 1 else b_wrong

    # Forward with scaling.
    alpha = np.zeros((T, 2))
    scale = np.zeros(T)
    alpha[0] = pi * emis(0)
    scale[0] = alpha[0].sum() + _EPS
    alpha[0] /= scale[0]
    for t in range(1, T):
        alpha[t] = (alpha[t - 1] @ A) * emis(t)
        scale[t] = alpha[t].sum() + _EPS
        alpha[t] /= scale[t]

    # Backward with the same scaling.
    beta = np.zeros((T, 2))
    beta[T - 1] = 1.0
    for t in range(T - 2, -1, -1):
        beta[t] = (A @ (emis(t + 1) * beta[t + 1])) / scale[t + 1]

    gamma = alpha * beta
    gamma /= gamma.sum(axis=1, keepdims=True) + _EPS

    # xi[t] over transition t->t+1, only the 0->* and 1->* rows matter.
    xi = np.zeros((T - 1, 2, 2))
    for t in range(T - 1):
        num = (
            alpha[t][:, None]
            * A
            * (emis(t + 1) * beta[t + 1])[None, :]
        )
        xi[t] = num / (num.sum() + _EPS)

    loglik = float(np.log(scale + _EPS).sum())
    return gamma, xi, loglik


def _em_fit(sequences: Sequence[np.ndarray], init: BKTParams) -> tuple[BKTParams, float]:
    """Fit BKT params by EM over multiple sequences. Returns (params, loglik)."""
    params = init
    prev_ll = -math.inf
    for _ in range(MAX_EM_ITERS):
        # Accumulators.
        sum_gamma0_not = 0.0  # expected P(not mastered at t=0)
        sum_gamma0_mast = 0.0
        trans_num = 0.0  # expected 0->1 transitions
        trans_den = 0.0  # expected time spent in state 0 (excluding last step)
        guess_num = 0.0  # correct while not mastered
        guess_den = 0.0  # time not mastered
        slip_num = 0.0  # wrong while mastered
        slip_den = 0.0  # time mastered
        total_ll = 0.0

        for seq in sequences:
            gamma, xi, ll = _forward_backward(seq, params)
            total_ll += ll
            sum_gamma0_not += gamma[0, 0]
            sum_gamma0_mast += gamma[0, 1]
            if len(seq) > 1:
                trans_num += xi[:, 0, 1].sum()
                trans_den += gamma[:-1, 0].sum()
            not_mastered = gamma[:, 0]
            mastered = gamma[:, 1]
            correct = seq == 1
            guess_num += not_mastered[correct].sum()
            guess_den += not_mastered.sum()
            slip_num += mastered[~correct].sum()
            slip_den += mastered.sum()

        n = len(sequences)
        p_init = sum_gamma0_mast / (sum_gamma0_mast + sum_gamma0_not + _EPS)
        p_transit = trans_num / (trans_den + _EPS)
        p_guess = guess_num / (guess_den + _EPS)
        p_slip = slip_num / (slip_den + _EPS)

        params = _clamp_params(p_init, p_transit, p_slip, p_guess)

        if abs(total_ll - prev_ll) < EM_TOLERANCE:
            prev_ll = total_ll
            break
        prev_ll = total_ll

    return params, prev_ll


def _predictive_accuracy(sequences: Sequence[np.ndarray], params: BKTParams) -> float:
    """One-step-ahead predictive accuracy of the fitted params on the data."""
    try:
        from dsbkt import apply_transition, posterior_given_answer
    except ImportError:  # pragma: no cover
        from ml.dsbkt import apply_transition, posterior_given_answer

    correct_preds = 0
    total = 0
    for seq in sequences:
        prior = params.p_init
        for obs in seq:
            p_correct = prior * (1.0 - params.p_slip) + (1.0 - prior) * params.p_guess
            predicted = 1 if p_correct >= 0.5 else 0
            correct_preds += int(predicted == obs)
            total += 1
            post = posterior_given_answer(prior, bool(obs), params)
            prior = apply_transition(post, params)
    return correct_preds / total if total else float("nan")


def fit_skill(
    sequences: Sequence[Sequence[int]],
    default_params: BKTParams = DEFAULT_PARAMS,
) -> SkillFit:
    """Fit one skill's BKT params from its sequences, backing off to defaults.

    ``sequences`` is a list of ordered 0/1 lists. When fewer than
    ``MIN_SEQUENCES_TO_FIT`` sequences are available, returns the default
    parameters with method ``"defaults"``.
    """
    arrays = [np.asarray(s, dtype=int) for s in sequences if len(s) > 0]
    n = len(arrays)
    if n < MIN_SEQUENCES_TO_FIT:
        return SkillFit(params=default_params, method="defaults", n_sequences=n)

    # Fixed EM starting point for determinism.
    init = BKTParams(p_init=0.3, p_transit=0.1, p_slip=0.1, p_guess=0.2)
    params, loglik = _em_fit(arrays, init)
    acc = _predictive_accuracy(arrays, params)
    return SkillFit(
        params=params,
        method="em",
        n_sequences=n,
        log_likelihood=loglik,
        predictive_accuracy=acc,
    )


def fit_all_skills(
    sequences_by_skill: Mapping[str, Sequence[Sequence[int]]],
    default_params: BKTParams = DEFAULT_PARAMS,
) -> dict[str, SkillFit]:
    """Fit every skill in a mapping of skill id -> list of 0/1 sequences."""
    return {
        str(skill_id): fit_skill(seqs, default_params)
        for skill_id, seqs in sequences_by_skill.items()
    }
