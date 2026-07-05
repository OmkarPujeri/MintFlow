from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.dependencies import get_db, require_viewer, pagination
from app.models.user import User
from app.models.campaign import Campaign, CampaignStatus
from app.schemas.campaign import CampaignResponse

router = APIRouter()


@router.get("/", response_model=List[CampaignResponse])
def get_feed(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer),
    page: tuple[int, int] = Depends(pagination),
):
    """Get active campaigns for the viewer feed (paginated)."""
    limit, offset = page
    campaigns = db.query(Campaign).filter(
        Campaign.status == CampaignStatus.active,
        Campaign.remaining_budget > 0,
    ).order_by(Campaign.created_at.desc()).offset(offset).limit(limit).all()

    return campaigns
