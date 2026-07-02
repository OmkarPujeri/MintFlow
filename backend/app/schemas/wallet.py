from pydantic import BaseModel
from app.models.wallet import TransactionType
from typing import Optional
from datetime import datetime
import uuid


class WalletOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    balance: float
    updated_at: datetime

    class Config:
        from_attributes = True


class TransactionOut(BaseModel):
    id: uuid.UUID
    type: TransactionType
    amount: float
    description: Optional[str]
    campaign_id: Optional[uuid.UUID]
    created_at: datetime

    class Config:
        from_attributes = True
