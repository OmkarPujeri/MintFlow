from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.dependencies import get_db, require_viewer
from app.models.user import User
from app.models.watch_session import WatchSession, WatchSessionStatus
from app.models.campaign import Campaign, CampaignStatus
from app.models.campaign_interaction import CampaignInteraction, InteractionType
from app.models.interaction_response import InteractionResponse
from app.models.wallet import Wallet, WalletTransaction, TransactionType
from app.core.constants import MIN_WATCH_PERCENTAGE
import uuid

router = APIRouter()


@router.post("/claim/{session_id}")
def claim_reward(
    session_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_viewer)
):
    # Fetch session
    session = db.query(WatchSession).filter(
        WatchSession.id == session_id,
        WatchSession.viewer_id == current_user.id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Watch session not found")

    # Rule 1: Not already rewarded
    if session.status == WatchSessionStatus.rewarded:
        raise HTTPException(status_code=400, detail="Reward already claimed for this session")

    # Rule 2: Session must be completed
    if session.status != WatchSessionStatus.completed:
        raise HTTPException(status_code=400, detail="Watch the full video before claiming reward")

    # Rule 3: Watch percentage >= 80%
    if float(session.watch_percentage) < MIN_WATCH_PERCENTAGE:
        raise HTTPException(status_code=400, detail=f"Must watch at least {MIN_WATCH_PERCENTAGE}% to earn reward")

    # Rule 4: Campaign must be active
    campaign = session.campaign
    if campaign.status != CampaignStatus.active:
        raise HTTPException(status_code=400, detail="Campaign is no longer active")

    # Rule 5: Campaign must have budget
    if float(campaign.remaining_budget) < float(campaign.reward_per_view):
        raise HTTPException(status_code=400, detail="Campaign budget exhausted")

    # Rule 6: Check all required interactions are completed
    required_interactions = db.query(CampaignInteraction).filter(
        CampaignInteraction.campaign_id == campaign.id,
        CampaignInteraction.is_required == True
    ).all()

    for interaction in required_interactions:
        question_ids = [q.id for q in interaction.questions]
        if not question_ids:
            continue
        submitted_count = db.query(InteractionResponse).filter(
            InteractionResponse.watch_session_id == session_id,
            InteractionResponse.question_id.in_(question_ids)
        ).count()
        if submitted_count < len(question_ids):
            raise HTTPException(status_code=400, detail="Complete all required interactions before claiming reward")

        # Rule 7: Quiz must be answered correctly
        if interaction.type == InteractionType.quiz:
            wrong = db.query(InteractionResponse).filter(
                InteractionResponse.watch_session_id == session_id,
                InteractionResponse.question_id.in_(question_ids),
                InteractionResponse.is_correct == False
            ).count()
            if wrong > 0:
                raise HTTPException(status_code=400, detail="Incorrect quiz answer. No reward granted.")

    # === ALL RULES PASSED — Grant Reward Atomically ===
    reward_amount = float(campaign.reward_per_view)

    # Deduct from campaign budget
    campaign.remaining_budget = float(campaign.remaining_budget) - reward_amount

    # Auto-complete campaign if budget runs out
    if float(campaign.remaining_budget) <= 0:
        campaign.status = CampaignStatus.completed

    # Credit viewer wallet
    wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id).first()
    wallet.balance = float(wallet.balance) + reward_amount

    # Create transaction record
    transaction = WalletTransaction(
        wallet_id=wallet.id,
        type=TransactionType.reward,
        amount=reward_amount,
        description=f"Reward for watching: {campaign.name}",
        campaign_id=campaign.id,
    )
    db.add(transaction)

    # Mark session as rewarded
    session.status = WatchSessionStatus.rewarded

    db.commit()

    return {
        "message": "Reward claimed successfully!",
        "reward_amount": reward_amount,
        "new_balance": float(wallet.balance)
    }
