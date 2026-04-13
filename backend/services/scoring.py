"""
services/scoring.py – Focus & Consistency Scoring
===================================================
Scores are normalised to 0–100 and stored in DailyStats so the dashboard
can read them cheaply.

Focus Score components
───────────────────────
  1. Session Completion Ratio (40 pts)
       Sessions with 0 interruptions / total sessions today
  2. Interruption Penalty     (30 pts)
       avg interruptions per session → lower is better
  3. Balance Bonus            (30 pts)
       number of distinct subjects studied today → diversity rewarded

Consistency Score
──────────────────
  Percentage of the last 7 days that had ≥ 1 completed study session.
  Range: 0–100.

Public API
───────────
  get_focus_score(user_id) -> dict
  get_consistency_score(user_id) -> float
  compute_and_save_daily_stats(user_id) -> DailyStats  ← called after /end
"""

from datetime import date, timedelta
from collections import defaultdict

from app import db
from models.study_session import StudySession
from models.daily_stats import DailyStats


# ─────────────────────────────────────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────────────────────────────────────

def _sessions_today(user_id: int):
    today = date.today()
    return StudySession.query.filter(
        StudySession.user_id  == user_id,
        StudySession.is_active == False,
        db.func.date(StudySession.start_time) == today.isoformat(),
    ).all()


def _sessions_on_date(user_id: int, d: date):
    return StudySession.query.filter(
        StudySession.user_id  == user_id,
        StudySession.is_active == False,
        db.func.date(StudySession.start_time) == d.isoformat(),
    ).all()


def _clamp(value: float, lo: float = 0.0, hi: float = 100.0) -> float:
    return max(lo, min(hi, value))


# ─────────────────────────────────────────────────────────────────────────────
# Focus Score
# ─────────────────────────────────────────────────────────────────────────────

def get_focus_score(user_id: int) -> dict:
    """
    Compute today's focus score.
    Returns:
        {
            "score": float,          # 0–100
            "breakdown": {
                "session_completion": float,    # 0–40
                "interruption_penalty": float,  # 0–30
                "balance_bonus": float,         # 0–30
            }
        }
    """
    sessions = _sessions_today(user_id)

    if not sessions:
        return {"score": 0.0, "breakdown": {
            "session_completion": 0,
            "interruption_penalty": 0,
            "balance_bonus": 0,
        }}

    n = len(sessions)

    # ── Component 1: session completion (max 40 pts) ──────────────────────────
    # A session "completes cleanly" if it has 0 interruptions.
    clean = sum(1 for s in sessions if s.interruptions == 0)
    completion_score = _clamp((clean / n) * 40)

    # ── Component 2: interruption penalty (max 30 pts) ───────────────────────
    avg_interruptions = sum(s.interruptions for s in sessions) / n
    # 0 interruptions → 30 pts; each interruption above 0 costs 5 pts.
    interruption_score = _clamp(30 - avg_interruptions * 5)

    # ── Component 3: subject balance bonus (max 30 pts) ───────────────────────
    subjects = set()
    for s in sessions:
        if s.task_id and s.task:
            subjects.add(s.task.subject)
    # 1 subject → 10 pts; 2 → 20; 3+ → 30 pts
    balance_score = _clamp(min(len(subjects), 3) * 10)

    total = _clamp(completion_score + interruption_score + balance_score)

    return {
        "score": round(total, 2),
        "breakdown": {
            "session_completion":    round(completion_score, 2),
            "interruption_penalty":  round(interruption_score, 2),
            "balance_bonus":         round(balance_score, 2),
        },
    }


# ─────────────────────────────────────────────────────────────────────────────
# Consistency Score
# ─────────────────────────────────────────────────────────────────────────────

def get_consistency_score(user_id: int) -> float:
    """
    Percentage of the last 7 days (including today) that had ≥ 1 session.
    Returns a float in [0, 100].
    """
    today         = date.today()
    active_days   = 0
    window        = 7

    for delta in range(window):
        d        = today - timedelta(days=delta)
        sessions = _sessions_on_date(user_id, d)
        if sessions:
            active_days += 1

    return round((active_days / window) * 100, 2)


# ─────────────────────────────────────────────────────────────────────────────
# Daily Stats writer
# ─────────────────────────────────────────────────────────────────────────────

def compute_and_save_daily_stats(user_id: int) -> DailyStats:
    """
    Compute today's scores + total study time and upsert into DailyStats.
    Called automatically whenever a session ends.
    """
    today = date.today()

    sessions     = _sessions_today(user_id)
    total_secs   = sum(s.duration or 0 for s in sessions)
    focus_data   = get_focus_score(user_id)
    consistency  = get_consistency_score(user_id)

    # Upsert: try to find existing row, otherwise create it.
    stats = DailyStats.query.filter_by(user_id=user_id, date=today).first()
    if not stats:
        stats = DailyStats(user_id=user_id, date=today)
        db.session.add(stats)

    stats.total_study_time  = total_secs
    stats.focus_score       = focus_data["score"]
    stats.consistency_score = consistency

    db.session.commit()
    return stats
