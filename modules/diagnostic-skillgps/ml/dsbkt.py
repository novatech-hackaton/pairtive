"""Bayesian Knowledge Tracing (BKT) core engine.

PURE MODULE: this file imports only the Python standard library. It has no
file, network, pandas, numpy, or scikit-learn dependency, so it can be tested
in isolation. Parameter fitting (``dsbkt_fit``), model persistence
(``dstrain_model``), and serving (``dsprediction_api``) build on top of it.

Bayesian Knowledge Tracing models a single latent, binary skill (here, one
skill per diagnostic topic) that a learner is either in the "mastered" or
"not mastered" state for. It processes a learner's answers to that skill one at
a time, in order, and after each answer updates the probability that the skill
is mastered. The four parameters are:

    p_init    P(L0)  prior probability the skill is already mastered
    p_transit P(T)   probability of moving unmastered -> mastered per opportunity
    p_slip    P(S)   probability of answering incorrectly despite mastery
    p_guess   P(G)   probability of answering correctly without mastery

Update equations for one observation (``correct`` is True/False). Given the
current prior P(L) that the skill is mastered *before* this answer:

    # 1. Posterior P(L | evidence) using Bayes' rule
    if correct:
        p_evidence = P(L)*(1 - p_slip) + (1 - P(L))*p_guess
        posterior  = P(L)*(1 - p_slip) / p_evidence
    else:
        p_evidence = P(L)*p_slip + (1 - P(L))*(1 - p_guess)
        posterior  = P(L)*p_slip / p_evidence

    # 2. Apply the learning transition to get the prior for the next answer
    P(L_next) = posterior + (1 - posterior)*p_transit

After the final answer in a sequence, the mastery probability is the posterior
P(L | all evidence) *before* the final transition is applied -- it is the best
estimate of the current mastery state given everything observed. This scalar in
[0, 1] is the ``mastery_probability`` the rest of the system already consumes,
so BKT is a drop-in for the previous classifier's output contract.

The three-level distribution (Weak/Developing/Proficient) that the
``Prediction_Result`` carries is derived deterministically from that scalar via
``probabilities_from_mastery`` so the response keeps its original shape without
reintroducing a classifier. The frontend's Mastery_Classifier still derives the
stored Mastery_Level from ``mastery_probability`` using the 0.40/0.70
thresholds; this module only mirrors those thresholds to shape the probability
triple.

Requirements covered (BKT revision): 17.1-17.8.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from numbers import Real
from typing import Any, Iterable, Mapping, Sequence

# Mastery-probability thresholds mirrored from the frontend Threshold_Config
# (developingThreshold = 0.40, proficientThreshold = 0.70). They are used ONLY
# to shape the Weak/Developing/Proficient probability triple in
# ``probabilities_from_mastery``; the authoritative Mastery_Level is still
# derived on the frontend. Keeping them here avoids a cross-language import and
# matches the documented defaults.
DEVELOPING_THRESHOLD = 0.40
PROFICIENT_THRESHOLD = 0.70

LEVELS: tuple[str, ...] = ("Weak", "Developing", "Proficient")

# Clamp bounds that keep fitted/supplied parameters identifiable and
# non-degenerate. ``p_slip`` and ``p_guess`` are additionally required to sum to
# strictly less than 1 (a mastered learner must be more likely to answer
# correctly than an unmastered one).
PARAM_MIN = 0.0
PARAM_MAX = 1.0
SLIP_GUESS_MAX = 0.5  # fitters clamp slip/guess into [0, 0.5] for stability


class BKTError(ValueError):
    """Raised for invalid BKT parameters or invalid response sequences.

    Carries an ``errors`` list so every problem can be reported at once, matching
    the aggregation style of the Preprocessor's ``PreprocessError``.
    """

    def __init__(self, errors: Sequence[str]):
        self.errors = list(errors)
        super().__init__("; ".join(self.errors))


def _is_finite_number(value: Any) -> bool:
    """Return True only for a real, finite number (bool excluded)."""
    if isinstance(value, bool):
        return False
    if not isinstance(value, Real):
        return False
    return math.isfinite(float(value))


@dataclass(frozen=True)
class BKTParams:
    """The four BKT parameters for one skill, validated on construction.

    Raises ``BKTError`` listing every invalid field when any parameter is not a
    finite number in [0, 1], or when ``p_slip + p_guess >= 1`` (which would make
    a correct answer no more likely under mastery than under non-mastery and
    makes the model unidentifiable).
    """

    p_init: float
    p_transit: float
    p_slip: float
    p_guess: float

    def __post_init__(self) -> None:
        errors: list[str] = []
        for name in ("p_init", "p_transit", "p_slip", "p_guess"):
            value = getattr(self, name)
            if not _is_finite_number(value):
                errors.append(f"{name}: must be a finite number in [0, 1]")
            elif not (PARAM_MIN <= float(value) <= PARAM_MAX):
                errors.append(f"{name}: must be from 0 to 1")
        if not errors and (float(self.p_slip) + float(self.p_guess)) >= 1.0:
            errors.append(
                "p_slip + p_guess: must be strictly less than 1 for identifiability"
            )
        if errors:
            raise BKTError(errors)
        # Normalize to plain floats (frozen dataclass -> use object.__setattr__).
        object.__setattr__(self, "p_init", float(self.p_init))
        object.__setattr__(self, "p_transit", float(self.p_transit))
        object.__setattr__(self, "p_slip", float(self.p_slip))
        object.__setattr__(self, "p_guess", float(self.p_guess))

    def as_dict(self) -> dict[str, float]:
        return {
            "p_init": self.p_init,
            "p_transit": self.p_transit,
            "p_slip": self.p_slip,
            "p_guess": self.p_guess,
        }

    @classmethod
    def from_mapping(cls, data: Mapping[str, Any]) -> "BKTParams":
        """Build params from a mapping, reporting any missing field."""
        if not isinstance(data, Mapping):
            raise BKTError(["params: must be a mapping of the four BKT fields"])
        missing = [
            name
            for name in ("p_init", "p_transit", "p_slip", "p_guess")
            if data.get(name, None) is None
        ]
        if missing:
            raise BKTError([f"{name}: missing parameter" for name in missing])
        return cls(
            p_init=data["p_init"],
            p_transit=data["p_transit"],
            p_slip=data["p_slip"],
            p_guess=data["p_guess"],
        )


# A reasonable, documented default parameter set drawn from common BKT practice.
# Used for skills with too little data to fit (see dsbkt_fit) and as a safe
# fallback for unknown topics in the Predictor.
DEFAULT_PARAMS = BKTParams(p_init=0.20, p_transit=0.15, p_slip=0.10, p_guess=0.20)


def posterior_given_answer(prior: float, is_correct: bool, params: BKTParams) -> float:
    """Return P(mastered | this answer) via Bayes' rule (no transition applied).

    ``prior`` is P(mastered) before observing the answer and must be in [0, 1].
    """
    if is_correct:
        correct_if_mastered = prior * (1.0 - params.p_slip)
        correct_if_not = (1.0 - prior) * params.p_guess
        evidence = correct_if_mastered + correct_if_not
        if evidence <= 0.0:
            # Degenerate only if prior in {0,1} and params at bounds; fall back
            # to the prior to stay in [0, 1] and deterministic.
            return prior
        return correct_if_mastered / evidence

    wrong_if_mastered = prior * params.p_slip
    wrong_if_not = (1.0 - prior) * (1.0 - params.p_guess)
    evidence = wrong_if_mastered + wrong_if_not
    if evidence <= 0.0:
        return prior
    return wrong_if_mastered / evidence


def apply_transition(posterior: float, params: BKTParams) -> float:
    """Apply the learning transition, returning the prior for the next answer."""
    return posterior + (1.0 - posterior) * params.p_transit


def run_sequence(
    responses: Sequence[bool], params: BKTParams
) -> float:
    """Run BKT over an ordered sequence of correctness values.

    ``responses`` is an ordered sequence of booleans (True = correct). Processes
    them in order, updating mastery after each, and returns the posterior
    mastery probability given the whole sequence (the posterior after the final
    answer, before any further transition). For an empty sequence this returns
    ``p_init`` (the prior with no evidence).

    The result is always in [0, 1] and is deterministic for a given input.
    """
    prior = params.p_init
    posterior = prior
    for index, is_correct in enumerate(responses):
        posterior = posterior_given_answer(prior, bool(is_correct), params)
        # Prepare the prior for the next observation.
        prior = apply_transition(posterior, params)
    # If there were no responses, report the prior; otherwise the last posterior.
    result = posterior if len(responses) > 0 else params.p_init
    # Guard against tiny floating-point drift outside [0, 1].
    return min(1.0, max(0.0, result))


def mastery_trajectory(
    responses: Sequence[bool], params: BKTParams
) -> list[float]:
    """Return the posterior mastery probability after each answer, in order.

    Useful for inspection, charts, and tests. The returned list has the same
    length as ``responses`` (empty for an empty sequence).
    """
    trajectory: list[float] = []
    prior = params.p_init
    for is_correct in responses:
        posterior = posterior_given_answer(prior, bool(is_correct), params)
        trajectory.append(min(1.0, max(0.0, posterior)))
        prior = apply_transition(posterior, params)
    return trajectory


def probabilities_from_mastery(mastery_probability: float) -> dict[str, float]:
    """Map a scalar mastery probability to a Weak/Developing/Proficient triple.

    BKT estimates a single mastery probability; the Prediction_Result keeps a
    three-level distribution for backward compatibility. The mapping is
    deterministic, continuous, and anchored on the same thresholds the frontend
    uses (0.40, 0.70):

      * membership peaks at Proficient as p -> 1, at Weak as p -> 0, and at
        Developing around the midpoint of [0.40, 0.70];
      * the three values are non-negative and sum to 1 (within 1e-9);
      * the mapping is monotonic at the extremes so argmax agrees with the
        threshold-based level for clearly-weak and clearly-proficient inputs.

    This is a presentation-only shaping of ``mastery_probability``; the stored
    Mastery_Level is still derived by the frontend classifier.
    """
    p = min(1.0, max(0.0, float(mastery_probability)))

    # Triangular membership centred on three anchors: Weak at 0.0, Developing at
    # the midpoint of the developing band, Proficient at 1.0.
    weak_anchor = 0.0
    dev_anchor = (DEVELOPING_THRESHOLD + PROFICIENT_THRESHOLD) / 2.0
    prof_anchor = 1.0

    def closeness(anchor: float, width: float) -> float:
        # Linear tent: 1 at the anchor, decaying to 0 at +/- width.
        return max(0.0, 1.0 - abs(p - anchor) / width)

    weak = closeness(weak_anchor, max(dev_anchor, 1e-9))
    developing = closeness(dev_anchor, max(dev_anchor, 1.0 - dev_anchor))
    proficient = closeness(prof_anchor, max(1.0 - dev_anchor, 1e-9))

    total = weak + developing + proficient
    if total <= 0.0:
        # Should not happen, but keep the contract (sum to 1) no matter what.
        return {"Weak": 1.0, "Developing": 0.0, "Proficient": 0.0}
    return {
        "Weak": weak / total,
        "Developing": developing / total,
        "Proficient": proficient / total,
    }


def build_prediction_result(mastery_probability: float) -> dict[str, Any]:
    """Assemble a Prediction_Result dict from a mastery probability.

    Keeps the original output contract:
        { predicted_label, confidence, probabilities{Weak,Developing,Proficient},
          mastery_probability }
    ``predicted_label`` is the argmax of the probability triple; on a tie the
    lower level wins (Weak < Developing < Proficient), matching the previous
    Predictor's tie rule. ``confidence`` is the maximum of the triple.
    """
    p = min(1.0, max(0.0, float(mastery_probability)))
    probabilities = probabilities_from_mastery(p)

    # Argmax with ties resolved to the lower level (LEVELS is low->high order).
    best_level = LEVELS[0]
    best_value = probabilities[LEVELS[0]]
    for level in LEVELS[1:]:
        if probabilities[level] > best_value:
            best_level = level
            best_value = probabilities[level]

    return {
        "predicted_label": best_level,
        "confidence": best_value,
        "probabilities": probabilities,
        "mastery_probability": p,
    }


def validate_response_sequence(responses: Any) -> list[bool]:
    """Validate and normalize a response sequence into a list of booleans.

    Accepts a sequence (not a string) of up to 20 items where each item is
    either a boolean-like correctness value or a mapping carrying an
    ``is_correct`` / ``isCorrect`` field (an optional ``difficulty`` of an
    integer 1..3 is accepted and ignored by v1 but validated when present).
    Returns the ordered list of booleans. Raises ``BKTError`` listing every
    invalid position when the sequence is empty, too long, or malformed.
    """
    if isinstance(responses, (str, bytes)) or not isinstance(responses, Iterable):
        raise BKTError(["responses: must be a sequence of answers"])

    items = list(responses)
    errors: list[str] = []
    if len(items) == 0:
        errors.append("responses: must contain at least 1 answer")
    elif len(items) > 20:
        errors.append("responses: must contain at most 20 answers")

    normalized: list[bool] = []
    for index, item in enumerate(items):
        if isinstance(item, Mapping):
            correctness = item.get("is_correct", item.get("isCorrect", None))
            if correctness is None:
                errors.append(f"responses[{index}].is_correct: missing correctness value")
            else:
                normalized.append(bool(correctness))
            difficulty = item.get("difficulty", None)
            if difficulty is not None:
                if (
                    not _is_finite_number(difficulty)
                    or float(difficulty) != math.floor(float(difficulty))
                    or not (1 <= float(difficulty) <= 3)
                ):
                    errors.append(
                        f"responses[{index}].difficulty: must be an integer from 1 to 3"
                    )
        elif isinstance(item, bool):
            normalized.append(item)
        elif _is_finite_number(item) and float(item) in (0.0, 1.0):
            normalized.append(bool(int(item)))
        else:
            errors.append(
                f"responses[{index}]: must be a boolean, 0/1, or a mapping with is_correct"
            )

    if errors:
        raise BKTError(errors)
    return normalized


def predict_sequence(responses: Any, params: BKTParams) -> dict[str, Any]:
    """Validate a raw response sequence, run BKT, and build a Prediction_Result.

    Convenience entry point used by the Predictor and the Prediction_API.
    Raises ``BKTError`` on an invalid sequence.
    """
    normalized = validate_response_sequence(responses)
    mastery = run_sequence(normalized, params)
    return build_prediction_result(mastery)
