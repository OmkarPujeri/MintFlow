"""Test harness: SQLite in-memory DB + fakeredis, no external services.

The app's models use Postgres-only column types (UUID/JSONB). Rather than fight
SQLite to emulate them, we swap those types for portable equivalents (string-UUID
+ generic JSON) *before the models import* — a test-only patch, prod is untouched.
Redis is swapped for fakeredis and the rate limiter is disabled.
"""
import os
import uuid

# Must be set BEFORE importing app.config (Settings reads them at import time).
os.environ.setdefault("DATABASE_URL", "sqlite://")
os.environ.setdefault("SECRET_KEY", "test-secret-key-that-is-at-least-32-chars")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
os.environ.setdefault("ENVIRONMENT", "development")

import sqlalchemy.dialects.postgresql as _pg
from sqlalchemy import JSON, String, types


class _PortableUUID(types.TypeDecorator):
    """String-backed UUID that binds/returns like Postgres UUID(as_uuid=True),
    but works on SQLite. Accepts str or uuid.UUID on the way in."""
    impl = String(36)
    cache_ok = True

    def process_bind_param(self, value, dialect):
        return None if value is None else str(value)

    def process_result_value(self, value, dialect):
        return None if value is None else uuid.UUID(value)


# Models do `from sqlalchemy.dialects.postgresql import UUID, JSONB` and call
# UUID(as_uuid=True) — swap both names to portable types before they import.
_pg.UUID = lambda *a, **k: _PortableUUID()
_pg.JSONB = JSON

import fakeredis
import pytest
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

import app.models  # noqa: F401 — registers every model on Base.metadata
import app.dependencies as deps
import app.api.v1.auth as auth_module
from app.core.rate_limit import limiter
from app.db.database import Base
from app.dependencies import get_db
from app.main import app

# Swap Redis for an in-memory fake and turn off rate limiting for tests.
_fake_redis = fakeredis.FakeStrictRedis(decode_responses=True)
deps.redis_client = _fake_redis
auth_module.redis_client = _fake_redis
limiter.enabled = False

# One shared in-memory SQLite connection (StaticPool) so every session sees the
# same data within a test.
_engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_TestingSessionLocal = sessionmaker(bind=_engine, autoflush=False, autocommit=False)


def _override_get_db():
    db = _TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture()
def client():
    """Fresh schema + empty Redis per test."""
    Base.metadata.create_all(_engine)
    _fake_redis.flushall()
    yield TestClient(app)
    Base.metadata.drop_all(_engine)
