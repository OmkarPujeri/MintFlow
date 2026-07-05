"""Shared rate limiter.

Defined in its own module so both main.py (to register the handler) and the
routers (to decorate endpoints) can import the same Limiter without a circular
import. Backed by Redis so limits are enforced consistently across workers.
"""
from slowapi import Limiter
from slowapi.util import get_remote_address
from app.config import settings

limiter = Limiter(
    key_func=get_remote_address,
    storage_uri=settings.REDIS_URL,
)
