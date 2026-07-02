from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


# ─── Interaction Schemas (flat format matching Flutter frontend) ───────────────

class InteractionCreate(BaseModel):
    """Flat interaction format matching the Flutter frontend CampaignInteraction model."""
    type: str                             # "quiz" | "survey" | "poll" | "feedback"
    question: str
    options: List[str] = []
    correctAnswer: Optional[str] = None  # camelCase to match frontend toJson()


class InteractionOut(BaseModel):
    type: str
    question: str
    options: List[str] = []
    correctAnswer: Optional[str] = None


# ─── Campaign Schemas (field names exactly matching Flutter Campaign model) ────

class CampaignCreate(BaseModel):
    """
    Create payload — field names match Flutter Campaign.toJson() exactly.
    Frontend sends these directly from the Create Campaign form.
    """
    name: str
    description: str = ""
    youtubeUrl: str                       # full YouTube URL (any format)
    youtubeVideoId: str                   # extracted 11-char video ID
    budget: float                         # stored as total_budget in DB
    rewardPerCompletion: float = 2.0      # stored as reward_per_view in DB
    startDate: datetime
    endDate: datetime
    interactions: List[InteractionCreate] = []


class CampaignUpdate(BaseModel):
    """Partial update — all fields optional. Used by edit campaign form."""
    name: Optional[str] = None
    description: Optional[str] = None
    youtubeUrl: Optional[str] = None
    youtubeVideoId: Optional[str] = None
    budget: Optional[float] = None
    rewardPerCompletion: Optional[float] = None
    startDate: Optional[datetime] = None
    endDate: Optional[datetime] = None
    status: Optional[str] = None
    interactions: Optional[List[InteractionCreate]] = None


class CampaignResponse(BaseModel):
    """
    Response shape — matches Flutter Campaign.fromJson() exactly.
    Includes views and completions computed from watch_sessions table.
    Analytics repo derives all dashboard metrics from these fields.
    """
    id: str
    name: str
    description: str
    youtubeUrl: str
    youtubeVideoId: str
    budget: float
    rewardPerCompletion: float
    remainingBudget: float
    startDate: datetime
    endDate: datetime
    status: str                           # "draft" | "active" | "paused" | "completed"
    interactions: List[InteractionOut] = []
    views: int = 0                        # total watch sessions started
    completions: int = 0                  # sessions that reached rewarded status
    createdAt: datetime
