# MintFlow Company Dashboard

Production-style Flutter Web dashboard for company admins to create campaigns, configure quiz/survey/poll/feedback interactions, review responses, and track reward spend.

## Current Scope

- Flutter Web first, polished SaaS UI with charts and animations.
- Backend-ready repository layer behind a reactive `DashboardController`.
- Browser local storage for session and campaign persistence.
- Campaign videos are YouTube URLs; the app stores both the original URL and extracted YouTube video ID.
- No backend or mobile viewer app in this phase.
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
- `http` — API client for the backend (see below).
- State: `ChangeNotifier` (`lib/state/dashboard_controller.dart`) consumed via `ListenableBuilder`.

## Connecting a backend (FastAPI)

The UI never touches storage directly — everything goes through the repositories
in `lib/repositories/`. To go live:

1. Build a FastAPI backend that returns JSON in the same shape as
   `Campaign.toJson()` (see `lib/models/campaign.dart`). Endpoints needed:
   `POST /auth/login`, `POST /auth/google`, `GET /auth/me`, `PUT /auth/profile`,
   `GET/POST /campaigns`, `PUT /campaigns/{id}`, `PATCH /campaigns/{id}/status`,
   `DELETE /campaigns/{id}`, `POST /campaigns/{id}/duplicate`,
   `GET /campaigns/{id}/responses`, `GET /transactions`, `GET /analytics/*`.
2. Enable CORS for the Flutter Web origin.
3. Use `ApiClient` (`lib/repositories/api_client.dart`) — it already handles the
   base URL, JWT Bearer header, and token storage. Write API-backed repository
   classes that call `apiClient.get/post/...` and parse with the existing
   `fromJson` factories, then inject them in `main.dart`.
4. Run with the backend enabled:

```sh
flutter run -d chrome \
  --dart-define=USE_BACKEND=true \
  --dart-define=API_BASE_URL=http://localhost:8000
```

Config lives in `lib/config/app_config.dart` (`useBackend`, `apiBaseUrl`,
`googleClientId`).

## Google Sign-In

A "Continue with Google" button is on the login screen. It currently creates a
demo session so the flow works with no setup. To make it real:

1. Create an OAuth 2.0 **Web** Client ID in Google Cloud Console → Credentials,
   with your app origin in "Authorized JavaScript origins".
2. Add the `google_sign_in` package and use it to obtain the Google **ID token**.
3. POST that token to `POST /auth/google`; verify it server-side and issue your
   own JWT.
4. Build the `CompanyAdmin` from the verified response inside
   `AuthRepository.loginWithGoogle` (the wiring point is marked with a comment).
   Pass the client ID via `--dart-define=GOOGLE_CLIENT_ID=...`.

> Real Google login requires your own OAuth Client ID (tied to your Google Cloud
> project) and a backend to verify the token — it cannot be fully enabled from
> the frontend alone.

## Run

Flutter is not installed in the current Codex environment. Once Flutter is available locally:

```sh
cd company_dashboard
flutter doctor
flutter pub get
flutter run -d chrome
```

## Verify

```sh
cd company_dashboard
flutter analyze
flutter test
```

## Demo Login

Use the prefilled credentials on the login screen, or enter any email and password. The demo session is stored in browser local storage.

## YouTube Video Strategy

MintFlow will upload campaign videos to YouTube and store the YouTube URL in the campaign record. The app extracts the YouTube video ID from common URL formats such as:

- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://www.youtube.com/embed/VIDEO_ID`
- `https://www.youtube.com/shorts/VIDEO_ID`

For reward verification, use the YouTube IFrame Player API events in the viewer app to track playback state, current time, duration, and completion percentage. For official YouTube reporting such as channel/video views and watch-time reports, use the YouTube Analytics or Reporting APIs later.
