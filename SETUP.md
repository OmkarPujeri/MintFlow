# MintFlow — Developer Setup & Onboarding

This guide gets the **full stack** (FastAPI backend + Postgres + Redis + Flutter Web
dashboard) running on a fresh machine, and summarizes the recent production-hardening
changes so a teammate who is behind on commits can catch up.

> TL;DR: install Docker + Flutter, create two `.env` files from the templates,
> run `docker compose up -d --build`, then `flutter run`. Details below.

---

## 1. Architecture at a glance

| Part | Tech | Port | Location |
|------|------|------|----------|
| Backend API | FastAPI (Python 3.13) | `8000` | `backend/` |
| Database | PostgreSQL 16 | `5432` | Docker container |
| Cache / rate-limit store | Redis 7 | `6379` | Docker container |
| Frontend | Flutter Web | `5173` | `lib/` |

- API routes are under `/api/v1/...` (e.g. `POST /api/v1/auth/login`).
- The whole backend now runs via **Docker Compose** with one command; migrations
  run automatically on startup.

---

## 2. Prerequisites

Install these first:

1. **Git**
2. **Docker Desktop** — https://www.docker.com/products/docker-desktop/
   (must be **running** before any `docker` command)
3. **Flutter SDK 3.44+** — https://docs.flutter.dev/get-started/install
   - Unzip to e.g. `C:\src\flutter`, add `C:\src\flutter\bin` to PATH, then
     open a **new** terminal and run `flutter doctor` (Flutter + Chrome must be ✓;
     Android/Visual Studio warnings are fine — we only build for web).

Python is **not required on the host** — it runs inside the backend container.
(Optional: install Python 3.13 only if you want to run the backend directly on
the host with hot-reload; see §6.)

---

## 3. Get the code

```sh
git clone https://github.com/OmkarPujeri/MintFlow.git
cd MintFlow
# if you already cloned, just get the latest:
git pull origin main
```

---

## 4. Create the environment files (IMPORTANT)

Secrets are **not** committed to git. You must create two `.env` files from the
provided `.env.example` templates. Both are gitignored.

### 4a. Root `.env` (used by docker-compose)

```sh
cp .env.example .env
```
Then edit `.env` and set your own values:
```dotenv
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<pick-any-strong-password>
POSTGRES_DB=mintflow_db

# generate with: python -c "import secrets; print(secrets.token_hex(32))"
# (or any 64-char hex string)
SECRET_KEY=<paste-a-random-64-char-hex>
ENVIRONMENT=development
DEBUG=True
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# Google Sign-In — Web OAuth Client ID (see §5b for how to get one).
# Leave empty to disable Google login (email/password still works).
GOOGLE_CLIENT_ID=
```

### 4b. `backend/.env` (used if you run the backend on the host, §6)

```sh
cp backend/.env.example backend/.env
```
Edit it so `DATABASE_URL`'s password matches the `POSTGRES_PASSWORD` above, and
set the same `SECRET_KEY`:
```dotenv
DATABASE_URL=postgresql://postgres:<same-password>@localhost:5432/mintflow_db
SECRET_KEY=<same-64-char-hex>
GOOGLE_CLIENT_ID=<same-client-id-as-root-.env>   # only needed for Google login
```

> For the Docker-only workflow (§5) you technically only need the **root** `.env`.
> Create `backend/.env` too if you plan to run the backend on the host.

---

## 5. Run the full stack (recommended — Docker)

Make sure Docker Desktop is running, then from the repo root:

```sh
docker compose up -d --build
```

This builds the API image and starts **Postgres + Redis + API** together.
Database migrations (`alembic upgrade head`) run automatically on startup.

Verify the backend:
```sh
curl http://localhost:8000/health         # -> {"status":"healthy"}
# API docs: http://localhost:8000/docs
```

Now run the frontend (separate terminal, from repo root). **Put the whole
command on one line** — the `\` line-continuation is a bash-ism and breaks in
PowerShell:
```sh
flutter pub get
flutter run -d chrome --web-port=5173 --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=GOOGLE_CLIENT_ID=<your-client-id>
```
> Omit the `GOOGLE_CLIENT_ID` define if you don't need Google login — the button
> then shows a "not configured" hint and email/password login still works.

Open **http://localhost:5173**.

### First login
The database starts empty. Register an account (any email + a password with
**at least 8 chars incl. a letter and a number**), e.g. via the API:
```sh
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@mintflow.com","password":"demo1234","role":"company_admin"}'
```
Then log in from the UI with `demo@mintflow.com` / `demo1234`.
(On Windows PowerShell use `curl.exe`, not `curl`, which is an alias for
`Invoke-WebRequest`.)

---

## 5b. Enable Google Sign-In (optional)

Real Google login needs your own OAuth Client ID — it can't be enabled from the
frontend alone. The `id_token` verification is done server-side; the **client
secret is not used** and should not be committed.

1. **Google Cloud Console** → create/select a project.
2. **APIs & Services → OAuth consent screen** → *External* → fill app name +
   your email → add your Google account under **Test users**.
3. **APIs & Services → Credentials → Create Credentials → OAuth client ID** →
   type **Web application**.
4. Under **Authorized JavaScript origins** add every origin the app runs from:
   - `http://localhost:5173` (local dev — must match `--web-port`)
   - `https://omkarpujeri.github.io` (deployed build)
   Leave *Authorized redirect URIs* empty (Google Identity Services uses origins).
5. Copy the **Client ID** (`xxxx.apps.googleusercontent.com`) and put the **same
   value** in two places:
   - the backend env (`GOOGLE_CLIENT_ID` in the root `.env`, §4a), then
     `docker compose up -d` to reload it;
   - the Flutter `--dart-define=GOOGLE_CLIENT_ID=...` (§5).

When configured, the login page shows Google's official rendered button. First
sign-in auto-creates a `company_admin` user with no local password.

**Troubleshooting:** `origin_mismatch` / `redirect_uri_mismatch` = the origin in
step 4 doesn't exactly match (scheme, host, and port); a `503` from
`/api/v1/auth/google` means `GOOGLE_CLIENT_ID` is empty on the backend.

---

## 6. Optional — run the backend on the host (hot-reload dev)

Nice when actively editing backend code (the container has no `--reload`, so it
needs a rebuild after changes). Run only Postgres + Redis in Docker:

```sh
docker compose up -d postgres redis
python -m venv venv
venv\Scripts\activate                     # Windows
pip install -r backend\requirements.txt
cd backend
..\venv\Scripts\uvicorn app.main:app --reload --port 8000
```
Uses `backend/.env` (host talks to `localhost:5432`). Stop the containerized
`api` first if it's running (`docker compose stop api`) to free port 8000.

---

## 7. Everyday commands

```sh
docker compose up -d          # start / resume the stack (data persists)
docker compose stop           # stop, keep data
docker compose up -d --build  # rebuild API after backend code changes
docker logs -f mintflow-api   # tail API logs
docker compose ps             # container status

# DANGER: `docker compose down -v` deletes the DB volume (wipes all data).
```

---

## 8. What changed recently (catch-up for the team)

Recent work hardened the app toward production. Key commits:

- `feat(auth)` — **Real Google OAuth sign-in**. Frontend uses the `google_sign_in`
  package + Google Identity Services to obtain an ID token; the backend verifies
  it at `POST /api/v1/auth/google` (checking signature, expiry, and `aud` ==
  `GOOGLE_CLIENT_ID`), then finds-or-creates the user and issues the app JWT.
  `users.password_hash` is now nullable (Google users have no local password —
  migration `a1b2c3d4e5f6`). See §5b to enable it.
- `fix(auth)` — login now shows clear error messages (no more infinite spinner),
  demo credentials are placeholder hints instead of prefilled values, and the
  Google button uses the official multi-color icon.
- `feat(docker)` — **Dockerized the backend**; added `docker-compose.yml`,
  `backend/Dockerfile`, `.dockerignore`. Whole stack starts with one command;
  migrations auto-run; Postgres uses a **persistent named volume** (`mintflow_pgdata`).
- `feat(security)` — production hardening:
  - Secrets removed from git; `.env` files gitignored; `.env.example` templates added.
  - **CORS** locked to explicit origins/methods (any-localhost only in dev).
  - **Rate limiting** (Redis-backed) on `/auth/login` (10/min) and `/auth/register` (5/min).
  - **Password policy** (min 8, letter + number) on registration.
  - Config hardened: `DEBUG` off by default, `SECRET_KEY`/`DATABASE_URL` required,
    `.env` loads regardless of working directory; Alembic reads the DB URL from
    app settings (no credentials in `alembic.ini`).
- `chore(security)` — stopped tracking Python bytecode (`__pycache__`, `*.pyc`) and
  the `venv/`.

### Config / secrets model (so nothing leaks)
- `backend/app/config.py` reads settings from `backend/.env` (or env vars).
- `SECRET_KEY` and `DATABASE_URL` are **required** — the app refuses to start without them.
- Real `.env` files are gitignored; only `*.env.example` templates are committed.

---

## 9. Production roadmap (what's left before going live)

The app runs end-to-end locally. The items below are **not yet done** and are the
path to a real deployment, roughly in priority order. Status verified against the
current code.

**🔴 Security**
1. **Token handling** — the JWT lives in browser storage (XSS-exposed). Also
   `logout` and refresh **do not blacklist tokens yet**: the Redis blacklist is
   *read* in `dependencies.py`/`auth.py` but nothing ever writes to it, so logout
   is currently a no-op server-side. Wire logout to blacklist the token (with a
   TTL = token expiry) and rotate refresh tokens.
2. **`DEBUG=False` in prod** — local `.env` sets `DEBUG=True`; compose defaults to
   `False`. Ensure staging/prod sets `ENVIRONMENT=production` and `DEBUG=False`.

**🟠 Reliability & correctness**
3. **Multi-worker API** — Dockerfile runs a single uvicorn process. Run under
   Gunicorn with uvicorn workers (or `uvicorn --workers N`).
4. **Managed Postgres + Redis** — move off the local containers to a hosted DB
   with automated backups (RDS / Cloud SQL / Neon / Supabase; Upstash for Redis).
5. **Deep health check** — `/health` returns a static value; extend it to verify
   DB + Redis connectivity (readiness probe).
6. **Structured logging + error tracking** (e.g. Sentry).
7. **Pagination on list endpoints** — `list_campaigns` (and responses) return
   `.all()` with no limit/offset.

**🟡 Deployment & delivery**
8. **Backend hosting** — deploy the container (Render / Railway / Fly.io / ECS).
9. **Frontend hosting** — `flutter build web` → Netlify / Vercel / Cloudflare /
   GitHub Pages.
10. **HTTPS/TLS** on both API and frontend.
11. **Dev hot-reload compose override** — a `docker-compose.override.yml` that
    bind-mounts code + `--reload`, so backend edits don't need an image rebuild
    (see §6 for the current host-run workaround).
12. **CI/CD** (GitHub Actions): lint → test → build → deploy.

**🟢 Quality & maintainability**
13. **Backend tests** (pytest) for auth / campaigns / rewards — none exist yet.
14. **Real video storage** — AWS S3 keys are empty; campaigns currently rely on
    YouTube URLs only.

✅ **Recently completed:** real Google OAuth, login error handling, Dockerized
full stack, security hardening (CORS, rate limiting, password policy, secrets out
of git). See §8.

---

## 10. Troubleshooting

| Symptom | Fix |
|--------|-----|
| `SECRET_KEY is missing` on `docker compose up` | You didn't create the root `.env` (see §4a). |
| `docker` command fails / daemon error | Docker Desktop isn't running — start it and retry. |
| "No account found" on login | The account isn't registered — register one (§5). Note `demo@mintflow.com` is easy to mistype as `mitflow`. |
| Google button says "not configured" | `--dart-define=GOOGLE_CLIENT_ID` wasn't passed. A dart-define only applies on a full `flutter run` (not hot reload) — quit with `q` and relaunch (§5). |
| Google popup: `origin_mismatch` | `http://localhost:5173` isn't in the OAuth client's Authorized JavaScript origins (§5b). |
| `flutter: command not found` | Flutter not on PATH; reopen terminal after adding `C:\src\flutter\bin`. |
| API up but login returns 500 | Postgres container not healthy — `docker compose ps`, check `docker logs mintflow-pg`. |
| Port 8000 already in use | A host uvicorn is running; stop it or `docker compose stop api`. |
| `curl` prompts for `Uri:` on Windows | You're in PowerShell where `curl` aliases `Invoke-WebRequest`; use `curl.exe`. |
