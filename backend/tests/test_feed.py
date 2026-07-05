"""Viewer feed + /auth/me — the Phase 0 backend fixes for the mobile app.

Covers: camelCase serialization with computed views/completions, questionId on
interactions (needed to submit answers), watched-campaign exclusion, boosted-first
ordering, and the /me gamification payload.
"""


def _admin_headers(client, email="admin@x.com"):
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "secret123", "role": "company_admin"},
    )
    token = client.post(
        "/api/v1/auth/login", json={"email": email, "password": "secret123"}
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _viewer_headers(client, email="viewer@x.com"):
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "secret123", "role": "viewer"},
    )
    token = client.post(
        "/api/v1/auth/login", json={"email": email, "password": "secret123"}
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _campaign_payload(name="C1", boosted=False):
    return {
        "name": name,
        "budget": 100.0,
        "rewardPerCompletion": 5.0,
        "startDate": "2026-01-01T00:00:00",
        "endDate": "2026-02-01T00:00:00",
        "youtubeUrl": "https://youtu.be/dQw4w9WgXcQ",
        "youtubeVideoId": "dQw4w9WgXcQ",
        "interactions": [
            {"type": "quiz", "question": "Pick one?", "options": ["A", "B"], "correctAnswer": "A"},
        ],
    }


def _publish(client, headers, payload):
    """Create + publish a campaign so it's active and shows in the feed. Returns its id."""
    cid = client.post("/api/v1/campaigns/", json=payload, headers=headers).json()["id"]
    client.post(f"/api/v1/campaigns/{cid}/publish", headers=headers)
    if payload.get("_boost"):
        client.post(f"/api/v1/campaigns/{cid}/boost", headers=headers)
    return cid


def test_feed_requires_viewer(client):
    assert client.get("/api/v1/feed/").status_code == 401
    headers = _admin_headers(client)
    assert client.get("/api/v1/feed/", headers=headers).status_code == 403


def test_feed_serializes_camelcase_with_question_id(client):
    admin = _admin_headers(client)
    _publish(client, admin, _campaign_payload("Launch"))

    feed = client.get("/api/v1/feed/", headers=_viewer_headers(client)).json()
    assert len(feed) == 1
    camp = feed[0]
    # camelCase fields the raw-ORM return used to drop
    assert camp["name"] == "Launch"
    assert camp["rewardPerCompletion"] == 5.0
    assert camp["views"] == 0 and camp["completions"] == 0
    # questionId must be present + a real UUID string so /interactions submit works
    qid = camp["interactions"][0]["questionId"]
    assert qid and isinstance(qid, str)


def test_feed_excludes_watched_campaign(client):
    admin = _admin_headers(client)
    cid = _publish(client, admin, _campaign_payload("Watched"))
    viewer = _viewer_headers(client)

    assert len(client.get("/api/v1/feed/", headers=viewer).json()) == 1
    started = client.post("/api/v1/watch/start", json={"campaign_id": cid}, headers=viewer)
    assert started.status_code == 201
    # after starting a session, it must drop out of the feed (no 409-on-tap)
    assert client.get("/api/v1/feed/", headers=viewer).json() == []


def test_feed_boosted_first(client):
    admin = _admin_headers(client)
    _publish(client, admin, _campaign_payload("Plain"))
    boosted = _campaign_payload("Boosted")
    boosted["_boost"] = True
    _publish(client, admin, boosted)

    feed = client.get("/api/v1/feed/", headers=_viewer_headers(client)).json()
    assert [c["name"] for c in feed][0] == "Boosted"


def test_me_returns_gamification(client):
    viewer = _viewer_headers(client, email="me@x.com")
    r = client.get("/api/v1/auth/me", headers=viewer)
    assert r.status_code == 200
    body = r.json()
    assert body["email"] == "me@x.com"
    assert body["role"] == "viewer"
    for k in ("mintCoins", "coinsEarnedToday", "raffleTickets", "dailyStreak"):
        assert body[k] == 0
    assert body["walletBalanceInr"] == 0.0


def test_me_requires_auth(client):
    assert client.get("/api/v1/auth/me").status_code == 401
