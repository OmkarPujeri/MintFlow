from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from app.dependencies import get_db, require_viewer
from app.models.user import User
from app.models.campaign import Campaign, CampaignStatus
from app.models.watch_session import WatchSession, WatchSessionStatus
from app.schemas.watch_session import WatchStartRequest, WatchProgressRequest, WatchSessionOut
from app.core.constants import MIN_WATCH_PERCENTAGE
import uuid
from datetime import datetime, timezone

router = APIRouter()


@router.post("/start", response_model=WatchSessionOut, status_code=201)
def start_watch(
    payload: WatchStartRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer)
):
    campaign = db.query(Campaign).filter(
        Campaign.id == payload.campaign_id,
        Campaign.status == CampaignStatus.active
    ).first()

    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found or not active")

    if float(campaign.remaining_budget) < float(campaign.reward_per_view):
        raise HTTPException(status_code=400, detail="Campaign budget exhausted")

    # Check for existing session (duplicate guard)
    existing = db.query(WatchSession).filter(
        WatchSession.viewer_id == current_user.id,
        WatchSession.campaign_id == payload.campaign_id
    ).first()

    if existing:
        raise HTTPException(status_code=409, detail="You have already watched this campaign")

    session = WatchSession(
        viewer_id=current_user.id,
        campaign_id=payload.campaign_id,
        status=WatchSessionStatus.started,
        watch_percentage=0.00,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.patch("/{session_id}/progress", response_model=WatchSessionOut)
def update_progress(
    session_id: uuid.UUID,
    payload: WatchProgressRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer)
):
    session = db.query(WatchSession).filter(
        WatchSession.id == session_id,
        WatchSession.viewer_id == current_user.id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Watch session not found")

    if session.status == WatchSessionStatus.rewarded:
        raise HTTPException(status_code=400, detail="Session already rewarded")

    session.watch_percentage = max(float(session.watch_percentage), payload.watch_percentage)
    db.commit()
    db.refresh(session)
    return session


@router.post("/{session_id}/complete", response_model=WatchSessionOut)
def complete_watch(
    session_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer)
):
    session = db.query(WatchSession).filter(
        WatchSession.id == session_id,
        WatchSession.viewer_id == current_user.id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Watch session not found")

    if float(session.watch_percentage) < MIN_WATCH_PERCENTAGE:
        raise HTTPException(
            status_code=400,
            detail=f"Must watch at least {MIN_WATCH_PERCENTAGE}% of the video"
        )

    session.status = WatchSessionStatus.completed
    session.completed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(session)
    return session
