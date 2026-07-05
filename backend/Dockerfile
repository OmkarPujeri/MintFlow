# Backend image for MintFlow API.
# Build context is the REPO ROOT (see docker-compose.yml) so alembic.ini and
# the migrations under backend/ are both available for `alembic upgrade head`.
FROM python:3.13-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install dependencies first for better layer caching.
COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

# App code + alembic config. The backend/ prefix is preserved so the paths in
# alembic.ini (script_location = backend/app/db/migrations) resolve from /app.
COPY backend/ /app/backend/
COPY alembic.ini /app/alembic.ini

# uvicorn imports `app.main:app`, so run from the backend package root.
WORKDIR /app/backend

EXPOSE 8000

# Default: run the API under Gunicorn with uvicorn workers (multi-process, so
# one blocking request doesn't stall the whole API). WEB_CONCURRENCY sets the
# worker count; hosts usually inject it, else Gunicorn defaults to 1.
# docker-compose overrides this to run migrations first.
CMD ["gunicorn", "app.main:app", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
