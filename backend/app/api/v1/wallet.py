from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.dependencies import get_db, require_viewer, pagination
from app.models.user import User
from app.models.wallet import Wallet, WalletTransaction
from app.schemas.wallet import WalletOut, TransactionOut

router = APIRouter()


@router.get("/", response_model=WalletOut)
def get_wallet(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer)
):
    wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id).first()
    return wallet


@router.get("/transactions", response_model=List[TransactionOut])
def get_transactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer),
    page: tuple[int, int] = Depends(pagination),
):
    limit, offset = page
    wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id).first()
    transactions = db.query(WalletTransaction).filter(
        WalletTransaction.wallet_id == wallet.id
    ).order_by(WalletTransaction.created_at.desc()).offset(offset).limit(limit).all()
    return transactions
