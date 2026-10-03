"""Preprocessor for the diagnostic SkillGPS ML pipeline.

This module converts raw per-topic answers into a Feature_Vector, validates
Feature_Vectors against the Predictor input rules, and transforms rows of
feature values into a model-ready matrix.

The Feature_Vector is the ordered set of values (glossary order, all unrounded):

    accuracy, correct_answers, incorrect_answers,
    average_difficulty, average_response_time, attempt_count

Formulas (shared with the JavaScript Feature_Extractor so the two agree within
0.0001 on the parity fixtures):

    accuracy             = correct_answers / (correct_answers + incorrect_answers)
    average_difficulty   = arithmetic mean of question difficulties (each 1..3)
    average_response_time = arithmetic mean Response_Time in seconds
    attempt_count        = the supplied attempt count

Requirements covered: 12.3, 17.6, 17.7, 17.8.
"""

from __future__ import annotations

import math
from numbers import Real
from typing import Any, Iterable, Mapping, Sequence

# Feature_Vector field order (glossary order). Every function in this module
# produces or consumes features in exactly this order.
FEATURE_NAMES: tuple[str, ...] = (
    "accuracy",
    "correct_answers",
    "incorrect_answers",
    "average_difficulty",
    "average_response_time",
    "attempt_count",
)

# Fields that must be present on a Feature_Vector. ``attempt_count`` is optional
# and defaults to 1 (Req 17.8), so it is not in this set.
REQUIRED_FIELDS: tuple[str, ...] = (
    "accuracy",
    "correct_answers",
    "incorrect_answers",
    "average_difficulty",
    "average_response_time",
)

# Tolerance for the accuracy-consistency rule (Req 17.7).
ACCURACY_CONSISTENCY_TOLERANCE = 0.01


class PreprocessError(ValueError):
    """Raised when answers or a Feature_Vector are invalid.

    The error reports every invalid field in a single message so a caller can
    surface all problems at once (Req 12.6, 17.6).
    """

    def __init__(self, errors: Sequence[str]):
        self.errors = list(errors)
        super().__init__("; ".join(self.errors))


def _is_finite_number(value: Any) -> bool:
    """Return True only for a real, finite number (not bool, NaN, or inf)."""
    # bool is a subclass of int; a correctness flag is valid but a boolean is
    # never a valid numeric feature value.
    if isinstance(value, bool):
        return False
    if not isinstance(value, Real):
        return False
    return math.isfinite(float(value))


def _is_whole_number(value: Real) -> bool:
    """Return True when a finite number has no fractional part."""
    return float(value) == math.floor(float(value))


def extract_features(
    answers: Iterable[Mapping[str, Any]],
    attempt_count: Any,
) -> dict[str, float]:
    """Convert a topic's answers plus an attempt count into a Feature_Vector.

    ``answers`` is a Valid_Answer_Set: 1 to 20 answers, each a mapping with:
      - ``is_correct`` (or ``isCorrect``): a correctness value (truthy/falsey)
      - ``difficulty``: an integer from 1 to 3
      - ``response_time`` (or ``responseTime``): seconds greater than 0

    Returns a Feature_Vector dict in glossary order with no value rounded
    (Req 12.1, 12.3). Raises ``PreprocessError`` identifying every invalid field
    when the answer set is empty, has more than 20 answers, or contains an answer
    with a missing correctness value, a difficulty that is not an integer 1..3,
    or a missing or non-positive Response_Time (Req 12.6).
    """
    answer_list = list(answers)
    errors: list[str] = []

    if len(answer_list) == 0:
        errors.append("answers: must contain at least 1 answer")
    elif len(answer_list) > 20:
        errors.append("answers: must contain at most 20 answers")

    correct_answers = 0
    incorrect_answers = 0
    difficulty_sum = 0.0
    response_time_sum = 0.0

    for index, answer in enumerate(answer_list):
        if not isinstance(answer, Mapping):
            errors.append(f"answers[{index}]: must be a mapping of fields")
            continue

        # Correctness value (required).
        correctness = answer.get("is_correct", answer.get("isCorrect", None))
        if correctness is None:
            errors.append(f"answers[{index}].is_correct: missing correctness value")
        else:
            if bool(correctness):
                correct_answers += 1
            else:
                incorrect_answers += 1

        # Difficulty: integer from 1 to 3.
        difficulty = answer.get("difficulty", None)
        if difficulty is None:
            errors.append(f"answers[{index}].difficulty: missing difficulty value")
        elif not _is_finite_number(difficulty):
            errors.append(
                f"answers[{index}].difficulty: must be an integer from 1 to 3"
            )
        elif not _is_whole_number(difficulty) or not (1 <= float(difficulty) <= 3):
            errors.append(
                f"answers[{index}].difficulty: must be an integer from 1 to 3"
            )
        else:
            difficulty_sum += float(difficulty)

        # Response_Time: a number of seconds greater than 0.
        response_time = answer.get("response_time", answer.get("responseTime", None))
        if response_time is None:
            errors.append(
                f"answers[{index}].response_time: missing Response_Time"
            )
        elif not _is_finite_number(response_time):
            errors.append(
                f"answers[{index}].response_time: must be a number greater than 0"
            )
        elif float(response_time) <= 0:
            errors.append(
                f"answers[{index}].response_time: must be greater than 0"
            )
        else:
            response_time_sum += float(response_time)

    if errors:
        raise PreprocessError(errors)

    total = correct_answers + incorrect_answers
    count = len(answer_list)

    feature_vector = {
        "accuracy": correct_answers / total,
        "correct_answers": correct_answers,
        "incorrect_answers": incorrect_answers,
        "average_difficulty": difficulty_sum / count,
        "average_response_time": response_time_sum / count,
        "attempt_count": attempt_count,
    }
    return feature_vector


def validate_feature_vector(fv: Mapping[str, Any]) -> dict[str, float]:
    """Validate a Feature_Vector against the Predictor input rules.

    Applies every invalid-field rule (Req 17.6), the accuracy-consistency rule
    (Req 17.7), and the ``attempt_count`` default of 1 when omitted or null
    (Req 17.8). Returns a normalized Feature_Vector dict (floats, with
    ``attempt_count`` defaulted) when valid; raises ``PreprocessError`` reporting
    every invalid field in a single error otherwise.
    """
    if not isinstance(fv, Mapping):
        raise PreprocessError(["feature_vector: must be a mapping of fields"])

    errors: list[str] = []

    # attempt_count defaults to 1 when omitted or null (Req 17.8). Normalize
    # before validation so the rest of the rules see the effective value.
    raw_attempt_count = fv.get("attempt_count", None)
    if raw_attempt_count is None:
        attempt_count: Any = 1
    else:
        attempt_count = raw_attempt_count

    # Required fields must be present (Req 17.6: a missing required field is
    # any field other than attempt_count).
    for field in REQUIRED_FIELDS:
        if fv.get(field, None) is None:
            errors.append(f"{field}: missing required field")

    # Every present field must be a finite number (not NaN/inf/non-numeric).
    numeric: dict[str, float] = {}
    for field in FEATURE_NAMES:
        value = attempt_count if field == "attempt_count" else fv.get(field, None)
        if value is None:
            # Already reported as missing for required fields; attempt_count was
            # defaulted so it is never None here.
            continue
        if not _is_finite_number(value):
            errors.append(f"{field}: must be a finite number")
        else:
            numeric[field] = float(value)

    # Field-level range and integrality rules (Req 17.6).
    accuracy = numeric.get("accuracy")
    if accuracy is not None and not (0 <= accuracy <= 1):
        errors.append("accuracy: must be from 0 to 1")

    correct = numeric.get("correct_answers")
    if correct is not None and (correct < 0 or not _is_whole_number(correct)):
        errors.append("correct_answers: must be a non-negative whole number")

    incorrect = numeric.get("incorrect_answers")
    if incorrect is not None and (incorrect < 0 or not _is_whole_number(incorrect)):
        errors.append("incorrect_answers: must be a non-negative whole number")

    if correct is not None and incorrect is not None and (correct + incorrect) == 0:
        errors.append(
            "correct_answers, incorrect_answers: their sum must be at least 1"
        )

    difficulty = numeric.get("average_difficulty")
    if difficulty is not None and not (1 <= difficulty <= 3):
        errors.append("average_difficulty: must be from 1 to 3")

    response_time = numeric.get("average_response_time")
    if response_time is not None and response_time <= 0:
        errors.append("average_response_time: must be greater than 0")

    attempt = numeric.get("attempt_count")
    if attempt is not None and (attempt < 1 or not _is_whole_number(attempt)):
        errors.append("attempt_count: must be a whole number of at least 1")

    if errors:
        raise PreprocessError(errors)

    # Accuracy-consistency rule (Req 17.7): only checked once criterion 6 passes.
    # A difference of 0.01 or less is accepted.
    denominator = correct + incorrect  # type: ignore[operator]
    expected_accuracy = correct / denominator  # type: ignore[operator]
    difference = abs(accuracy - expected_accuracy)  # type: ignore[arg-type]
    # A difference of 0.01 or less is accepted (Req 17.7). A small epsilon keeps
    # a difference of exactly 0.01 from being rejected due to binary floating
    # point (e.g. 0.51 - 0.50 evaluates to 0.0100000000000000009).
    if difference > ACCURACY_CONSISTENCY_TOLERANCE + 1e-9:
        raise PreprocessError(
            [
                "accuracy: inconsistent with correct/(correct+incorrect) "
                f"(expected ~{expected_accuracy}, got {accuracy})"
            ]
        )

    return {
        "accuracy": float(accuracy),  # type: ignore[arg-type]
        "correct_answers": float(correct),  # type: ignore[arg-type]
        "incorrect_answers": float(incorrect),  # type: ignore[arg-type]
        "average_difficulty": float(difficulty),  # type: ignore[arg-type]
        "average_response_time": float(response_time),  # type: ignore[arg-type]
        "attempt_count": float(attempt),  # type: ignore[arg-type]
    }


def to_feature_row(fv: Mapping[str, Any]) -> list[float]:
    """Return a Feature_Vector's values as a list in Feature_Vector order.

    ``attempt_count`` defaults to 1 when omitted or null (Req 17.8). Values are
    taken as-is (empty values are left as ``None`` so the imputer can fill them
    during ``transform``).
    """
    row: list[Any] = []
    for name in FEATURE_NAMES:
        if name == "attempt_count":
            value = fv.get("attempt_count", None)
            value = 1 if value is None else value
        else:
            value = fv.get(name, None)
        row.append(float(value) if value is not None else None)
    return row


def transform(
    feature_rows: Iterable[Mapping[str, Any]],
    imputer: Any,
    scaler: Any,
) -> Any:
    """Build a model-ready matrix from Feature_Vector rows in glossary order.

    Each row in ``feature_rows`` is a Feature_Vector mapping. Columns are laid
    out in Feature_Vector order (``FEATURE_NAMES``), the fitted ``imputer`` fills
    empty values, and the fitted ``scaler`` standardizes the result. The imputer
    and scaler are applied with ``transform`` only (never fit here) so no
    information leaks from the data being transformed.

    Returns the transformed 2-D array (``numpy.ndarray`` when scikit-learn
    transformers are used).
    """
    matrix = [to_feature_row(fv) for fv in feature_rows]
    imputed = imputer.transform(matrix)
    scaled = scaler.transform(imputed)
    return scaled
