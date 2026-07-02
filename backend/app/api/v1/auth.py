from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.dependencies import get_db, get_current_user, redis_client
from app.models.user import User, UserRole
from app.models.wallet import Wallet
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.schemas.auth import RegisterRequest, LoginRequest, RegisterResponse, LoginResponse, RefreshRequest
from app.config import settings
from datetime import timedelta

router = APIRouter()


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    user = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        role=UserRole(payload.role),
    )
    db.add(user)
    db.flush()

    # Auto-create wallet for viewers
    if payload.role == "viewer":
        wallet = Wallet(user_id=user.id, balance=0.00)
        db.add(wallet)

    db.commit()
    db.refresh(user)
    return RegisterResponse(
        id=str(user.id),
        email=user.email,
        role=user.role,
        message="Account created successfully"
    )


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()

    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token({"sub": str(user.id), "role": user.role})

    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        id=str(user.id),
        email=user.email,
        name="Company Admin",            # Will be updated when profile feature is added
        companyName="My Brand",          # Will be updated when profile feature is added
        role=user.role,
    )


@router.post("/refresh")
def refresh_token(payload: RefreshRequest):
    token_data = decode_token(payload.refresh_token)
    if not token_data or token_data.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    if redis_client.get(f"blacklist:{payload.refresh_token}"):
        raise HTTPException(status_code=401, detail="Refresh token has been revoked")

    new_access_token = create_access_token({
        "sub": token_data["sub"],
        "role": token_data["role"]
    })
    return {"access_token": new_access_token, "token_type": "bearer"}


@router.post("/logout")
def logout(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return {"message": "Logged out successfully"}
