from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from app.dependencies import get_db, require_company_admin, pagination
from app.models.user import User
from app.models.campaign import Campaign, CampaignStatus
from app.models.campaign_interaction import CampaignInteraction, InteractionType, InteractionQuestion, QuestionType
from app.models.watch_session import WatchSession, WatchSessionStatus
from app.schemas.campaign import CampaignCreate, CampaignUpdate, CampaignResponse, InteractionOut, SlideCreate
from app.services.campaign_serializer import build_campaign_response as _build_campaign_response
import uuid

router = APIRouter()


def _save_interactions(campaign_id, interactions_data: list, db: Session):
    """Delete old interactions and save new flat interactions for a campaign."""
    existing = db.query(CampaignInteraction).filter(
        CampaignInteraction.campaign_id == campaign_id
    ).all()
    for item in existing:
        db.delete(item)
    db.flush()

    for item in interactions_data:
        interaction = CampaignInteraction(
            campaign_id=campaign_id,
            type=InteractionType(item.type),
            title=item.question[:255],
            is_required=True,
        )
        db.add(interaction)
        db.flush()

        # Store as a single question per interaction (flat frontend structure)
        question = InteractionQuestion(
            interaction_id=interaction.id,
            question_text=item.question,
            question_type=QuestionType.multiple_choice if item.options else QuestionType.text,
            options=item.options if item.options else None,
            correct_option=item.correctAnswer,
            sequence=0,
        )
        db.add(question)


# ─── Routes ──────────────────────────────────────────────────────────────────

@router.post("/", response_model=CampaignResponse, status_code=status.HTTP_201_CREATED)
def create_campaign(
    payload: CampaignCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_company_admin)
):
    slides_db = [s.model_dump() for s in payload.slides]
    youtube_url_val = payload.youtubeUrl or ""
    youtube_video_id_val = payload.youtubeVideoId or ""
    if not slides_db and youtube_url_val:
        slides_db = [{"type": "video", "url": youtube_url_val, "videoId": youtube_video_id_val}]
    elif slides_db and not youtube_url_val:
        first_video = next((s for s in slides_db if s["type"] == "video"), None)
        if first_video:
            youtube_url_val = first_video["url"]
            youtube_video_id_val = first_video["videoId"]

    campaign = Campaign(
        company_admin_id=current_user.id,
        name=payload.name,
        description=payload.description,
        youtube_url=youtube_url_val,
        youtube_video_id=youtube_video_id_val,
        slides=slides_db,
        total_budget=payload.budget,
        remaining_budget=payload.budget,
        reward_per_view=payload.rewardPerCompletion,
        start_date=payload.startDate,
        end_date=payload.endDate,
        status=CampaignStatus.draft,
        # CTA Settings
        cta_url=payload.ctaUrl,
        cta_button_text=payload.ctaButtonText or "Learn More",
        # Demographics Targeting
        target_gender=payload.targetGender or "all",
        target_age_min=payload.targetAgeMin,
        target_age_max=payload.targetAgeMax,
        target_locations=payload.targetLocations,
        target_interests=payload.targetInterests,
        # Brand Details
        brand_bio=payload.brandBio,
        brand_website=payload.brandWebsite,
        brand_logo_url=payload.brandLogoUrl,
    )
    db.add(campaign)
    db.flush()

    if payload.interactions:
        _save_interactions(campaign.id, payload.interactions, db)

    db.commit()
    db.refresh(campaign)
    return _build_campaign_response(campaign, db)


@router.get("/", response_model=List[CampaignResponse])
def list_campaigns(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_company_admin),
    page: tuple[int, int] = Depends(pagination),
):
    limit, offset = page
    campaigns = db.query(Campaign).filter(
        Campaign.company_admin_id == current_user.id
    ).order_by(Campaign.created_at.desc()).offset(offset).limit(limit).all()
    return [_build_campaign_response(c, db) for c in campaigns]


@router.get("/{campaign_id}", response_model=CampaignResponse)
def get_campaign(
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
    return _build_campaign_response(campaign, db)


@router.patch("/{campaign_id}", response_model=CampaignResponse)
def update_campaign(
    campaign_id: uuid.UUID,
    payload: CampaignUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_company_admin)
):
    campaign = db.query(Campaign).filter(
        Campaign.id == campaign_id,
        Campaign.company_admin_id == current_user.id
    ).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")

    field_map = {
        "name": "name",
        "description": "description",
        "youtubeUrl": "youtube_url",
        "youtubeVideoId": "youtube_video_id",
        "budget": "total_budget",
        "rewardPerCompletion": "reward_per_view",
        "startDate": "start_date",
        "endDate": "end_date",
        "ctaUrl": "cta_url",
        "ctaButtonText": "cta_button_text",
        "targetGender": "target_gender",
        "targetAgeMin": "target_age_min",
        "targetAgeMax": "target_age_max",
        "targetLocations": "target_locations",
        "targetInterests": "target_interests",
        "brandBio": "brand_bio",
        "brandWebsite": "brand_website",
        "brandLogoUrl": "brand_logo_url",
        "isBoosted": "is_boosted",
    }
    data = payload.model_dump(exclude_unset=True)
    for frontend_key, db_key in field_map.items():
        if frontend_key in data:
            setattr(campaign, db_key, data[frontend_key])

    # Handle slides update
    if "slides" in data:
        slides_db = [s.model_dump() for s in payload.slides] if payload.slides is not None else []
        campaign.slides = slides_db
        first_video = next((s for s in slides_db if s["type"] == "video"), None)
        if first_video:
            campaign.youtube_url = first_video["url"]
            campaign.youtube_video_id = first_video["videoId"]

    # Handle budget update — also reset remaining_budget proportionally
    if "budget" in data:
        spent = float(campaign.total_budget) - float(campaign.remaining_budget)
        campaign.remaining_budget = max(0, data["budget"] - spent)
        campaign.total_budget = data["budget"]

    # Handle status update
    if "status" in data:
        campaign.status = CampaignStatus(data["status"])

    # Handle interactions update
    if payload.interactions is not None:
        _save_interactions(campaign.id, payload.interactions, db)

    db.commit()
    db.refresh(campaign)
    return _build_campaign_response(campaign, db)


@router.post("/{campaign_id}/publish", response_model=CampaignResponse)
def publish_campaign(
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
    if not campaign.youtube_url:
        raise HTTPException(status_code=400, detail="Campaign must have a YouTube URL before publishing")
    campaign.status = CampaignStatus.active
    db.commit()
    db.refresh(campaign)
    return _build_campaign_response(campaign, db)


@router.post("/{campaign_id}/pause", response_model=CampaignResponse)
def pause_campaign(
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
    campaign.status = CampaignStatus.paused
    db.commit()
    db.refresh(campaign)
    return _build_campaign_response(campaign, db)


@router.delete("/{campaign_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_campaign(
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
    db.delete(campaign)
    db.commit()


@router.post("/{campaign_id}/boost", response_model=CampaignResponse)
def boost_campaign(
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

    campaign.is_boosted = True
    db.commit()
    db.refresh(campaign)
    return _build_campaign_response(campaign, db)
