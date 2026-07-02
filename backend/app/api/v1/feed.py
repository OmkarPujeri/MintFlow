from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.dependencies import get_db, require_viewer
from app.models.user import User
from app.models.campaign import Campaign, CampaignStatus
from app.schemas.campaign import CampaignResponse
from datetime import date

router = APIRouter()


@router.get("/", response_model=List[CampaignResponse])
def get_feed(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer)
):
    """Get all active campaigns for viewer feed."""
    today = date.today()
    campaigns = db.query(Campaign).filter(
        Campaign.status == CampaignStatus.active,
        Campaign.remaining_budget > 0,
    ).order_by(Campaign.created_at.desc()).all()

    return campaigns
