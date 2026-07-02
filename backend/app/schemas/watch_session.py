from pydantic import BaseModel
from app.models.watch_session import WatchSessionStatus
from typing import Optional
from datetime import datetime
import uuid


class WatchStartRequest(BaseModel):
    campaign_id: uuid.UUID


class WatchProgressRequest(BaseModel):
    watch_percentage: float


class WatchSessionOut(BaseModel):
    id: uuid.UUID
    viewer_id: uuid.UUID
    campaign_id: uuid.UUID
    watch_percentage: float
    status: WatchSessionStatus
    started_at: datetime
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True
