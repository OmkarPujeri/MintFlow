from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from app.config import settings
from app.core.rate_limit import limiter
from app.api.v1 import auth, campaigns, feed, watch, interactions, rewards, wallet, analytics

app = FastAPI(
    title="MintFlow API",
    description="Verified Attention Network Backend",
    version="1.0.0",
)

# Rate limiting (Redis-backed). Endpoints opt in via @limiter.limit(...).
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Middleware — explicit allowlist. In non-production we also permit any
# localhost port for developer convenience; production is locked to the
# configured origins only.
cors_kwargs = dict(
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)
if not settings.is_production:
    cors_kwargs["allow_origin_regex"] = r"https?://(localhost|127\.0\.0\.1)(:\d+)?"

app.add_middleware(CORSMiddleware, **cors_kwargs)

# Routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(campaigns.router, prefix="/api/v1/campaigns", tags=["Campaigns"])
app.include_router(feed.router, prefix="/api/v1/feed", tags=["Feed"])
app.include_router(watch.router, prefix="/api/v1/watch", tags=["Watch Sessions"])
app.include_router(interactions.router, prefix="/api/v1/interactions", tags=["Interactions"])
app.include_router(rewards.router, prefix="/api/v1/rewards", tags=["Rewards"])
app.include_router(wallet.router, prefix="/api/v1/wallet", tags=["Wallet"])
app.include_router(analytics.router, prefix="/api/v1/analytics", tags=["Analytics"])


@app.get("/", tags=["Health"])
def root():
    return {"message": "MintFlow API is running 🚀", "version": "1.0.0"}


@app.get("/health", tags=["Health"])
def health():
    return {"status": "healthy"}
