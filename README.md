<div align="center">

<img src="assets/brand_logo.svg" alt="MintFlow" width="120" />

# MintFlow

**A verified-attention ad network — brands pay for watched, rewarded views.**

Company-admin dashboard in **Flutter Web**, backed by a **FastAPI + PostgreSQL + Redis** API.

<br />

![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Python_3.13-009688?logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-7-DC382D?logo=redis&logoColor=white)
![Docker](https://img.shields.io/badge/Docker_Compose-ready-2496ED?logo=docker&logoColor=white)
![Tests](https://img.shields.io/badge/tests-16_passing-brightgreen)
![Status](https://img.shields.io/badge/status-pre--launch-orange)

[**Setup Guide**](SETUP.md) · [**Deployment**](DEPLOYMENT.md) · [**API Contract**](API_CONTRACT.md) · [**PRD**](PRD.md)

</div>

---

## Contents

- [What is MintFlow](#what-is-mintflow)
- [Features](#features)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Testing](#testing)
- [Deployment](#deployment)
- [Project structure](#project-structure)
- [Roadmap](#roadmap)

---

## What is MintFlow

MintFlow is a **verified attention network**: companies fund video campaigns,
viewers watch and complete interactions (quiz / survey / poll / feedback), and
earn coin rewards for genuine, verified attention. This repo is the **company
admin dashboard** — create and manage campaigns, configure interactions, review
responses, and track reward spend — plus the full backend that powers it.

> The mobile **viewer** app is a later phase. Campaign videos are YouTube URLs
> today (the app stores both the URL and the extracted video ID).

---

## Features

| | |
|---|---|
| 📊 **Overview** | Animated KPI cards (count-up), completion-trend area chart, interaction-mix donut, spend-by-campaign bars. |
| 🎯 **Campaigns** | Live search + status filter chips; edit, pause/resume, complete, duplicate, delete (confirm dialog + toasts). |
| ✏️ **Create / Edit** | One sectioned, validated form for both, with a live phone preview of the viewer experience. |
| 💬 **Interactions / Responses / Spend** | Task cards, response-mix donut, budget-health gauge, spend trend, reward transactions. |
| ⚙️ **Settings** | Editable company profile persisted locally. |
| 🔐 **Auth** | Email/password **and real Google OAuth**, JWT with server-side token revocation. |
| 🖥️ **Responsive shell** | Full sidebar → icon rail → mobile drawer, animated transitions, skeleton loaders, empty states. |

---

## Tech stack

**Frontend** — Flutter Web · `fl_chart` (charts) · `flutter_animate` (motion) ·
`google_fonts` (Plus Jakarta Sans + Inter) · `google_sign_in` (OAuth) · `http`.
State via `ChangeNotifier` (`lib/state/dashboard_controller.dart`) consumed with
`ListenableBuilder` — the UI never touches storage or HTTP directly.

**Backend** — FastAPI (Python 3.13) · SQLAlchemy + Alembic · PostgreSQL 16 ·
Redis 7 (rate limiting + token blacklist) · JWT (python-jose) · Gunicorn +
uvicorn workers · structured JSON logging · optional Sentry.

---

## Architecture

```
┌─────────────────┐      HTTPS / JSON       ┌──────────────────────┐
│  Flutter Web     │  ───────────────────▶  │  FastAPI  /api/v1/…    │
│  dashboard       │  ◀───────────────────  │  auth · campaigns ·    │
│  (lib/)          │      JWT Bearer         │  feed · watch · …      │
└─────────────────┘                         └───────┬──────┬────────┘
                                                    │      │
                                            ┌───────▼─┐  ┌─▼───────┐
                                            │ Postgres │  │  Redis   │
                                            └──────────┘  └─────────┘
```

The Flutter side routes everything through `lib/repositories/`:

- **`ApiClient`** owns the base URL, the JWT Bearer header, and token storage.
- **`AppConfig`** toggles `useBackend`, `apiBaseUrl`, and `googleClientId` — all
  set at build time from **`dart_defines.json`** (via `--dart-define-from-file`).
- Models parse API JSON with their `fromJson` factories.

Backend routes live under `/api/v1/…` (`auth`, `campaigns`, `feed`, `watch`,
`interactions`, `rewards`, `wallet`, `analytics`) — browse them live at
`http://localhost:8000/docs`. With `USE_BACKEND=false` the app falls back to
browser storage and runs with no backend at all.

---

## Quick start

> Full, step-by-step onboarding (Docker, env files, Google Sign-In) is in
> **[SETUP.md](SETUP.md)**. The short version:

**Prerequisites:** Docker Desktop (running) + Flutter SDK 3.44+.

```sh
# 1. Clone
git clone https://github.com/OmkarPujeri/MintFlow.git && cd MintFlow

# 2. Create env files from templates (see SETUP.md §4 for values)
cp .env.example .env
cp backend/.env.example backend/.env

# 3. Backend + Postgres + Redis — one command (migrations auto-run)
docker compose up -d --build

# 4. Frontend — build settings come from dart_defines.json
flutter pub get
flutter run -d chrome --web-port=5173 --dart-define-from-file=dart_defines.json
```

Open **http://localhost:5173** · API docs at **http://localhost:8000/docs**.

```sh
curl http://localhost:8000/health
# -> {"status":"healthy","checks":{"database":"ok","redis":"ok"}}
```

**First login** — the DB starts empty. Register (password: 8+ chars, a letter and
a number), then log in from the UI:

```sh
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@mintflow.com","password":"demo1234","role":"company_admin"}'
```

_(On Windows PowerShell use `curl.exe`.) Or use Google Sign-In once configured._

---

## Configuration

Build/run settings live in **`dart_defines.json`** (repo root) — edit that file
instead of passing long `--dart-define=` flags:

| Key | Purpose |
|-----|---------|
| `USE_BACKEND` | `"false"` = browser-storage demo mode, no backend needed. |
| `API_BASE_URL` | Backend URL (`http://localhost:8000` locally). |
| `GOOGLE_CLIENT_ID` | Web OAuth client ID; empty disables Google login. |

**Google Sign-In** is implemented end-to-end (the backend verifies the Google ID
token at `POST /api/v1/auth/google` before issuing the app JWT). It's off until
you supply your own Web OAuth Client ID in **both** the backend `.env` and
`dart_defines.json` — see **[SETUP.md §5b](SETUP.md)**. The client _secret_ is
never used or committed.

Backend secrets (`SECRET_KEY`, `DATABASE_URL`, …) come from `backend/.env` or
host env vars — see [SETUP.md](SETUP.md) and [DEPLOYMENT.md](DEPLOYMENT.md).

---

## Testing

```sh
# Frontend
flutter analyze
flutter test

# Backend (no DB/Redis needed — SQLite + fakeredis)
cd backend
pip install -r requirements.txt -r requirements-dev.txt
pytest
```

The backend suite (`backend/tests/`) covers the token primitives, the full auth
flow including **logout revocation** and **refresh rotation**, RBAC, and list
**pagination** — 16 tests, zero external services.

---

## Deployment

The code is production-hardened (token revocation, prod config guard, multi-worker
Gunicorn, deep health check, JSON logging + Sentry, pagination). Going live is
mostly **configuration** — managed Postgres/Redis, a container host, a static
frontend host, HTTPS.

**➡️ Full hosting walkthrough, env vars, and the gotchas (worker/DB-connection
sizing, CORS, TLS) are in [DEPLOYMENT.md](DEPLOYMENT.md).**

---

## Project structure

```
MintFlow/
├── lib/                  # Flutter Web app
│   ├── pages/            #   screens (overview, campaigns, create, …)
│   ├── widgets/          #   charts, shell, cards, states
│   ├── repositories/     #   ApiClient + data repos (only layer touching HTTP)
│   ├── state/            #   DashboardController (ChangeNotifier)
│   └── models/           #   JSON-serializable models
├── backend/              # FastAPI service
│   ├── app/
│   │   ├── api/v1/        #   routers: auth, campaigns, feed, watch, …
│   │   ├── models/        #   SQLAlchemy models
│   │   ├── schemas/       #   Pydantic schemas
│   │   ├── core/          #   security, rate limit, logging
│   │   └── db/            #   engine + Alembic migrations
│   └── tests/            #   pytest suite
├── docker-compose.yml    # Postgres + Redis + API
├── dart_defines.json     # frontend build config
├── SETUP.md · DEPLOYMENT.md · API_CONTRACT.md · PRD.md
```

---

## Roadmap

Production-readiness is tracked in **[SETUP.md §9](SETUP.md)**. Done: token
revocation, prod config guard, multi-worker API, deep health check, structured
logging + Sentry, pagination, backend tests. Remaining: managed Postgres/Redis,
hosting + HTTPS, CI/CD ([DEPLOYMENT.md](DEPLOYMENT.md)), and real S3 video storage.

<div align="center">
<br />
<sub>Private project · all rights reserved · built with Flutter + FastAPI</sub>
</div>
</content>
