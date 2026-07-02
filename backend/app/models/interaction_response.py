import uuid
from sqlalchemy import Column, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base


class InteractionResponse(Base):
    __tablename__ = "interaction_responses"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    watch_session_id = Column(UUID(as_uuid=True), ForeignKey("watch_sessions.id"), nullable=False)
    question_id = Column(UUID(as_uuid=True), ForeignKey("interaction_questions.id"), nullable=False)
    viewer_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    response_value = Column(Text, nullable=True)
    is_correct = Column(Boolean, nullable=True)   # None for non-quiz
    responded_at = Column(DateTime(timezone=True), server_default=func.now())

    watch_session = relationship("WatchSession", back_populates="responses")
    question = relationship("InteractionQuestion")
    viewer = relationship("User")
