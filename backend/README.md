# OptiMind – Study Productivity Booster · Backend

A clean, modular Flask REST API that powers the **OptiMind** Flutter mobile app.
It provides authentication, task management, study session tracking, a scoring
system, and a rule-based intelligence layer (ready to be upgraded to ML).

---

## 📁 Project Structure

```
OptiMind/
├── app.py                   # Application factory
├── config.py                # Centralised settings (reads from .env)
├── run.py                   # Dev server entry-point
├── requirements.txt
├── render.yaml              # One-click Render deployment
├── .env.example             # Template — copy to .env and fill in secrets
│
├── models/
│   ├── user.py              # User account + password hash
│   ├── task.py              # Study tasks
│   ├── study_session.py     # Study session lifecycle
│   └── daily_stats.py       # Per-day aggregated stats (scores + study time)
│
├── routes/
│   ├── auth_routes.py       # POST /register, POST /login, GET /me
│   ├── task_routes.py       # CRUD for tasks
│   ├── session_routes.py    # Start / end / interrupt sessions
│   ├── dashboard_routes.py  # Stats + productivity summary
│   └── intelligence_routes.py  # /nudge, /focus-score, /daily-goal
│
├── services/
│   ├── rule_engine.py       # Behaviour-based nudge engine (ML-ready)
│   ├── scoring.py           # Focus & consistency score computation
│   └── adaptive_goal.py     # Daily study goal suggestion
│
├── utils/
│   ├── time_utils.py        # Date/time helpers
│   └── helpers.py           # Response builders, validators
│
└── database/
    └── __init__.py          # Package placeholder for migrations / seed scripts
```

---

## 🚀 Running Locally

### 1. Clone & create a virtual environment

```bash
git clone <your-repo-url>
cd OptiMind
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure environment variables

```bash
cp .env.example .env
# Open .env and set SECRET_KEY and JWT_SECRET_KEY to long random strings
```

### 4. Start the development server

```bash
python run.py
```

The API will be available at **http://localhost:5000**.

---

## 🌐 API Reference

All protected endpoints require the header:
```
Authorization: Bearer <access_token>
```

### Auth — `/api/auth`

| Method | Path        | Auth | Description         |
|--------|-------------|------|---------------------|
| POST   | `/register` | No   | Create account      |
| POST   | `/login`    | No   | Get JWT token       |
| GET    | `/me`       | Yes  | Get own profile     |

**Register body**
```json
{ "name": "Alice", "email": "alice@example.com", "password": "secret123" }
```

---

### Tasks — `/api/tasks`

| Method | Path                  | Auth | Description          |
|--------|-----------------------|------|----------------------|
| GET    | `/`                   | Yes  | List all tasks       |
| POST   | `/`                   | Yes  | Create task          |
| PUT    | `/<id>`               | Yes  | Update task          |
| PATCH  | `/<id>/complete`      | Yes  | Mark task completed  |
| DELETE | `/<id>`               | Yes  | Delete task          |

**Create task body**
```json
{
  "subject": "Organic Chemistry",
  "priority": "high",
  "deadline": "2026-04-15T23:59:00",
  "estimated_time": 90
}
```

---

### Study Sessions — `/api/sessions`

| Method | Path                  | Auth | Description                    |
|--------|-----------------------|------|--------------------------------|
| POST   | `/start`              | Yes  | Begin a session                |
| POST   | `/end`                | Yes  | End the active session         |
| POST   | `/<id>/interrupt`     | Yes  | Log an interruption mid-session|
| GET    | `/active`             | Yes  | Get currently active session   |
| GET    | `/`                   | Yes  | Session history (paginated)    |

**Start body** (task_id optional)
```json
{ "task_id": 3 }
```

**End body** (interruptions optional)
```json
{ "interruptions": 2 }
```

---

### Dashboard — `/api/dashboard`

| Method | Path              | Auth | Description                      |
|--------|-------------------|------|----------------------------------|
| GET    | `/stats`          | Yes  | Today's DailyStats               |
| GET    | `/stats/history`  | Yes  | Last N days (`?days=7`)          |
| GET    | `/summary`        | Yes  | Full productivity summary        |

---

### Intelligence Layer — `/api`

| Method | Path            | Auth | Description                         |
|--------|-----------------|------|-------------------------------------|
| GET    | `/nudge`        | Yes  | Behavioural nudge for the user now  |
| GET    | `/focus-score`  | Yes  | Focus score + breakdown (0–100)     |
| GET    | `/daily-goal`   | Yes  | Adaptive study goal for today       |

**Sample nudge response**
```json
{
  "nudge": "You've been studying for 125 minutes straight 🔥 — take a break!",
  "type":  "burnout"
}
```

**Sample focus-score response**
```json
{
  "focus_score":       72.5,
  "consistency_score": 71.43,
  "breakdown": {
    "session_completion":   32.0,
    "interruption_penalty": 25.0,
    "balance_bonus":        15.5
  }
}
```

---

## ☁️ Deploying to Render

1. Push repo to GitHub.
2. Create a new **Web Service** on [render.com](https://render.com), link your repo.
3. Render auto-detects `render.yaml` — click **Deploy**.
4. Set `SECRET_KEY` and `JWT_SECRET_KEY` in the Render environment panel.
5. For a real production app, create a **Postgres** database on Render and set
   `DATABASE_URL` to the provided connection string.

---

## 🔧 Upgrading the Rule Engine to ML

The intelligence layer is designed for a clean swap:

1. Open `services/rule_engine.py`.
2. Replace `get_nudge()` with a call to your trained model.
3. Keep the return shape: `{ "nudge": str, "type": str }`.
4. Routes and the Flutter client require **zero changes**.

The same pattern applies to `services/scoring.py` and `services/adaptive_goal.py`.

---

## 🔐 Security Notes

- Passwords are hashed with **werkzeug PBKDF2-SHA256** — never stored in plain text.
- JWTs expire after **7 days** (configurable in `config.py`).
- All secrets live in `.env` — never commit this file.
