# MintFlow Viewer Mobile App — Build Plan

## Context
MintFlow is a verified-attention ad network. The **company dashboard** (Flutter Web) is done: brands create video campaigns with quiz/survey/poll/feedback tasks and a reward budget. The missing half is the **viewer mobile app**: end-users browse campaigns, watch the video, complete tasks, and earn Mint Coins (redeemable at Rs 0.75/coin), with a daily cap, streak multiplier, and raffle tickets.

The backend already exposes the full viewer flow (`auth`, `feed`, `watch`, `interactions`, `rewards`, `wallet`) and enforces all reward rules server-side. So this is largely a **new Flutter client** against existing APIs — plus a handful of **required backend fixes** the exploration uncovered.

**Scope (v1, confirmed):** happy-path MVP (auth → feed → watch → tasks → claim → wallet/profile); new `viewer_app/` copying the ~8 stable shared Dart files (web dashboard untouched); **email/password + Google sign-in**; **Android-first** (iOS config stubbed, validated later on a Mac). Targeting/demographics deferred to a later phase.

## Backend changes (REQUIRED — the app can't function without these)

These are blocking bugs/gaps in the viewer API, all small:

1. **Fix feed serialization** — `backend/app/api/v1/feed.py:25` returns raw ORM `Campaign` objects, but `CampaignResponse` is camelCase with no `from_attributes` → validation drops/breaks fields and never computes `views`/`completions`. Reuse the working serializer: extract `_build_campaign_response` (`campaigns.py:16-83`) into a shared module (`app/services/campaign_serializer.py`) and call it from both `campaigns.py` and `feed.py`.
2. **Expose `questionId`** — the feed's `InteractionOut` (`schemas/campaign.py:24-28`) omits the question UUID, but `POST /interactions/{session}/submit` requires `question_id` per answer. Add `questionId: Optional[str]` to `InteractionOut` and populate it from `question.id` in the serializer. Without this the app cannot submit tasks.
3. **Add `GET /api/v1/auth/me`** — coins/streak/tickets live on `User` but no endpoint returns them (`WalletOut` only has INR balance). Add a `MeResponse` (id, email, role, mintCoins, coinsEarnedToday, raffleTickets, dailyStreak, walletBalanceInr) so the wallet/profile screen has data. Reuse `get_current_user` (`dependencies.py`).
4. **Exclude already-watched campaigns from the feed** — one session per viewer per campaign is DB-enforced (`uq_viewer_campaign`), so a watched campaign in the feed just yields `409` on tap. Filter the feed query to campaigns with no `WatchSession` for `current_user.id` (NOT IN / outerjoin).
5. **Boosted-first ordering** — `feed.py` orders only by `created_at`; add `Campaign.is_boosted.desc()` before it so boosted campaigns surface first.
6. **Tests** — extend `backend/tests/` with feed serialization + `/me` cases (SQLite + fakeredis harness already exists).

Deferred (not in v1): viewer demographic columns on `User` + migration + targeting filter in feed. Note in code where the filter would hook in.

## Flutter app structure — `viewer_app/` (new Flutter project, package `mintflow_viewer`)

**Copy verbatim from `lib/` (pure Dart, no web deps):**
- `config/app_config.dart`, `theme.dart`
- `repositories/api_client.dart`, `local_storage.dart`, `local_storage_stub.dart`
- `models/campaign.dart` (includes `extractYouTubeVideoId`)

**New / rebuilt files:**
- `repositories/local_storage_io.dart` — sync facade over `shared_preferences`: load once at startup into an in-memory map, write-through on set. Flip `local_storage.dart`'s conditional export to `if (dart.library.io)`. Keeps the **synchronous** `read/write/remove` contract so `ApiClient` needs zero changes. (`ponytail:` do not make the interface async — it ripples into ApiClient + repos for no gain.)
- `widgets/youtube_player_widget.dart` — reimplement on **`youtube_player_flutter`** (native), keeping the same prop contract as the web widget: `videoId`, `onDurationLoaded`, `onTimeChanged(position, duration)`. Configure to **disable seek / hide progress bar** so watch-% reflects real playback (anti-cheat).
- `models/`: `viewer.dart` (profile + gamification from `/me`), `watch_session.dart` (WatchSessionOut), `wallet.dart` (WalletOut + TransactionOut). Follow the existing `fromJson` pattern in `campaign.dart`.
- `repositories/`:
  - `auth_repository.dart` — register (`role:"viewer"`)/login/logout + `me()` → viewer + `loginWithGoogle(idToken)` (`POST /auth/google` already exists). Saves JWT via `ApiClient.saveToken`.
  - `feed_repository.dart` — `GET /feed/?limit&offset` → `List<Campaign>`.
  - `watch_repository.dart` — `start(campaignId)`, `progress(sessionId, pct)`, `complete(sessionId)`, `submitAnswers(sessionId, answers)`, `claim(sessionId)`.
  - `wallet_repository.dart` — `wallet()` + `transactions()`.
- `state/viewer_controller.dart` — `ChangeNotifier` holding the viewer, feed list, and current watch-session state; consumed via `ListenableBuilder` (same pattern as `dashboard_controller.dart`).
- `pages/`: `login_page.dart` (login + register toggle), `feed_page.dart` (vertical swipe/reels list of campaigns), `watch_page.dart` (player + live progress + "Continue" gate at 80%), `tasks_sheet.dart` (interaction cards: quiz/poll/survey/feedback), `reward_page.dart` (claim result: coins/streak/tickets animation), `wallet_page.dart`, `profile_page.dart`.
- `main.dart` — wire storage → ApiClient → repositories → controller; route to login vs. home shell (bottom nav: Feed / Wallet / Profile).

**pubspec deps:** `http`, `google_fonts`, `flutter_svg`, `flutter_animate`, `shared_preferences` (new), `youtube_player_flutter` (new), `google_sign_in` (base package — native Android/iOS impl, NOT `google_sign_in_web`). Drop `youtube_player_iframe`, `google_sign_in_web`, `fl_chart` (viewer needs no charts).

**Google sign-in native config (Android v1):** in Google Cloud, add an **Android OAuth client** (package name + SHA-1); keep the existing **Web** client ID as the backend's `GOOGLE_CLIENT_ID`. On the client, initialize `GoogleSignIn(serverClientId: <web client id>)` so it returns an **`idToken`** minted for the web client — that's what the backend verifies (`aud == GOOGLE_CLIENT_ID`). Add `google-services.json` to `android/app/`. Flow: `GoogleSignIn` → `idToken` → `authRepository.loginWithGoogle(idToken)` → app JWT. iOS OAuth client + URL scheme are stubbed and validated later.

## Viewer flow → endpoints (all require a `role=viewer` Bearer JWT)
1. Register `POST /auth/register {role:"viewer"}` → Login `POST /auth/login` → save JWT; `GET /auth/me` for coins/streak.
2. Feed `GET /feed/` → campaigns (already excludes watched, boosted first).
3. Tap → `POST /watch/start {campaign_id}` → session id.
4. Play video; throttle `PATCH /watch/{id}/progress {watch_percentage}` (~every 5s / 10% milestone, send max seen).
5. At ≥80% → `POST /watch/{id}/complete`.
6. Show tasks → `POST /interactions/{id}/submit {answers:[{question_id,response_value}]}` (uses the new `questionId`).
7. `POST /rewards/claim/{id}` → reward dict `{reward_coins, raffle_tickets, daily_cap_reached, daily_streak, new_balance_coins, new_balance_inr}` → reward screen. Refresh `/me` + wallet.
8. Wallet `GET /wallet/` + `/wallet/transactions`; optional CTA deep-link via `GET /watch/redirect/{id}`.

## Watch verification (trust-critical)
Percentage must come from **real playback position** (`onTimeChanged`), never a wall-clock timer. Disable seeking in the player so a viewer can't scrub to the end. Report `max(position/duration*100)` to the backend; the 80% gate + server-side claim rules do the rest. Throttle progress PATCHes to avoid request spam.

## Build order (phased)
- **Phase 0** — backend fixes (§ above) + tests. Verify feed/me via curl before touching Flutter.
- **Phase 1** — `flutter create viewer_app`; copy shared files; mobile storage; theme; auth (login/register + Google sign-in w/ Android OAuth config) + `/me`; app shell with bottom nav.
- **Phase 2** — feed screen from `/feed`.
- **Phase 3** — watch screen + native YouTube player + progress/complete.
- **Phase 4** — tasks sheet + submit.
- **Phase 5** — claim + reward result UI.
- **Phase 6** — wallet/profile.
- **Phase 7** — empty/error/loading states, retry, logout, CTA deep-link, polish.

## Files touched
- Backend (new): `app/services/campaign_serializer.py`; edits to `app/api/v1/feed.py`, `campaigns.py`, `app/api/v1/auth.py` (+`/me`), `schemas/campaign.py` (questionId), `schemas/auth.py` (MeResponse); tests under `backend/tests/`.
- New app: `viewer_app/` (whole Flutter project as above).

## Verification
1. **Backend**: `cd backend && pytest` (add feed + /me tests); manual: register a viewer, `GET /api/v1/feed/` returns camelCase campaigns with `questionId` on interactions and excludes watched ones; `GET /api/v1/auth/me` returns coins/streak.
2. **App**: `cd viewer_app && flutter run` on an Android emulator. **Use `API_BASE_URL=http://10.0.2.2:8000`** (emulator → host loopback), not `localhost`. Walk the full flow with a viewer account: feed → watch a real YouTube campaign to 80% → answer tasks → claim → confirm the reward screen shows coins and the wallet/profile balance updates; confirm the watched campaign disappears from the feed.
3. `flutter analyze` clean; widget test for the feed→watch happy path with a fake `ApiClient` (mirror the web app's `test/dashboard_controller_test.dart` fake-http pattern).
