import uuid
import enum
from sqlalchemy import Column, Numeric, DateTime, ForeignKey, Enum as SAEnum, UniqueConstraint, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base


class WatchSessionStatus(str, enum.Enum):
    started = "started"
    completed = "completed"
    rewarded = "rewarded"


class WatchSession(Base):
    __tablename__ = "watch_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    viewer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaigns.id"), nullable=False)
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)
    watch_percentage = Column(Numeric(5, 2), default=0.00)
    cta_clicked = Column(Boolean, default=False, nullable=False)
    status = Column(SAEnum(WatchSessionStatus), default=WatchSessionStatus.started, nullable=False)

    __table_args__ = (
        UniqueConstraint("viewer_id", "campaign_id", name="uq_viewer_campaign"),
    )

    viewer = relationship("User", backref="watch_sessions")
    campaign = relationship("Campaign", back_populates="watch_sessions")
    responses = relationship("InteractionResponse", back_populates="watch_session")
