from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.dependencies import get_db, require_viewer
from app.models.user import User
from app.models.watch_session import WatchSession, WatchSessionStatus
from app.models.campaign_interaction import CampaignInteraction, InteractionQuestion, InteractionType
from app.models.interaction_response import InteractionResponse
from app.schemas.interaction import SubmitInteractionRequest
import uuid

router = APIRouter()


@router.post("/{session_id}/submit")
def submit_responses(
    session_id: uuid.UUID,
    payload: SubmitInteractionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer)
):
    session = db.query(WatchSession).filter(
        WatchSession.id == session_id,
        WatchSession.viewer_id == current_user.id,
        WatchSession.status == WatchSessionStatus.completed
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Watch session not found or not completed yet")

    for answer in payload.answers:
        question = db.query(InteractionQuestion).filter(
            InteractionQuestion.id == answer.question_id
        ).first()

        if not question:
            raise HTTPException(status_code=404, detail=f"Question {answer.question_id} not found")

        # Check if already answered
        existing = db.query(InteractionResponse).filter(
            InteractionResponse.watch_session_id == session_id,
            InteractionResponse.question_id == answer.question_id
        ).first()

        if existing:
            continue  # Skip already answered questions

        # Determine if correct (only for quiz)
        is_correct = None
        if question.correct_option:
            is_correct = (answer.response_value == question.correct_option)

        response = InteractionResponse(
            watch_session_id=session_id,
            question_id=answer.question_id,
            viewer_id=current_user.id,
            response_value=answer.response_value,
            is_correct=is_correct,
        )
        db.add(response)

    db.commit()
    return {"message": "Responses submitted successfully"}
