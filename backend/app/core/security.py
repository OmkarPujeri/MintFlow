import uuid
from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
import bcrypt
from app.config import settings


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    # jti makes every token unique — two tokens minted in the same second must
    # differ, else rotation would blacklist the freshly-issued one too.
    to_encode.update({"exp": expire, "type": "access", "jti": uuid.uuid4().hex})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh", "jti": uuid.uuid4().hex})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        return None


def remaining_ttl(payload: dict) -> int:
    """Seconds until this token's own expiry (0 if expired / no exp).

    Used as the blacklist TTL so Redis auto-evicts a revocation once the token
    would have expired anyway — the blacklist never grows unbounded.
    """
    exp = payload.get("exp") if payload else None
    if not exp:
        return 0
    return max(0, int(exp - datetime.now(timezone.utc).timestamp()))


if __name__ == "__main__":
    # ponytail: self-check the TTL math instead of a pytest+Redis harness.
    _now = datetime.now(timezone.utc).timestamp()
    assert remaining_ttl({"exp": _now + 100}) > 90
    assert remaining_ttl({"exp": _now - 100}) == 0
    assert remaining_ttl({}) == 0
    assert remaining_ttl(None) == 0
    print("security self-check ok")
