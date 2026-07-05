"""Auth flow — registration, login, and the token-revocation guard (#1)."""


def _register(client, email="a@b.com", pw="secret123", role="company_admin"):
    return client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": pw, "role": role},
    )


def _login(client, email="a@b.com", pw="secret123"):
    return client.post("/api/v1/auth/login", json={"email": email, "password": pw})


def test_register_and_login(client):
    assert _register(client).status_code == 201
    body = _login(client).json()
    assert body["access_token"] and body["refresh_token"]


def test_register_duplicate_email(client):
    _register(client)
    assert _register(client).status_code == 409


def test_register_weak_password_rejected(client):
    assert _register(client, pw="short").status_code == 422


def test_login_wrong_password(client):
    _register(client)
    assert _login(client, pw="wrongpass9").status_code == 401


def test_logout_revokes_access_token(client):
    _register(client)
    token = _login(client).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Works before logout...
    assert client.get("/api/v1/campaigns/", headers=headers).status_code == 200
    assert client.post("/api/v1/auth/logout", headers=headers).status_code == 200
    # ...and is rejected after (this is the bug #1 fixed).
    assert client.get("/api/v1/campaigns/", headers=headers).status_code == 401


def test_refresh_rotates_and_revokes_old(client):
    _register(client)
    old_refresh = _login(client).json()["refresh_token"]

    rotated = client.post("/api/v1/auth/refresh", json={"refresh_token": old_refresh})
    assert rotated.status_code == 200
    assert rotated.json()["refresh_token"] != old_refresh

    # The used refresh token must no longer work.
    replay = client.post("/api/v1/auth/refresh", json={"refresh_token": old_refresh})
    assert replay.status_code == 401
