from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from app.dependencies import get_db, require_company_admin
from app.models.user import User
from app.models.campaign import Campaign, CampaignStatus
from app.models.campaign_interaction import CampaignInteraction, InteractionType, InteractionQuestion, QuestionType
from app.models.watch_session import WatchSession, WatchSessionStatus
from app.schemas.campaign import CampaignCreate, CampaignUpdate, CampaignResponse, InteractionOut
import uuid

router = APIRouter()


def _build_campaign_response(campaign: Campaign, db: Session) -> CampaignResponse:
    """Convert Campaign ORM object → CampaignResponse, computing views & completions."""
    views = db.query(WatchSession).filter(WatchSession.campaign_id == campaign.id).count()
    completions = db.query(WatchSession).filter(
        WatchSession.campaign_id == campaign.id,
        WatchSession.status == WatchSessionStatus.rewarded
    ).count()

    # Build flat interactions list (matching Flutter CampaignInteraction model)
    interactions_out = []
    for interaction in campaign.interactions:
        # Take first question from each interaction (flat structure)
        question = interaction.questions[0] if interaction.questions else None
        interactions_out.append(InteractionOut(
            type=interaction.type.value,
            question=question.question_text if question else interaction.type.value,
            options=question.options or [] if question else [],
            correctAnswer=question.correct_option if question else None,
        ))

    return CampaignResponse(
        id=str(campaign.id),
        name=campaign.name,
        description=campaign.description or "",
        youtubeUrl=campaign.youtube_url or "",
        youtubeVideoId=campaign.youtube_video_id or "",
        budget=float(campaign.total_budget),
        rewardPerCompletion=float(campaign.reward_per_view),
        remainingBudget=float(campaign.remaining_budget),
        startDate=campaign.start_date,
        endDate=campaign.end_date,
        status=campaign.status.value,
        interactions=interactions_out,
        views=views,
        completions=completions,
        createdAt=campaign.created_at,
    )


def _save_interactions(campaign_id, interactions_data: list, db: Session):
    """Delete old interactions and save new flat interactions for a campaign."""
    # Remove existing interactions
    db.query(CampaignInteraction).filter(
        CampaignInteraction.campaign_id == campaign_id
    ).delete()

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
    campaign = Campaign(
        company_admin_id=current_user.id,
        name=payload.name,
        description=payload.description,
        youtube_url=payload.youtubeUrl,
        youtube_video_id=payload.youtubeVideoId,
        total_budget=payload.budget,
        remaining_budget=payload.budget,
        reward_per_view=payload.rewardPerCompletion,
        start_date=payload.startDate,
        end_date=payload.endDate,
        status=CampaignStatus.draft,
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
    current_user: User = Depends(require_company_admin)
):
    campaigns = db.query(Campaign).filter(
        Campaign.company_admin_id == current_user.id
    ).order_by(Campaign.created_at.desc()).all()
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

    # Map frontend field names → DB field names
    field_map = {
        "name": "name",
        "description": "description",
        "youtubeUrl": "youtube_url",
        "youtubeVideoId": "youtube_video_id",
        "budget": "total_budget",
        "rewardPerCompletion": "reward_per_view",
        "startDate": "start_date",
        "endDate": "end_date",
    }
    data = payload.model_dump(exclude_unset=True)
    for frontend_key, db_key in field_map.items():
        if frontend_key in data:
            setattr(campaign, db_key, data[frontend_key])

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
