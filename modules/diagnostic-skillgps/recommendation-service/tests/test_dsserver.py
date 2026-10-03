"""Tests for the recommendation service, including Gemini model fallback."""

from __future__ import annotations

import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import dsserver  # noqa: E402


@pytest.fixture(autouse=True)
def _env(monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "test-key")
    monkeypatch.setenv("ALLOWED_ORIGINS", "http://localhost:5173")
    monkeypatch.setenv("GEMINI_MODELS", "model-a,model-b,model-c")


@pytest.fixture
def client():
    app = dsserver.create_app()
    app.testing = True
    return app.test_client()


def test_health(client):
    body = client.get("/health").get_json()
    assert body["ok"] is True
    assert body["hasKey"] is True
    assert body["models"] == ["model-a", "model-b", "model-c"]


def test_recommend_uses_first_working_model(client, monkeypatch):
    calls = []

    def fake_call(api_key, model, prompt):
        calls.append(model)
        return "Nice wording" if model == "model-a" else None

    monkeypatch.setattr(dsserver, "_call_gemini", fake_call)
    resp = client.post("/recommend", json={"entries": [{"topicId": "t1", "topicName": "Loops"}]})
    assert resp.status_code == 200
    entry = resp.get_json()["entries"][0]
    assert entry["generatedRecommendationText"] == "Nice wording"
    assert entry["reason"] is None
    assert calls == ["model-a"]  # stopped at the first success


def test_recommend_falls_back_to_next_model(client, monkeypatch):
    calls = []

    def fake_call(api_key, model, prompt):
        calls.append(model)
        # a and b fail (overloaded/rate-limited), c succeeds
        return "From C" if model == "model-c" else None

    monkeypatch.setattr(dsserver, "_call_gemini", fake_call)
    resp = client.post("/recommend", json={"entries": [{"topicId": "t1", "topicName": "Trees"}]})
    entry = resp.get_json()["entries"][0]
    assert entry["generatedRecommendationText"] == "From C"
    assert calls == ["model-a", "model-b", "model-c"]  # tried all until success


def test_recommend_all_models_fail_gives_reason(client, monkeypatch):
    monkeypatch.setattr(dsserver, "_call_gemini", lambda *a, **k: None)
    resp = client.post("/recommend", json={"entries": [{"topicId": "t1", "topicName": "Graphs"}]})
    assert resp.status_code == 200  # still 200 so the frontend can fall back
    entry = resp.get_json()["entries"][0]
    assert entry["generatedRecommendationText"] is None
    assert entry["reason"]


def test_malformed_request_400_no_calls(client, monkeypatch):
    called = {"n": 0}
    monkeypatch.setattr(dsserver, "_call_gemini", lambda *a, **k: called.__setitem__("n", called["n"] + 1))
    resp = client.post("/recommend", json={"not_entries": []})
    assert resp.status_code == 400
    assert called["n"] == 0


def test_missing_key_503(client, monkeypatch):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    resp = client.post("/recommend", json={"entries": [{"topicId": "t1"}]})
    assert resp.status_code == 503
