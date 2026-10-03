"""Tests for the BKT Prediction_API (ml/dsprediction_api.py)."""

from __future__ import annotations

import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dsbkt import DEFAULT_PARAMS  # noqa: E402
import dsprediction_api as api  # noqa: E402


def _bundle():
    return {
        "engine": "bkt",
        "skill_params": {"5": {"p_init": 0.3, "p_transit": 0.2, "p_slip": 0.1, "p_guess": 0.2}},
        "default_params": DEFAULT_PARAMS.as_dict(),
    }


@pytest.fixture
def client():
    app = api.create_app(bundle=_bundle())
    app.testing = True
    return app.test_client()


@pytest.fixture
def unloaded_client():
    app = api.create_app(bundle=None)
    app.testing = True
    return app.test_client()


def test_health_loaded(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["loaded"] is True
    assert body["engine"] == "bkt"
    assert body["skills_count"] == 1


def test_health_unloaded(unloaded_client):
    body = unloaded_client.get("/health").get_json()
    assert body["loaded"] is False
    assert body["skills_count"] == 0


def test_predict_valid_object(client):
    resp = client.post("/predict", json={"topic_id": "5", "responses": [True, True, True, False]})
    assert resp.status_code == 200
    body = resp.get_json()
    assert set(body) == {"predicted_label", "confidence", "probabilities", "mastery_probability"}
    assert 0.0 <= body["mastery_probability"] <= 1.0
    assert abs(sum(body["probabilities"].values()) - 1.0) < 1e-9


def test_predict_bare_list(client):
    resp = client.post("/predict", json=[1, 0, 1, 1])
    assert resp.status_code == 200


def test_predict_missing_responses_400(client):
    resp = client.post("/predict", json={"topic_id": "5"})
    assert resp.status_code == 400


def test_predict_malformed_json_400(client):
    resp = client.post("/predict", data="not json", content_type="application/json")
    assert resp.status_code == 400


def test_predict_invalid_sequence_400(client):
    resp = client.post("/predict", json={"responses": []})
    assert resp.status_code == 400
    assert "fields" in resp.get_json()


def test_predict_unloaded_503(unloaded_client):
    resp = unloaded_client.post("/predict", json={"responses": [1, 0]})
    assert resp.status_code == 503


def test_predict_too_large_413(client):
    big = {"responses": [{"is_correct": True, "difficulty": 2}] * 2000}
    resp = client.post("/predict", json=big)
    assert resp.status_code == 413


def test_cors_only_allowed_origin(monkeypatch):
    monkeypatch.setenv("ALLOWED_ORIGINS", "http://localhost:5173")
    app = api.create_app(bundle=_bundle())
    app.testing = True
    c = app.test_client()
    ok = c.get("/health", headers={"Origin": "http://localhost:5173"})
    assert ok.headers.get("Access-Control-Allow-Origin") == "http://localhost:5173"
    bad = c.get("/health", headers={"Origin": "http://evil.example"})
    assert bad.headers.get("Access-Control-Allow-Origin") is None


def test_cors_never_wildcard(monkeypatch):
    monkeypatch.setenv("ALLOWED_ORIGINS", "http://localhost:5173")
    app = api.create_app(bundle=_bundle())
    app.testing = True
    c = app.test_client()
    resp = c.get("/health", headers={"Origin": "http://localhost:5173"})
    assert resp.headers.get("Access-Control-Allow-Origin") != "*"
