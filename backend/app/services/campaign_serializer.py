"""Shared Campaign ORM → CampaignResponse serializer.

Used by both the company dashboard (campaigns.py) and the viewer feed (feed.py)
so the two never drift. Computes views/completions and flattens interactions to
the shape the Flutter clients expect.
"""
from sqlalchemy.orm import Session

from app.models.campaign import Campaign
from app.models.watch_session import WatchSession, WatchSessionStatus
from app.schemas.campaign import CampaignResponse, InteractionOut, SlideCreate


def build_campaign_response(campaign: Campaign, db: Session) -> CampaignResponse:
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
            questionId=str(question.id) if question else None,
            options=question.options or [] if question else [],
            correctAnswer=question.correct_option if question else None,
        ))

    # Serialize slides
    slides_out = []
    if campaign.slides:
        for s in campaign.slides:
            slides_out.append(SlideCreate(
                type=s.get("type", "video"),
                url=s.get("url", ""),
                videoId=s.get("videoId"),
            ))
    elif campaign.youtube_url:
        slides_out.append(SlideCreate(
            type="video",
            url=campaign.youtube_url,
            videoId=campaign.youtube_video_id,
        ))

    return CampaignResponse(
        id=str(campaign.id),
        name=campaign.name,
        description=campaign.description or "",
        youtubeUrl=campaign.youtube_url or "",
        youtubeVideoId=campaign.youtube_video_id or "",
        slides=slides_out,
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
        # CTA Settings
        ctaUrl=campaign.cta_url,
        ctaButtonText=campaign.cta_button_text or "Learn More",
        # Demographics Targeting
        targetGender=campaign.target_gender or "all",
        targetAgeMin=campaign.target_age_min,
        targetAgeMax=campaign.target_age_max,
        targetLocations=campaign.target_locations or [],
        targetInterests=campaign.target_interests or [],
        # Brand Details & Boosting
        brandBio=campaign.brand_bio or "",
        brandWebsite=campaign.brand_website or "",
        brandLogoUrl=campaign.brand_logo_url or "",
        isBoosted=campaign.is_boosted,
    )
