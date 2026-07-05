from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.dependencies import get_db, require_viewer, pagination
from app.models.user import User
from app.models.campaign import Campaign, CampaignStatus
from app.models.watch_session import WatchSession
from app.schemas.campaign import CampaignResponse
from app.services.campaign_serializer import build_campaign_response

router = APIRouter()


@router.get("/", response_model=List[CampaignResponse])
def get_feed(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer),
    page: tuple[int, int] = Depends(pagination),
):
    """Get active campaigns for the viewer feed (paginated).

    Excludes campaigns this viewer has already watched (one session per
    viewer/campaign is DB-enforced, so a watched campaign would only 409 on tap).
    Boosted campaigns surface first, then newest.
    """
    limit, offset = page
    watched = db.query(WatchSession.campaign_id).filter(
        WatchSession.viewer_id == current_user.id
    )
    # ponytail: demographic/targeting filter would hook in here (deferred to a later phase).
    campaigns = db.query(Campaign).filter(
        Campaign.status == CampaignStatus.active,
        Campaign.remaining_budget > 0,
        Campaign.id.notin_(watched),
    ).order_by(
        Campaign.is_boosted.desc(),
        Campaign.created_at.desc(),
    ).offset(offset).limit(limit).all()

    return [build_campaign_response(c, db) for c in campaigns]
