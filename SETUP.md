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

Now run the frontend (separate terminal, from repo root):
```sh
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=http://localhost:8000
```

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

## 9. Known issues / work in progress

- **Login screen**: currently pre-fills a demo account that doesn't exist in the
  backend, so a failed login spins forever with no error. Fix in progress
  (proper error message + placeholder hints instead of prefilled values).
- **Google Sign-In**: the "Continue with Google" button is a demo stub (no real
  OAuth) and uses a plain blue "G" instead of the official multi-color icon.
  Real Google OAuth (Cloud client ID + `/api/v1/auth/google` endpoint) is planned.

---

## 10. Troubleshooting

| Symptom | Fix |
|--------|-----|
| `SECRET_KEY is missing` on `docker compose up` | You didn't create the root `.env` (see §4a). |
| `docker` command fails / daemon error | Docker Desktop isn't running — start it and retry. |
| Login hangs forever | Known issue (§9); the prefilled demo account isn't in the DB. Register one (§5). |
| `flutter: command not found` | Flutter not on PATH; reopen terminal after adding `C:\src\flutter\bin`. |
| API up but login returns 500 | Postgres container not healthy — `docker compose ps`, check `docker logs mintflow-pg`. |
| Port 8000 already in use | A host uvicorn is running; stop it or `docker compose stop api`. |
