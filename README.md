# Private Space

A one-way private messaging app. You write to a person; they can only read.

- `backend/`  FastAPI + SQLAlchemy + Alembic + PostgreSQL
- `frontend/` Flutter (Android first)

## How the one-way model works

Messages are directed rows: `sender_id -> recipient_id`.

- `POST /messages` has no sender field. `sender_id` is always the JWT user, so it cannot be spoofed.
- There are no edit, delete, reply, or reaction endpoints.
- `GET /messages/{user_id}?direction=sent` returns what **I wrote** to that person (`can_write: true`).
- `GET /messages/{user_id}?direction=received` returns what **they wrote to me** (`can_write: false`). Opening it marks those messages read.
- In the app, each person's space has two tabs: "Written by me" (with composer) and "Written to me" (read-only, shows "You can only read this space.").

## Local setup (backend)

Requires Python 3.11+ and a local PostgreSQL.

```bash
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt

createdb private_space                               # or create it in pgAdmin
cp .env.example .env                                 # then edit DATABASE_URL and JWT_SECRET

alembic upgrade head                                 # create tables
python seed.py                                       # DEV ONLY: Alice 1234, Bob 2345, John 3456, Sarah 4567
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Generate a secret: `python -c "import secrets; print(secrets.token_urlsafe(48))"`.
API docs: http://localhost:8000/docs

Optional smoke test (uses SQLite, no Postgres needed):

```bash
pip install pytest httpx
DATABASE_URL=sqlite:///test.db JWT_SECRET=a-long-test-secret-of-32-chars-minimum pytest -q
```

## Local setup (Flutter)

```bash
cd frontend
flutter create --org com.example --project-name private_space .   # generates android/ (keeps lib/ and pubspec.yaml)
flutter pub get
```

Then edit the generated Android files:

1. `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` add:
   `<uses-permission android:name="android.permission.INTERNET"/>`
   and on `<application>` add `android:usesCleartextTraffic="true"` (needed for `http://10.0.2.2` in development; remove it for release builds that only use HTTPS).
2. `android/app/build.gradle(.kts)`: set `minSdk = 23` (required by `flutter_secure_storage`).

If `flutter create` overwrote `pubspec.yaml` or `lib/main.dart`, restore them from this project.

Run against the local backend on an Android emulator (default URL is `http://10.0.2.2:8000`):

```bash
flutter run
# physical phone on the same Wi-Fi:
flutter run --dart-define=API_BASE_URL=http://<your-computer-LAN-ip>:8000
```

The base URL lives in one place: `frontend/lib/config.dart`.

## Deploy the backend to Render

1. Push this repo to GitHub.
2. Render dashboard: **New + > PostgreSQL**. Create it, then copy the **Internal Database URL**.
3. **New + > Web Service**, connect the repo, and set:
   - Root Directory: `backend`
   - Runtime: Docker (uses `backend/Dockerfile`, which runs `alembic upgrade head` and then `uvicorn ... --host 0.0.0.0 --port $PORT`)
   - Health Check Path: `/health`
4. Environment variables:
   - `DATABASE_URL` = the Internal Database URL
   - `JWT_SECRET` = a long random string
   - `APP_ENV` = `production` (makes `seed.py` refuse to run)
5. Deploy. Check `https://<your-service>.onrender.com/health`.

Alternatively use the included `render.yaml` via **New + > Blueprint**.

Create real users in production (Render Shell tab, or locally with the production `DATABASE_URL`):

```bash
python create_user.py "Alice" 4821
```

Do not run `seed.py` in production; its PINs are public.

Note: on Render's free tier the service sleeps when idle, so the first request can take ~30 seconds. The app uses a 40 second timeout.

## Build the Android APK

```bash
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com
# output: build/app/outputs/flutter-apk/app-release.apk
```

## Security notes

- PINs are hashed with Argon2; plaintext PINs are never stored or returned.
- A 4-digit PIN has only 10,000 possibilities, so the backend locks an account for 5 minutes after 5 wrong attempts. Keep that, and keep the database private, since a leaked hash can be brute-forced offline in seconds.
- `GET /users` is public by design (it feeds the "Choose your space" screen) and exposes only ids and display names.
- JWTs last 30 days and are stored with `flutter_secure_storage`. There is no server-side revocation in v1.

## API summary

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/users` | no | People to choose from |
| POST | `/auth/login` | no | `{user_id, pin}` returns a JWT |
| GET | `/auth/me` | yes | Validate stored session |
| PUT | `/auth/change-pin` | yes | `{current_pin, new_pin}` |
| GET | `/chats` | yes | People with counts and previews |
| GET | `/messages/{user_id}?direction=sent\|received` | yes | One direction of a thread |
| POST | `/messages` | yes | `{recipient_id, content}` |
