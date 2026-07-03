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
    from datetime import datetime, timezone, date

    # 1. Reset daily coin cap if new day
    today_date = date.today()
    if not current_user.last_earning_reset or current_user.last_earning_reset.date() != today_date:
        current_user.coins_earned_today = 0
        current_user.last_earning_reset = datetime.now(timezone.utc)

    # 2. Update Streak
    if current_user.last_watch_date:
        days_diff = (today_date - current_user.last_watch_date.date()).days
        if days_diff == 1:
            current_user.daily_streak += 1
        elif days_diff > 1:
            current_user.daily_streak = 1
    else:
        current_user.daily_streak = 1
    current_user.last_watch_date = datetime.now(timezone.utc)

    # 3. Calculate multiplier
    multiplier = 1.2 if current_user.daily_streak >= 7 else 1.0
    reward_coins = round(float(campaign.reward_per_view) * multiplier)
    reward_amount_inr = float(campaign.reward_per_view) * 0.75  # brand is charged 0.75 INR per coin

    # Deduct from campaign budget
    campaign.remaining_budget = float(campaign.remaining_budget) - reward_amount_inr

    # Auto-complete campaign if budget runs out
    if float(campaign.remaining_budget) <= 0:
        campaign.status = CampaignStatus.completed

    # 4. Award Coins or Raffle Tickets
    capped = False
    awarded_coins = 0
    awarded_tickets = 0

    if current_user.coins_earned_today >= 50:
        current_user.raffle_tickets += 1
        awarded_tickets = 1
        capped = True
    else:
        remaining_cap = 50 - current_user.coins_earned_today
        if reward_coins > remaining_cap:
            awarded_coins = remaining_cap
            current_user.mint_coins += awarded_coins
            current_user.coins_earned_today = 50
            current_user.raffle_tickets += 1
            awarded_tickets = 1
            capped = True
        else:
            awarded_coins = reward_coins
            current_user.mint_coins += awarded_coins
            current_user.coins_earned_today += awarded_coins

    # Sync wallet balance (in INR terms)
    wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id).first()
    if not wallet:
        wallet = Wallet(user_id=current_user.id, balance=0.0)
        db.add(wallet)
        db.flush()
    
    wallet.balance = float(current_user.mint_coins) * 0.75

    # Create transaction record
    transaction = WalletTransaction(
        wallet_id=wallet.id,
        type=TransactionType.reward,
        amount=float(awarded_coins) * 0.75 if awarded_coins > 0 else 0.0,
        description=f"Earned {awarded_coins} Coins (Raffle: {awarded_tickets}) for watching: {campaign.name}",
        campaign_id=campaign.id,
    )
    db.add(transaction)

    # Mark session as rewarded
    session.status = WatchSessionStatus.rewarded

    db.commit()

    return {
        "message": "Reward claimed successfully!",
        "reward_coins": awarded_coins,
        "raffle_tickets": awarded_tickets,
        "daily_cap_reached": capped,
        "daily_streak": current_user.daily_streak,
        "new_balance_coins": current_user.mint_coins,
        "new_balance_inr": float(wallet.balance),
    }
