# OptiMind Backend — Completed Walkthrough

## What Was Built

A fully modular, production-ready Flask REST API for the **OptiMind: Study Productivity Booster** mobile app.

---

## Final Project Structure

```
OptiMind/
├── app.py                        Application factory (extensions + blueprints)
├── config.py                     Centralised settings via .env
├── run.py                        Dev-server entry-point
├── requirements.txt              7 pinned dependencies
├── render.yaml                   One-click Render deploy config
├── .env / .env.example           Dev secrets (never commit .env)
├── .gitignore
├── test_api.py                   21-check smoke test suite
├── README.md                     Full API reference + deploy guide
│
├── models/
│   ├── __init__.py               Re-exports all models for SQLAlchemy
│   ├── user.py                   User (id, name, email, password_hash)
│   ├── task.py                   Task (subject, priority, deadline, estimated_time)
│   ├── study_session.py          StudySession (start/end, duration, interruptions)
│   └── daily_stats.py            DailyStats (per-day scores + study time)
│
├── routes/
│   ├── auth_routes.py            POST /register  POST /login  GET /me
│   ├── task_routes.py            GET/POST/PUT/PATCH/DELETE /tasks
│   ├── session_routes.py         POST /start  /end  /<id>/interrupt  GET /active  /history
│   ├── dashboard_routes.py       GET /stats  /stats/history  /summary
│   └── intelligence_routes.py   GET /nudge  /focus-score  /daily-goal
│
├── services/
│   ├── rule_engine.py            6-rule nudge engine (ML-swappable)
│   ├── scoring.py                Focus score (0–100) + Consistency score
│   └── adaptive_goal.py         3-factor daily study goal suggestion
│
├── utils/
│   ├── time_utils.py             Date/time helpers (now_utc, friendly durations …)
│   └── helpers.py                Response builders, email/password validators
│
└── database/
    └── __init__.py               Package placeholder for future migrations
```

---

## All 20 Registered Routes

| Blueprint | Method | Path | Auth |
|-----------|--------|------|------|
| Auth | POST | `/api/auth/register` | No |
| Auth | POST | `/api/auth/login` | No |
| Auth | GET | `/api/auth/me` | JWT |
| Tasks | GET | `/api/tasks/` | JWT |
| Tasks | POST | `/api/tasks/` | JWT |
| Tasks | PUT | `/api/tasks/<id>` | JWT |
| Tasks | PATCH | `/api/tasks/<id>/complete` | JWT |
| Tasks | DELETE | `/api/tasks/<id>` | JWT |
| Sessions | POST | `/api/sessions/start` | JWT |
| Sessions | POST | `/api/sessions/end` | JWT |
| Sessions | POST | `/api/sessions/<id>/interrupt` | JWT |
| Sessions | GET | `/api/sessions/active` | JWT |
| Sessions | GET | `/api/sessions/` | JWT |
| Dashboard | GET | `/api/dashboard/stats` | JWT |
| Dashboard | GET | `/api/dashboard/stats/history` | JWT |
| Dashboard | GET | `/api/dashboard/summary` | JWT |
| Intelligence | GET | `/api/nudge` | JWT |
| Intelligence | GET | `/api/focus-score` | JWT |
| Intelligence | GET | `/api/daily-goal` | JWT |

---

## Rule Engine — 6 Rules (Priority Order)

| # | Rule | Type | Fires when |
|---|------|------|-----------|
| 1 | `_rule_burnout_long_session` | burnout | Active session > 120 min |
| 2 | `_rule_burnout_high_daily` | burnout | Total today > 300 min |
| 3 | `_rule_laziness_no_study_yet` | laziness | After 14:00 with zero study |
| 4 | `_rule_laziness_low_study_evening` | laziness | After 18:00 with < 60 min |
| 5 | `_rule_reminder_neglected_subject` | reminder | Any subject unstudied 2+ days |
| 6 | `_rule_on_track` | on_track | Always (fallback) |

To add a new rule: write a `_rule_*` function and append it to `RULES`. No other change needed.

---

## Scoring System

### Focus Score (0–100)
| Component | Max pts | Logic |
|-----------|---------|-------|
| Session completion | 40 | `(clean sessions / total) × 40` |
| Interruption penalty | 30 | `30 − avg_interruptions × 5` |
| Subject balance bonus | 30 | `min(distinct_subjects, 3) × 10` |

### Consistency Score (0–100)
`(active days in last 7) / 7 × 100`

---

## Adaptive Goal Formula

```
base           = 7-day rolling avg (minutes), default 60 for new users
task_bump      = min(pending_tasks × 10, 30)       ← +10 min per task, max +30
streak_factor  = 1.0 + min(streak_days × 0.02, 0.20)  ← up to +20% at 10-day streak
raw_goal       = (base + task_bump) × streak_factor
goal_minutes   = clamp(round(raw_goal / 5) × 5,  30, 240)
```

---

## Test Results

```
=== OptiMind API Smoke Test ===

1. Auth
  PASS  Register user  [201]
  PASS  Login  [200]
  PASS  JWT token returned
  PASS  GET /me  [alice_<ts>@test.com]

2. Tasks
  PASS  Create task  [Organic Chemistry]
  PASS  List tasks  [1 task(s)]
  PASS  Update task  [medium]
  PASS  Complete task

3. Study Sessions
  PASS  Start session  [active=True]
  PASS  Log interruption  [interruptions=1]
  PASS  GET active session  [id=2]
  PASS  End session  [duration=0s]
  PASS  List sessions history  [total=1]

4. Dashboard
  PASS  GET today stats  [study_time=0s  focus=35.0]
  PASS  GET productivity summary  [streak=1d  weekly=0s]
  PASS  GET stats history (7d)  [1 record(s)]

5. Intelligence
  PASS  GET /nudge  [type=laziness]
  PASS  GET /focus-score  [focus=35.0  consistency=14.29]
  PASS  GET /daily-goal  [goal=30 min]

6. Edge Cases
  PASS  Reject double-start session  [A session is already active]
  PASS  Delete task  [Task deleted]

=============================================
  Result: 21/21 tests passed
  >>> All systems go! <<<
=============================================
```

---

## Running Locally

```bash
# 1. Activate venv
venv\Scripts\activate          # Windows
source venv/bin/activate       # macOS/Linux

# 2. Start server
python run.py
# → http://localhost:5000

# 3. Run smoke tests (server must be running)
python test_api.py
```

---

## Deploying to Render

1. Push to GitHub
2. Create **Web Service** on render.com, link the repo
3. Render auto-reads `render.yaml` — click **Deploy**
4. Set `SECRET_KEY` and `JWT_SECRET_KEY` to random 32+ char strings in the Render dashboard
5. For production, create a Render **Postgres** DB and set `DATABASE_URL` to its connection URL

```bash
# Generate a strong key locally:
python -c "import secrets; print(secrets.token_hex(32))"
```

---

## Upgrading the Rule Engine to ML

The intelligence layer is designed for a **zero-friction swap**:

```python
# services/rule_engine.py — current rule-based version
def get_nudge(user_id: int) -> dict:
    ctx = { ... }
    for rule in RULES:
        result = rule(user_id, ctx)
        if result:
            return result

# services/rule_engine.py — future ML version
def get_nudge(user_id: int) -> dict:
    features = build_feature_vector(user_id)
    label, message = my_model.predict(features)
    return {"nudge": message, "type": label}
```

Routes and the Flutter client require **zero changes** — they only see the `{ nudge, type }` contract.

The same pattern applies to `scoring.py` → `get_focus_score()` and `adaptive_goal.py` → `get_daily_goal()`.

---

## Known IDE Lint Warnings

The Pyre2 linter shows "Could not find import of flask / flask_sqlalchemy …" errors. These are **false positives** — Pyre2 is not configured to look at the `venv/` site-packages. The server runs correctly. To suppress them, either:

- Set your IDE Python interpreter to `venv\Scripts\python.exe`, **or**
- Add a `.pyre_configuration` pointing at the venv's `site-packages` path.
