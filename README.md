# MintFlow Company Dashboard

Production-style **Flutter Web** dashboard for company admins to create campaigns,
configure quiz/survey/poll/feedback interactions, review responses, and track
reward spend — backed by a **FastAPI + PostgreSQL + Redis** API.

> **Setting up on a new machine? Read [SETUP.md](SETUP.md)** — it's the complete,
> step-by-step onboarding guide (Docker, env files, running the stack, Google
> Sign-In, and the production roadmap). This README is the high-level overview.
>
> **Deploying to production? Read [DEPLOYMENT.md](DEPLOYMENT.md)** — the hosting
> checklist, required env vars, and the config-time gotchas (worker/DB-connection
> sizing, CORS, Sentry, HTTPS).

## Current Scope

- **Full stack**: Flutter Web frontend + FastAPI backend (JWT auth, Postgres,
  Redis), all runnable with one `docker compose up` (see SETUP.md).
- Polished SaaS UI with charts and animations.
- Clean repository layer behind a reactive `DashboardController`; the UI never
  touches storage/HTTP directly.
- Auth: email/password **and real Google OAuth** (see below).
- Campaign videos are YouTube URLs; the app stores both the original URL and the
  extracted YouTube video ID.
- Mobile viewer app is a later phase.
- Existing HTML prototype in `../dashboard` is kept as reference.

## Features

- **Overview** — animated KPI cards (count-up), completion-trend area chart, interaction-mix donut, spend-by-campaign bars.
- **Campaigns** — live search + status filter chips; edit, pause/resume, complete, duplicate, delete (with confirm dialog + toasts).
- **Create / Edit** — one sectioned, validated form reused for both, with a live phone preview of the viewer experience.
- **Interactions / Responses / Spend** — task cards, response mix donut, budget-health gauge, spend trend, reward transactions.
- **Settings** — editable company profile that persists to local storage.
- Responsive shell (full sidebar → icon rail → mobile drawer), animated section transitions, skeleton loaders, and empty states.

## Tech

- `fl_chart` — charts.
- `flutter_animate` — entrance / micro-animations.
- `google_fonts` — Plus Jakarta Sans (headings) + Inter (body).
- `google_sign_in` / `google_sign_in_web` — real Google OAuth on the web.
- `http` — API client for the backend (see below).
- State: `ChangeNotifier` (`lib/state/dashboard_controller.dart`) consumed via `ListenableBuilder`.

## Architecture: how the frontend talks to the backend

The backend lives in **`backend/`** (FastAPI). Routes are under `/api/v1/...`
(`auth`, `campaigns`, `feed`, `watch`, `interactions`, `rewards`, `wallet`,
`analytics`) — browse them live at `http://localhost:8000/docs`.

On the Flutter side, the UI never touches storage or HTTP directly — everything
goes through the repositories in `lib/repositories/`:

- `ApiClient` (`lib/repositories/api_client.dart`) owns the base URL, the JWT
  Bearer header, and token storage.
- `AppConfig` (`lib/config/app_config.dart`) toggles `useBackend`, `apiBaseUrl`,
  and `googleClientId` — all set at build time from `dart_defines.json` (via
  `--dart-define-from-file`).
- Models parse API JSON with their `fromJson` factories (e.g.
  `lib/models/campaign.dart`).

Run against the backend by passing the defines shown in **Run** above. With
`USE_BACKEND=false` the app uses browser storage so it works with no backend at all.

## Google Sign-In

Real Google OAuth is implemented end-to-end: the web app uses Google Identity
Services (via `google_sign_in`) to get an ID token, and the backend verifies it at
`POST /api/v1/auth/google` before issuing the app JWT (creating the user on first
sign-in). It's disabled until you supply your own OAuth **Web Client ID**.

**To enable it, follow §5b in [SETUP.md](SETUP.md)** — create a Web OAuth Client
ID, add your origins, then set `GOOGLE_CLIENT_ID` in **both** the backend `.env`
and `dart_defines.json`. Without it, the button shows a "not configured" hint and
email/password login still works. The client *secret* is not used (ID-token
verification only needs the client ID, which is public).

## Run

Full setup (backend + frontend) is in **[SETUP.md](SETUP.md)**. The short version,
from the repo root:

```sh
# 1. Backend + Postgres + Redis (needs Docker + the .env files — see SETUP.md §4)
docker compose up -d --build

# 2. Frontend — build settings come from dart_defines.json (repo root)
flutter pub get
flutter run -d chrome --web-port=5173 --dart-define-from-file=dart_defines.json
```

Then open **http://localhost:5173**. API docs at **http://localhost:8000/docs**.

Build/run settings (`USE_BACKEND`, `API_BASE_URL`, `GOOGLE_CLIENT_ID`) live in
**`dart_defines.json`** — edit that file rather than passing long `--dart-define=`
flags. To run standalone (no backend, browser-storage demo mode), set
`USE_BACKEND` to `"false"` there.

## Verify

```sh
flutter analyze
flutter test
```

## First Login

The database starts empty. Register an account via the API (password: 8+ chars
with a letter and a number), then log in from the UI:

```sh
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@mintflow.com","password":"demo1234","role":"company_admin"}'
```

(On Windows PowerShell use `curl.exe`.) Or use Google Sign-In once configured.

## YouTube Video Strategy

MintFlow will upload campaign videos to YouTube and store the YouTube URL in the campaign record. The app extracts the YouTube video ID from common URL formats such as:

- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://www.youtube.com/embed/VIDEO_ID`
- `https://www.youtube.com/shorts/VIDEO_ID`

For reward verification, use the YouTube IFrame Player API events in the viewer app to track playback state, current time, duration, and completion percentage. For official YouTube reporting such as channel/video views and watch-time reports, use the YouTube Analytics or Reporting APIs later.
