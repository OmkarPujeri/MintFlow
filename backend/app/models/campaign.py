import uuid
import enum
from sqlalchemy import Column, String, Text, Numeric, DateTime, ForeignKey, Integer, Boolean, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base


class CampaignStatus(str, enum.Enum):
    draft = "draft"
    active = "active"
    paused = "paused"
    completed = "completed"


class Campaign(Base):
    __tablename__ = "campaigns"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_admin_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)

    # Video fields — aligned with Flutter frontend model (fallback for single-video)
    youtube_url = Column(String(500), nullable=True)
    youtube_video_id = Column(String(20), nullable=True)

    # Carousel slides
    # Structure: [{"type": "video" | "image", "url": "...", "videoId": "..."}]
    slides = Column(JSONB, nullable=True)

    # Budget & Pricing
    total_budget = Column(Numeric(12, 2), nullable=False)
    remaining_budget = Column(Numeric(12, 2), nullable=False)
    reward_per_view = Column(Numeric(8, 2), nullable=False, default=5.00) # Represented in Coins
    status = Column(SAEnum(CampaignStatus), default=CampaignStatus.draft, nullable=False)

    # CTA Settings
    cta_url = Column(String(500), nullable=True)
    cta_button_text = Column(String(100), nullable=True, default="Learn More")

    # Demographics Targeting
    target_gender = Column(String(50), nullable=True, default="all")  # "all", "male", "female"
    target_age_min = Column(Integer, nullable=True)
    target_age_max = Column(Integer, nullable=True)
    target_locations = Column(JSONB, nullable=True)                  # ["Mumbai", "Delhi"]
    target_interests = Column(JSONB, nullable=True)                  # ["Gaming", "Tech"]

    # Brand Details
    brand_bio = Column(Text, nullable=True)
    brand_website = Column(String(500), nullable=True)
    brand_logo_url = Column(String(500), nullable=True)
    is_boosted = Column(Boolean, default=False, nullable=False)

    # Timestamps
    start_date = Column(DateTime(timezone=True), nullable=True)
    end_date = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    company_admin = relationship("User", backref="campaigns")
    interactions = relationship("CampaignInteraction", back_populates="campaign", cascade="all, delete-orphan")
    watch_sessions = relationship("WatchSession", back_populates="campaign")
