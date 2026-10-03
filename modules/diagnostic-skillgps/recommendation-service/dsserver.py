"""Recommendation_Service — rewrites recommendation wording with Gemini.

This server-side-only service holds the GEMINI_API_KEY and turns a list of
recommendation entries into friendlier wording, grounded in each entry''s
deterministic Recommendation_Content. It NEVER decides which topics to
recommend or their order (the frontend Recommendation_Engine does that) and it
makes no mastery decisions.

Model fallback
--------------
Gemini free-tier models occasionally return transient errors (overloaded,
rate-limited, or temporarily unavailable). To lessen the chance of a failed
request, the service tries a chain of free models in order and uses the first
one that answers. The chain is ordered by free-tier quota headroom (most
generous first), since this task is lightweight text rewriting:

    gemini-2.5-flash-lite -> gemini-2.5-flash -> gemini-2.0-flash
    -> gemini-2.0-flash-lite -> gemini-1.5-flash -> gemini-1.5-flash-8b

Override the chain with GEMINI_MODELS (comma-separated) in the environment.

Endpoints
---------
    GET  /health   -> { ok, hasKey, models }
    POST /recommend-> { entries: [ { topicId, generatedRecommendationText, reason } ] }

Behavior:
  * Per-entry failure/timeout/empty across ALL models -> that entry gets a null
    generatedRecommendationText and a reason, still HTTP 200 (the frontend falls
    back to the deterministic Recommendation_Content).
  * Malformed request -> 400, zero Gemini calls.
  * Missing GEMINI_API_KEY -> log + 503 for every request.
  * Unexpected error -> 500, no stack traces.
  * CORS strictly from ALLOWED_ORIGINS (never *); holds no Supabase creds;
    stores nothing.
"""

from __future__ import annotations

import logging
import os

import requests
from flask import Flask, jsonify, request

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("recommendation-service")

MAX_BODY_BYTES = 64 * 1024
GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/models"
REQUEST_TIMEOUT_SECONDS = 10

# Default free-model fallback chain, verified available via ListModels and
# ordered newest-and-most-generous first for lightweight text rewriting. The
# `-latest` aliases are listed first because Google keeps them pointed at the
# current flash models, which keeps this chain working as model names change.
# Override with the GEMINI_MODELS env var (comma-separated) if needed.
DEFAULT_MODELS = [
    "gemini-flash-lite-latest",
    "gemini-flash-latest",
    "gemini-3.5-flash-lite",
    "gemini-3.5-flash",
    "gemini-2.5-flash",
    "gemini-2.5-pro",
]


def _models() -> list[str]:
    raw = os.environ.get("GEMINI_MODELS", "")
    chain = [m.strip() for m in raw.split(",") if m.strip()]
    return chain or list(DEFAULT_MODELS)


def _allowed_origins() -> list[str]:
    raw = os.environ.get("ALLOWED_ORIGINS", "")
    origins = [o.strip() for o in raw.split(",") if o.strip()]
    return origins or ["http://localhost:5173"]


def _prompt_for(entry: dict) -> str:
    name = str(entry.get("topicName", "this topic"))
    level = str(entry.get("masteryLevel", "Developing"))
    prob = entry.get("masteryProbability", None)
    content = str(entry.get("recommendationContent", "")).strip()
    pct = f"{round(float(prob) * 100)}%" if isinstance(prob, (int, float)) else "unknown"
    return (
        "You are a friendly study coach. Rewrite the following study recommendation "
        "in 2-3 encouraging sentences for a student. Keep the facts and the suggested "
        "actions; do not invent new resources or change the topic.\n\n"
        f"Topic: {name}\n"
        f"Mastery level: {level} (mastery probability {pct})\n"
        f"Base recommendation: {content or 'Review the fundamentals of this topic.'}\n\n"
        "Rewritten recommendation:"
    )


def _call_gemini(api_key: str, model: str, prompt: str) -> str | None:
    """Call one Gemini model. Returns text on success, or None on any failure."""
    url = f"{GEMINI_BASE}/{model}:generateContent"
    try:
        resp = requests.post(
            url,
            params={"key": api_key},
            json={"contents": [{"parts": [{"text": prompt}]}]},
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
    except requests.RequestException as exc:
        log.warning("model %s request error: %s", model, exc)
        return None

    if resp.status_code != 200:
        # 429 (rate limit), 503 (overloaded), 404 (model gone) -> try next model.
        log.warning("model %s returned HTTP %s", model, resp.status_code)
        return None

    try:
        data = resp.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"].strip()
    except (ValueError, KeyError, IndexError, TypeError):
        log.warning("model %s returned an unparseable body", model)
        return None

    return text or None


def _generate_with_fallback(api_key: str, models: list[str], prompt: str):
    """Try each model in order. Returns (text, model) or (None, reason)."""
    for model in models:
        text = _call_gemini(api_key, model, prompt)
        if text:
            return text, model
    return None, "all models failed or were unavailable"


def create_app() -> Flask:
    app = Flask(__name__)
    app.config["MAX_CONTENT_LENGTH"] = MAX_BODY_BYTES
    allowed = _allowed_origins()
    models = _models()

    @app.after_request
    def cors(resp):  # noqa: ANN001
        origin = request.headers.get("Origin")
        if origin and origin in allowed:
            resp.headers["Access-Control-Allow-Origin"] = origin
            resp.headers["Vary"] = "Origin"
            resp.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
        return resp

    @app.route("/health", methods=["GET", "OPTIONS"])
    def health():
        if request.method == "OPTIONS":
            return ("", 204)
        return jsonify({"ok": True, "hasKey": bool(os.environ.get("GEMINI_API_KEY")), "models": models}), 200

    @app.route("/recommend", methods=["POST", "OPTIONS"])
    def recommend():
        if request.method == "OPTIONS":
            return ("", 204)

        api_key = os.environ.get("GEMINI_API_KEY", "").strip()
        if not api_key:
            log.error("GEMINI_API_KEY is not set; cannot generate wording")
            return jsonify({"error": "Recommendation service is not configured."}), 503

        data = request.get_json(silent=True)
        if not isinstance(data, dict) or not isinstance(data.get("entries"), list):
            return jsonify({"error": "Request must be an object with an 'entries' array."}), 400

        out = []
        try:
            for entry in data["entries"]:
                if not isinstance(entry, dict):
                    out.append({"topicId": None, "generatedRecommendationText": None, "reason": "invalid entry"})
                    continue
                prompt = _prompt_for(entry)
                text, info = _generate_with_fallback(api_key, models, prompt)
                out.append({
                    "topicId": entry.get("topicId"),
                    "generatedRecommendationText": text,
                    "reason": None if text else info,
                })
        except Exception:  # noqa: BLE001 - never leak internals
            log.exception("unexpected error generating recommendations")
            return jsonify({"error": "Internal server error."}), 500

        return jsonify({"entries": out}), 200

    @app.errorhandler(413)
    def too_large(_err):  # noqa: ANN001
        return jsonify({"error": "Request body too large."}), 413

    return app


def main() -> int:
    port = int(os.environ.get("PORT", "8001"))
    create_app().run(host="127.0.0.1", port=port, debug=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
