"""
services/adaptive_goal.py – Daily Adaptive Study Goal
======================================================
Suggests how many minutes the user should aim to study today based on:

  1. Past study time  – 7-day rolling average; stable baseline.
  2. Pending tasks    – more pending tasks → higher goal, capped to prevent
                        overwhelm.
  3. Consistency      – users on long streaks are rewarded with a moderate
                        increase; users returning after a gap get an easier goal.

Formula (all components are floats, result is rounded to nearest 5 mins):

    base      = 7-day average (seconds → minutes), default 60 if no history
    task_bump = min(pending_tasks * 10, 30)         # +10 per task, max +30
    streak_factor = 1.0 + (streak_days * 0.02)      # up to +20% at 10-day streak
    raw_goal  = (base + task_bump) * streak_factor
    goal      = clamp(round(raw_goal / 5) * 5, 30, 240)   # 30–240 min

Public API
───────────
    get_daily_goal(user_id: int) -> dict
        Returns: { "goal_minutes": int, "rationale": str }
"""

from datetime import date, timedelta

from app import db
from models.daily_stats import DailyStats
from models.task import Task
from models.study_session import StudySession


def _rolling_avg_minutes(user_id: int, days: int = 7) -> float:
    """Average daily study time in minutes over the last `days` days."""
    today = date.today()
    since = today - timedelta(days=days - 1)

    stats = DailyStats.query.filter(
        DailyStats.user_id == user_id,
        DailyStats.date   >= since,
    ).all()

    if not stats:
        return 60.0  # sensible default for a first-time user

    total_seconds = sum(s.total_study_time for s in stats)
    return (total_seconds / 60) / days   # per-day average in minutes


def _pending_task_count(user_id: int) -> int:
    return Task.query.filter_by(user_id=user_id, is_completed=False).count()


def _current_streak(user_id: int) -> int:
    """Consecutive days (ending today) with ≥ 1 completed session."""
    today   = date.today()
    streak  = 0
    current = today

    while True:
        had = StudySession.query.filter(
            StudySession.user_id  == user_id,
            StudySession.is_active == False,
            db.func.date(StudySession.start_time) == current.isoformat(),
        ).first()

        if had:
            streak  += 1
            current  = current - timedelta(days=1)
        else:
            break

    return streak


def _round_to_5(n: float) -> int:
    return max(30, min(240, round(n / 5) * 5))


def get_daily_goal(user_id: int) -> dict:
    """
    Compute and return the adaptive daily goal.
    Replace this function with an ML predictor in the future — keep the
    return schema identical so routes and the Flutter client stay unchanged.
    """
    avg_mins       = _rolling_avg_minutes(user_id)
    pending_tasks  = _pending_task_count(user_id)
    streak_days    = _current_streak(user_id)

    # ── Component: task workload bump ─────────────────────────────────────────
    task_bump = min(pending_tasks * 10, 30)           # +10 min per task, max +30

    # ── Component: streak multiplier ──────────────────────────────────────────
    streak_factor = 1.0 + min(streak_days * 0.02, 0.20)   # up to +20%

    raw_goal      = (avg_mins + task_bump) * streak_factor
    goal_minutes  = _round_to_5(raw_goal)

    # ── Build a human-readable rationale ──────────────────────────────────────
    parts = []
    if avg_mins > 0:
        parts.append(f"your {int(avg_mins)}-min daily average")
    if pending_tasks:
        parts.append(f"{pending_tasks} pending task{'s' if pending_tasks > 1 else ''}")
    if streak_days >= 2:
        parts.append(f"a {streak_days}-day streak")

    rationale = (
        f"Goal of {goal_minutes} min based on " + ", ".join(parts) + "."
        if parts else
        f"Start with {goal_minutes} min — build your habit! 🎯"
    )

    return {
        "goal_minutes": goal_minutes,
        "rationale":    rationale,
    }
