from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.dependencies import get_db, require_company_admin
from app.models.user import User
from app.models.campaign import Campaign
from app.models.watch_session import WatchSession, WatchSessionStatus
from app.models.interaction_response import InteractionResponse
from app.models.wallet import WalletTransaction
import uuid

router = APIRouter()


@router.get("/campaigns/{campaign_id}")
def campaign_analytics(
    campaign_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_company_admin)
):
    campaign = db.query(Campaign).filter(
        Campaign.id == campaign_id,
        Campaign.company_admin_id == current_user.id
    ).first()

    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")

    total_views = db.query(WatchSession).filter(WatchSession.campaign_id == campaign_id).count()
    completed_views = db.query(WatchSession).filter(
        WatchSession.campaign_id == campaign_id,
        WatchSession.status.in_([WatchSessionStatus.completed, WatchSessionStatus.rewarded])
    ).count()
    rewarded_views = db.query(WatchSession).filter(
        WatchSession.campaign_id == campaign_id,
        WatchSession.status == WatchSessionStatus.rewarded
    ).count()

    total_spent = float(campaign.total_budget) - float(campaign.remaining_budget)
    completion_rate = (completed_views / total_views * 100) if total_views > 0 else 0

    return {
        "campaign_id": str(campaign_id),
        "campaign_name": campaign.name,
        "status": campaign.status,
        "total_budget": float(campaign.total_budget),
        "remaining_budget": float(campaign.remaining_budget),
        "total_spent": total_spent,
        "total_views": total_views,
        "completed_views": completed_views,
        "rewarded_views": rewarded_views,
        "completion_rate": round(completion_rate, 2),
    }


@router.get("/campaigns/{campaign_id}/responses")
def campaign_responses(
    campaign_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_company_admin)
):
    campaign = db.query(Campaign).filter(
        Campaign.id == campaign_id,
        Campaign.company_admin_id == current_user.id
    ).first()

    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")

    sessions = db.query(WatchSession).filter(
        WatchSession.campaign_id == campaign_id
    ).all()

    session_ids = [s.id for s in sessions]
    responses = db.query(InteractionResponse).filter(
        InteractionResponse.watch_session_id.in_(session_ids)
    ).all()

    return {
        "campaign_id": str(campaign_id),
        "total_responses": len(responses),
        "responses": [
            {
                "question_id": str(r.question_id),
                "response_value": r.response_value,
                "is_correct": r.is_correct,
                "responded_at": r.responded_at,
            }
            for r in responses
        ]
    }
