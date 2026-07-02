# Import all models here so Alembic can detect them
from app.models.user import User, UserRole
from app.models.company_admin import CompanyAdminProfile
from app.models.campaign import Campaign, CampaignStatus
from app.models.campaign_interaction import CampaignInteraction, InteractionQuestion, InteractionType, QuestionType
from app.models.watch_session import WatchSession, WatchSessionStatus
from app.models.interaction_response import InteractionResponse
from app.models.wallet import Wallet, WalletTransaction, TransactionType
