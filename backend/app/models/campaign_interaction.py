import uuid
import enum
from sqlalchemy import Column, String, Text, Boolean, Integer, ForeignKey, Enum as SAEnum, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base


class InteractionType(str, enum.Enum):
    quiz = "quiz"
    survey = "survey"
    poll = "poll"
    feedback = "feedback"


class QuestionType(str, enum.Enum):
    multiple_choice = "multiple_choice"
    rating = "rating"
    text = "text"


class CampaignInteraction(Base):
    __tablename__ = "campaign_interactions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    campaign_id = Column(UUID(as_uuid=True), ForeignKey("campaigns.id"), nullable=False)
    type = Column(SAEnum(InteractionType), nullable=False)
    title = Column(String(255), nullable=True)
    is_required = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    campaign = relationship("Campaign", back_populates="interactions")
    questions = relationship("InteractionQuestion", back_populates="interaction", cascade="all, delete-orphan")


class InteractionQuestion(Base):
    __tablename__ = "interaction_questions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    interaction_id = Column(UUID(as_uuid=True), ForeignKey("campaign_interactions.id"), nullable=False)
    question_text = Column(Text, nullable=False)
    question_type = Column(SAEnum(QuestionType), nullable=False)
    options = Column(JSONB, nullable=True)         # ["Option A", "Option B"]
    correct_option = Column(String(100), nullable=True)  # Only for quiz
    sequence = Column(Integer, default=0)

    interaction = relationship("CampaignInteraction", back_populates="questions")
