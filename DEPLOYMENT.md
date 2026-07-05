# MintFlow — Deployment Guide & Hosting Checklist

Everything you need to take MintFlow from "runs on my machine" to a live
deployment, plus the gotchas that were flagged while the production-hardening
changes went in. **The code is ready; most of what's left is configuration you
set on the host — not code.**

> Read order: skim §1 (what the code already enforces), do §2 (env vars), then
> work §3 (the numbered hosting tasks). §4 is the "don't get burned" list.

---

## 1. What the code already does for you

These landed during hardening — you don't implement them, you just *configure*
them:

| Feature | How it behaves | You must… |
|---------|----------------|-----------|
| **Prod config guard** (`config.py`) | App **refuses to boot** in production with `DEBUG=True` or a weak/placeholder `SECRET_KEY` (<32 chars or contains `CHANGE_ME`). | Set `ENVIRONMENT=production` + a real `SECRET_KEY`. |
| **Deep health check** (`/health`) | Returns `200` only if **DB + Redis** both answer; `503` otherwise, with `{"checks": {...}}`. | Point the host's health/readiness probe at `GET /health`. |
| **Multi-worker** (Gunicorn + uvicorn workers) | Reads `WEB_CONCURRENCY` for the worker count. Defaults to **1** if unset. | Set `WEB_CONCURRENCY` (see §4 — the DB-connection ceiling). |
| **Structured logging** | One JSON line per request on **stdout** (`method`, `path`, `status`, `duration_ms`). | Nothing — the host captures stdout. Optionally ship to an aggregator. |
| **Sentry error tracking** | Captures unhandled exceptions, tagged with `ENVIRONMENT`. **No-op unless `SENTRY_DSN` is set.** | Set `SENTRY_DSN` to turn it on. |
| **Token revocation** | `logout` blacklists the access token in Redis until expiry; refresh rotates. | Nothing — but see §4 on the browser-storage XSS caveat (still open). |
| **List pagination** | `campaigns`, `feed`, `wallet/transactions` return **max 50** items (`?limit=&offset=`). | See §4 — the frontend "load more" note. |

---

## 2. Production environment variables

Set these on the backend host (Render/Railway/Fly/ECS dashboard → Environment).
There is **no `.env` file in prod** — the platform injects these.

```dotenv
# --- Required / safety-critical ---
ENVIRONMENT=production                 # flips CORS to strict + enables the boot guard
DEBUG=False                            # guard rejects True in prod
SECRET_KEY=<64-char hex>               # python -c "import secrets; print(secrets.token_hex(32))"
DATABASE_URL=<managed Postgres URL>    # from your DB provider (§3.1)
REDIS_URL=<managed Redis URL>          # from your Redis provider (§3.1)

# --- CORS: MUST list your real frontend origin(s), comma-separated ---
CORS_ORIGINS=https://your-frontend.example.com

# --- Scaling (see §4 for the ceiling) ---
WEB_CONCURRENCY=2                      # start at 2; raise only within DB connection limit

# --- Optional but recommended ---
SENTRY_DSN=<dsn from sentry.io>        # empty = error tracking off
GOOGLE_CLIENT_ID=<web oauth client id> # empty = Google login off

# --- Only if using S3 video storage (task #14, not yet wired) ---
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_BUCKET_NAME=mintflow-videos
AWS_REGION=ap-south-1
```

---

## 3. Hosting tasks (the roadmap, in order)

### 3.1 Managed Postgres + Redis with backups  *(roadmap #4)*
Move off the local Docker containers.
- **Postgres:** Neon / Supabase / RDS / Cloud SQL. Enable **automated backups**.
  Copy its connection string → `DATABASE_URL`. Migrations run on deploy
  (`alembic upgrade head`).
- **Redis:** Upstash / managed Redis. Copy URL → `REDIS_URL`. Redis holds the
  token blacklist and rate-limit counters — **it must be durable enough that
  restarting it doesn't un-revoke tokens** (blacklist entries are TTL'd anyway).
- ⚠️ **Note the DB's `max_connections` limit now** — small tiers cap it low
  (Neon/Supabase free ≈ 20–100). This sets your worker ceiling (§4).

### 3.2 Backend hosting  *(roadmap #8)*
Deploy the container (`backend/Dockerfile`) to Render / Railway / Fly.io / ECS.
- Build context is the **repo root** (Dockerfile expects `alembic.ini` there).
- Set all §2 env vars.
- Health check path: **`/health`**. Expect `200`.
- The container already runs Gunicorn; just set `WEB_CONCURRENCY`.

### 3.3 Frontend hosting  *(roadmap #9)*
```sh
flutter build web --dart-define-from-file=dart_defines.json
```
- In `dart_defines.json` set `API_BASE_URL` → your **deployed** API URL,
  `USE_BACKEND=true`, and `GOOGLE_CLIENT_ID` (same value as the backend).
- Deploy `build/web/` to Netlify / Vercel / Cloudflare Pages / GitHub Pages.
- Add the deployed frontend origin to the backend's `CORS_ORIGINS` (§2).

### 3.4 HTTPS / TLS  *(roadmap #10)*
Render/Railway/Fly/Netlify/Vercel terminate TLS automatically on their domains.
If you put a custom domain or your own load balancer in front, provision certs
(managed cert or Let's Encrypt). Everything must be `https://` — mixed content
breaks the browser app and Google Sign-In.

### 3.5 CI/CD  *(roadmap #12)*
GitHub Actions: `flutter analyze` + `flutter test` + `pytest` → build → deploy.
The backend suite runs with no services (SQLite + fakeredis), so CI needs no
Postgres/Redis containers:
```sh
cd backend && pip install -r requirements.txt -r requirements-dev.txt && pytest
```
Most hosts also offer deploy-on-push straight from the repo, which is the lazier
first step.

### 3.6 Dev hot-reload override  *(roadmap #11 — local only, not prod)*
A `docker-compose.override.yml` that bind-mounts `backend/` and runs
`uvicorn --reload` so backend edits don't need an image rebuild. Convenience
only; unrelated to the production deploy.

### 3.7 Mobile viewer app → Play Store  *(new track — `viewer_app/`)*
The Android-first viewer app ships as its own artifact; the dashboard host is
irrelevant to it. Before a release build:

1. **Point at the production API over HTTPS.** Build with prod defines, not the
   dev `10.0.2.2` file:
   ```sh
   cd viewer_app
   flutter build appbundle \
     --dart-define=API_BASE_URL=https://your-api.example.com \
     --dart-define=GOOGLE_CLIENT_ID=<web oauth client id>
   ```
   Android blocks cleartext `http://` in release — the API **must** be `https`.
2. **Release manifest** (`android/app/src/main/AndroidManifest.xml`): add
   `<uses-permission android:name="android.permission.INTERNET"/>` (debug has it
   automatically; release does not). Do **not** add `usesCleartextTraffic` there —
   it's intentionally debug-only.
3. **App signing** — generate an upload keystore and wire it in
   `android/app/build.gradle` + `key.properties` (keep the keystore out of git).
   Or use Play App Signing and upload the `.aab`.
4. **Native Google Sign-In** (if enabling): create an **Android** OAuth client
   (package name + SHA-1) in Google Cloud, keep the **Web** client id as the
   backend's `GOOGLE_CLIENT_ID` / the app's `serverClientId`, and drop
   `google-services.json` into `android/app/`.
5. **Anything compiled into the `.aab` is extractable** — ship only public config
   (client id, base URL). No secrets in `--dart-define`.

> Only files `viewer_app/` imports end up in the bundle — the web dashboard code
> in the repo root is never included, even though it's the same repo.

---

## 4. Gotchas flagged during hardening (read before you deploy)

**① Worker count is capped by the database, not the CPU.**
Each Gunicorn worker keeps its **own** SQLAlchemy pool. With the current default
engine that's up to **15 connections per worker** (`pool_size=5` + `max_overflow=10`).
So:
```
WEB_CONCURRENCY × 15  <  Postgres max_connections
```
Example: a DB tier with `max_connections=20` → **1 worker** is the safe max at
the default pool. To run more workers on a small DB, shrink the pool in
`backend/app/db/database.py`:
```python
engine = create_engine(settings.DATABASE_URL, pool_size=2, max_overflow=3)
```
Rule of thumb for worker count is `2×CPU+1`, but **the DB limit wins**. Start at
`WEB_CONCURRENCY=2`, watch active connections, raise only if the DB has headroom.

**② `ENVIRONMENT=production` is what actually locks things down.**
Without it, CORS still allows any localhost and the boot guard doesn't run. It's
the master switch — don't forget it.

**③ JWT is stored in browser storage (XSS-exposed) — still open (roadmap #1).**
Logout revocation is done, but the token lives in `localStorage`. The real fix
(httpOnly cookies) is a frontend+backend change not yet made. Acceptable for
launch; track it. Keep the access-token lifetime modest.

**④ Frontend lists show max 50 items.**
Backend now paginates `campaigns` / `feed` / `wallet/transactions`. The Flutter
app doesn't send `limit`/`offset` yet, so it sees the newest 50. Fine for launch;
when a user can exceed 50, add "load more" client-side (`?limit=50&offset=50`).

**⑤ Google OAuth origins must include the prod domain.**
In Google Cloud Console → Credentials → your Web client → **Authorized
JavaScript origins**, add the deployed frontend URL (e.g.
`https://your-frontend.example.com`). Missing = `origin_mismatch`. (See SETUP.md §5b.)

**⑥ Redis durability.**
The token blacklist and rate-limit counters live in Redis. A flush un-revokes
logged-out tokens (they'd still expire on their own TTL) and resets rate limits.
Use a managed Redis with persistence for prod.

---

## 5. Pre-launch smoke checklist

- [ ] `ENVIRONMENT=production`, `DEBUG=False`, strong `SECRET_KEY` set — app boots.
- [ ] `GET /health` returns `200` with `database: ok` and `redis: ok`.
- [ ] `CORS_ORIGINS` contains the real frontend origin; app loads over HTTPS.
- [ ] Register + login works; **logout then reusing the old token returns 401**.
- [ ] `WEB_CONCURRENCY` × pool ≤ DB `max_connections` (no "too many connections").
- [ ] Managed Postgres backups enabled.
- [ ] `SENTRY_DSN` set and a test error shows up in Sentry (optional).
- [ ] Google Sign-In works from the prod domain (if enabled).

**Mobile viewer app (if releasing — §3.7):**
- [ ] Release build points at the **HTTPS** production API (not `10.0.2.2`).
- [ ] `INTERNET` permission in the release manifest; no `usesCleartextTraffic`.
- [ ] Upload keystore / Play App Signing configured; `.aab` builds.
- [ ] No secrets baked into `--dart-define` (client id + base URL only).
</content>
