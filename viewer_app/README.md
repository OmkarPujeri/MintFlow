# MintFlow Viewer App (`mintflow_viewer`)

The **viewer** half of MintFlow — a Flutter (Android-first) mobile app where
end-users browse campaigns, watch videos, complete tasks, and earn Mint Coins.
It talks to the same FastAPI backend as the company dashboard; all reward rules
are enforced server-side.

> This is a separate Flutter project from the web dashboard (repo root `lib/`).
> It **copies** the ~8 stable shared Dart files rather than sharing them, so the
> dashboard is never touched. Only files this project imports ship in the APK.

---

## Build progress

Phases follow `concurrent-launching-stearns.md` (the master plan at the repo root).

| Phase | Scope | Status |
|-------|-------|--------|
| **0 — Backend fixes** | Shared campaign serializer for the feed, `questionId` on interactions, `GET /auth/me`, exclude watched campaigns, boosted-first ordering, tests. | ✅ Done (22 backend tests) |
| **1 — Scaffold + auth** | `flutter create`, copied shared files, mobile storage (sync `shared_preferences` facade), theme, email/password + Google sign-in, `/me`, bottom-nav shell, live Profile. | ✅ Done |
| **2 — Discover** | Home browse page: all active campaigns as a scrollable card list (thumbnail / brand / **coins payout** / boost badge), **sort by payout or newest**, pull-to-refresh, empty/error/loading states. | ✅ Done |
| **3 — Watch** | Native YouTube player (`youtube_player_flutter`, seek disabled), real-playback progress, throttled `PATCH /progress`, `POST /complete` at ≥80%. | ⬜ Remaining |
| **4 — Tasks** | Interaction sheet (quiz/poll/survey/feedback) → `POST /interactions/{id}/submit` using `questionId`. | ⬜ Remaining |
| **5 — Reward** | Claim screen: `POST /rewards/claim/{id}` → coins/streak/tickets result; refresh `/me` + wallet. | ⬜ Remaining |
| **6 — Wallet** | Real Wallet tab (`/wallet/` + `/wallet/transactions`); replaces the placeholder. | ⬜ Remaining (placeholder) |
| **7 — Polish + release** | Deeper empty/error/retry, CTA deep-link, release manifest (INTERNET + https), app signing, native Google OAuth config, widget test for feed→watch. | ⬜ Remaining |

**Deferred (not in v1):** viewer demographics/targeting; campaign **categories**
(no backend field yet — Discover sorts by payout/newest only until it exists).

---

## Run it (Android emulator)

**Prereqs:** Android Studio + an Android emulator, Flutter 3.44+, and the backend
running (see repo `SETUP.md`).

```sh
# 1. Backend must be reachable from the emulator via 10.0.2.2
#    (from repo root) docker compose up -d   — or run it on the host on :8000

# 2. From this folder:
cd viewer_app
flutter pub get
flutter run --dart-define-from-file=dart_defines.dev.json
```

`dart_defines.dev.json` sets `API_BASE_URL=http://10.0.2.2:8000` (the emulator's
alias for your PC's localhost) and the Google web client id.

**First use:** the DB starts empty — tap **"Create an account"**, use a password
with **8+ chars incl. a letter and a number**. You land on the bottom-nav home.

> **Discover is empty unless the backend has an _active_ campaign.** Create one in
> the dashboard and click **Publish/Active** (a draft never appears in the feed).

---

## Architecture

Same layering as the dashboard — the UI never touches HTTP or storage directly:

```
main.dart:  LocalStorage → ApiClient → repositories → ViewerController
            └ route: isAuthenticated ? HomeShell : LoginPage
```

- **`repositories/`** — `ApiClient` (JWT + base URL), `auth_repository`,
  `feed_repository`. Mobile storage is `local_storage_io.dart`: a **synchronous**
  facade over `shared_preferences` (loads once at startup, writes through) so
  `ApiClient` needs no changes. The conditional export in `local_storage.dart`
  selects it on `dart.library.io`.
- **`state/viewer_controller.dart`** — single `ChangeNotifier`; holds the viewer
  profile + feed, consumed via `ListenableBuilder`.
- **`models/`** — `campaign.dart` (copied verbatim, incl. `extractYouTubeVideoId`),
  `viewer.dart` (from `/me`).
- **`pages/`** — `login_page`, `home_shell` (Discover / Wallet / Profile),
  `feed_page`, `profile_page`.

---

## Gotchas

- **Backend code is baked into the `mintflow-api` image** (no live mount, Gunicorn
  without `--reload`). After **any backend change**, rebuild:
  `docker compose up -d --build api`. Just restarting won't pick up the change.
- **Cleartext HTTP** to `10.0.2.2` is allowed only in the **debug** manifest
  (`android/app/src/debug/AndroidManifest.xml`). The release build stays
  https-only — production must point at an HTTPS API.
- **Google Sign-In** needs an Android OAuth client + `google-services.json` in
  Google Cloud (Phase 7). Until then the button errors gracefully;
  email/password is the working path.
- **Windows desktop is not configured** — this project is Android/iOS only. Pick
  the emulator as the run target, not "Windows".
