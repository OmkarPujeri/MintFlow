"""Pure-logic tests — no DB/Redis. Guards the token + password primitives."""
from datetime import datetime, timezone
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    remaining_ttl,
)


def test_password_hash_roundtrip():
    h = hash_password("secret123")
    assert h != "secret123"
    assert verify_password("secret123", h)
    assert not verify_password("wrong", h)


def test_access_token_roundtrip():
    payload = decode_token(create_access_token({"sub": "u1", "role": "viewer"}))
    assert payload["sub"] == "u1"
    assert payload["type"] == "access"


def test_refresh_token_type():
    payload = decode_token(create_refresh_token({"sub": "u1", "role": "viewer"}))
    assert payload["type"] == "refresh"


def test_decode_garbage_returns_none():
    assert decode_token("not-a-jwt") is None


def test_remaining_ttl():
    now = datetime.now(timezone.utc).timestamp()
    assert remaining_ttl({"exp": now + 100}) > 90
    assert remaining_ttl({"exp": now - 100}) == 0
    assert remaining_ttl({}) == 0
    assert remaining_ttl(None) == 0
