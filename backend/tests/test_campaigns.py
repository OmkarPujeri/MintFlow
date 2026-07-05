"""Campaigns — auth guards, create/list, and the pagination cap (#7)."""


def _admin_headers(client, email="c@d.com"):
    client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "secret123", "role": "company_admin"},
    )
    token = client.post(
        "/api/v1/auth/login", json={"email": email, "password": "secret123"}
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _payload(name="C1"):
    return {
        "name": name,
        "budget": 100.0,
        "rewardPerCompletion": 1.0,
        "startDate": "2026-01-01T00:00:00",
        "endDate": "2026-02-01T00:00:00",
    }


def test_list_requires_auth(client):
    assert client.get("/api/v1/campaigns/").status_code == 401


def test_viewer_forbidden(client):
    client.post(
        "/api/v1/auth/register",
        json={"email": "v@x.com", "password": "secret123", "role": "viewer"},
    )
    token = client.post(
        "/api/v1/auth/login", json={"email": "v@x.com", "password": "secret123"}
    ).json()["access_token"]
    r = client.get("/api/v1/campaigns/", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 403


def test_create_and_list(client):
    headers = _admin_headers(client)
    created = client.post("/api/v1/campaigns/", json=_payload("Launch"), headers=headers)
    assert created.status_code == 201
    assert created.json()["name"] == "Launch"

    listed = client.get("/api/v1/campaigns/", headers=headers)
    assert listed.status_code == 200
    assert len(listed.json()) == 1


def test_pagination_limits_results(client):
    headers = _admin_headers(client)
    for i in range(3):
        client.post("/api/v1/campaigns/", json=_payload(f"C{i}"), headers=headers)

    assert len(client.get("/api/v1/campaigns/?limit=2", headers=headers).json()) == 2
    assert len(client.get("/api/v1/campaigns/?limit=2&offset=2", headers=headers).json()) == 1


def test_pagination_rejects_bad_limit(client):
    headers = _admin_headers(client)
    # limit above the 100 ceiling is a validation error.
    assert client.get("/api/v1/campaigns/?limit=999", headers=headers).status_code == 422
