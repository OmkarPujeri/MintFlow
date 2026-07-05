import logging
import time
from fastapi import FastAPI, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from app.config import settings
from app.core.rate_limit import limiter
from app.core.logging_config import configure_logging
from app.db.database import SessionLocal
from app.dependencies import redis_client
from app.api.v1 import auth, campaigns, feed, watch, interactions, rewards, wallet, analytics

configure_logging()
logger = logging.getLogger("mintflow")

# Sentry captures unhandled exceptions (auto-instruments FastAPI when installed).
# No-op unless SENTRY_DSN is set, so dev/local runs stay clean.
if settings.SENTRY_DSN:
    import sentry_sdk
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        environment=settings.ENVIRONMENT,
        traces_sample_rate=0.0,  # errors only; enable perf tracing later if needed
    )

app = FastAPI(
    title="MintFlow API",
    description="Verified Attention Network Backend",
    version="1.0.0",
    # In prod DEBUG=False so 500s don't leak stack traces to clients.
    debug=settings.DEBUG,
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


@app.middleware("http")
async def log_requests(request: Request, call_next):
    """One structured line per request. Skips health/root pings so load-balancer
    probes don't drown the logs."""
    if request.url.path in ("/health", "/"):
        return await call_next(request)
    start = time.monotonic()
    response = await call_next(request)
    logger.info(
        "request",
        extra={
            "method": request.method,
            "path": request.url.path,
            "status": response.status_code,
            "duration_ms": round((time.monotonic() - start) * 1000, 1),
        },
    )
    return response

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
def health(response: Response):
    """Deep check: DB + Redis must both answer or the pod is unhealthy (503),
    so load balancers pull it out of rotation instead of routing to a broken API."""
    checks = {}
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        checks["database"] = "ok"
    except Exception:
        checks["database"] = "down"
    try:
        redis_client.ping()
        checks["redis"] = "ok"
    except Exception:
        checks["redis"] = "down"

    healthy = all(v == "ok" for v in checks.values())
    if not healthy:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    return {"status": "healthy" if healthy else "unhealthy", "checks": checks}
