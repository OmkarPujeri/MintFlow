from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException, Query, status
from fastapi.security import OAuth2PasswordBearer
from app.db.database import SessionLocal
from app.core.security import decode_token, remaining_ttl
from app.models.user import User, UserRole
import redis
from app.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)


def blacklist_token(token: str) -> None:
    """Revoke a JWT until its natural expiry. No-op for undecodable/expired tokens."""
    ttl = remaining_ttl(decode_token(token))
    if ttl > 0:
        redis_client.set(f"blacklist:{token}", "1", ex=ttl)


def pagination(
    limit: int = Query(50, ge=1, le=100, description="Max items to return"),
    offset: int = Query(0, ge=0, description="Items to skip"),
) -> tuple[int, int]:
    """Shared list pagination. Bounds enforced by Query so a caller can't ask
    for an unbounded page. Returns (limit, offset)."""
    return limit, offset


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    # Check if token is blacklisted in Redis
    if redis_client.get(f"blacklist:{token}"):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has been revoked")

    payload = decode_token(token)
    if not payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()

    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")

    return user


def require_viewer(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.viewer:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Viewer access required")
    return current_user


def require_company_admin(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.company_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Company admin access required")
    return current_user
