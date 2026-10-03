"""HTTP Prediction_API for the BKT engine (Flask).

Loads the BKT Model_Bundle once at startup from ``MODEL_PATH`` and serves:

    GET  /health   -> { "loaded": bool, "engine": "bkt", "skills_count": int }
    POST /predict  -> Prediction_Result

The POST body is a response sequence for one topic:

    { "topic_id": "<id>", "responses": [ {"is_correct": true, "difficulty": 2},
                                          {"is_correct": false}, ... ] }

``responses`` may also be a plain list of booleans / 0-1 ints. ``topic_id`` is
optional; when it is unknown the bundle's default parameters are used.

Behavior (BKT revision of Requirement 18):
  * 200 with a Prediction_Result on valid input;
  * 400 on malformed JSON or an invalid response sequence (reports the fields);
  * 413 when the body exceeds 10 KB;
  * 503 when the Model_Bundle is not loaded;
  * 500 on an unexpected error, with NO stack trace in the response;
  * CORS strictly limited to the origins in ``ALLOWED_ORIGINS`` (never ``*``);
  * holds no Supabase credentials and stores nothing.

Run with::

    MODEL_PATH=ml/dsmodel.pkl ALLOWED_ORIGINS=http://localhost:5173 \
        python ml/dsprediction_api.py        # dev server on PORT (default 8000)
"""

from __future__ import annotations

import os

from flask import Flask, jsonify, request

try:
    from dsbkt import BKTError
    from dspredict import PredictorError, load_bundle, predict
except ImportError:  # pragma: no cover
    from ml.dsbkt import BKTError
    from ml.dspredict import PredictorError, load_bundle, predict

MAX_BODY_BYTES = 10 * 1024  # 10 KB (Req 18)


def _allowed_origins() -> list[str]:
    raw = os.environ.get("ALLOWED_ORIGINS", "")
    return [o.strip() for o in raw.split(",") if o.strip()]


_LOAD_FROM_DISK = object()  # sentinel: load the bundle from MODEL_PATH


def create_app(bundle=_LOAD_FROM_DISK) -> Flask:
    """Application factory. Loads the bundle once from MODEL_PATH unless an
    explicit ``bundle`` (including ``None`` for "stay unloaded") is injected."""
    app = Flask(__name__)
    app.config["MAX_CONTENT_LENGTH"] = MAX_BODY_BYTES
    allowed = _allowed_origins()

    if bundle is _LOAD_FROM_DISK:
        try:
            bundle = load_bundle(os.environ.get("MODEL_PATH"))
        except PredictorError as exc:
            app.logger.warning("Model_Bundle not loaded: %s", exc)
            bundle = None
    app.config["BKT_BUNDLE"] = bundle

    def _cors(resp):
        origin = request.headers.get("Origin")
        if origin and origin in allowed:
            resp.headers["Access-Control-Allow-Origin"] = origin
            resp.headers["Vary"] = "Origin"
            resp.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
        return resp

    @app.after_request
    def after_request(resp):  # noqa: ANN001
        return _cors(resp)

    @app.route("/health", methods=["GET", "OPTIONS"])
    def health():
        if request.method == "OPTIONS":
            return ("", 204)
        b = app.config["BKT_BUNDLE"]
        loaded = b is not None
        skills = len(b.get("skill_params", {})) if loaded else 0
        return jsonify({"loaded": loaded, "engine": "bkt", "skills_count": skills}), 200

    @app.route("/predict", methods=["POST", "OPTIONS"])
    def predict_route():
        if request.method == "OPTIONS":
            return ("", 204)

        b = app.config["BKT_BUNDLE"]
        if b is None:
            return jsonify({"error": "Model_Bundle is not loaded."}), 503

        data = request.get_json(silent=True)
        if data is None:
            return jsonify({"error": "Request body must be valid JSON."}), 400

        if isinstance(data, list):
            responses = data
            topic_id = None
        elif isinstance(data, dict):
            responses = data.get("responses")
            topic_id = data.get("topic_id")
            if responses is None:
                return jsonify({"error": "Missing 'responses' in request body."}), 400
        else:
            return jsonify({"error": "Request body must be an object or array."}), 400

        try:
            result = predict(responses, topic_id, b)
        except BKTError as exc:
            return jsonify({"error": "Invalid response sequence.", "fields": exc.errors}), 400
        except Exception:  # noqa: BLE001 - never leak internals
            app.logger.exception("Unexpected error during prediction")
            return jsonify({"error": "Internal server error."}), 500

        return jsonify(result), 200

    @app.errorhandler(413)
    def too_large(_err):  # noqa: ANN001
        return jsonify({"error": "Request body too large (max 10 KB)."}), 413

    return app


def main() -> int:
    port = int(os.environ.get("PORT", "8000"))
    app = create_app()
    app.run(host="127.0.0.1", port=port, debug=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
