"""
services/rule_engine.py – Behaviour-Based Nudge Engine
=======================================================
All logic here is **pure rule-based** and fully replaceable by an ML model
in the future.  The public contract is:

    get_nudge(user_id: int) -> dict
        Returns: { "nudge": str, "type": "burnout" | "laziness" | "reminder" | "on_track" }

Design principle: each rule is a standalone function that returns a dict on
a match, or None if the rule does not fire.  The engine evaluates rules in
priority order and returns the first match.

Adding a new rule = adding a new _rule_* function and registering it in RULES.
Swapping to ML = replace get_nudge() with a model call; keep the return shape.
"""

from datetime import date, datetime, timedelta, timezone
from collections import defaultdict

from app import db
from models.study_session import StudySession
from models.task import Task
from models.daily_stats import DailyStats
from utils.time_utils import minutes_to_friendly, seconds_to_minutes


# ─────────────────────────────────────────────────────────────────────────────
# Data helpers
# ─────────────────────────────────────────────────────────────────────────────

def _today_study_seconds(user_id: int) -> int:
    """Total seconds studied today (completed sessions only)."""
    today = date.today()
    sessions = StudySession.query.filter(
        StudySession.user_id  == user_id,
        StudySession.is_active == False,
        db.func.date(StudySession.start_time) == today.isoformat(),
    ).all()
    return sum(s.duration or 0 for s in sessions)


def _active_session(user_id: int):
    """Return the currently active session or None."""
    return StudySession.query.filter_by(user_id=user_id, is_active=True).first()


def _active_session_minutes(session) -> int:
    """How many minutes has the active session been running?"""
    if not session:
        return 0
    start = session.start_time
    if start.tzinfo is None:
        start = start.replace(tzinfo=timezone.utc)
    return int((datetime.now(timezone.utc) - start).total_seconds() / 60)


def _last_studied_per_subject(user_id: int) -> dict:
    """
    Returns { subject: last_study_date } for each subject the user has tasks in.
    Uses sessions linked to tasks to determine which subject was last studied.
    """
    result    = {}
    sessions  = (
        StudySession.query
        .filter(StudySession.user_id == user_id, StudySession.is_active == False)
        .order_by(StudySession.start_time.desc())
        .all()
    )
    for s in sessions:
        if s.task_id and s.task:
            subject = s.task.subject
            if subject not in result:
                result[subject] = s.start_time.date() if s.start_time.tzinfo is None \
                                  else s.start_time.astimezone().date()
    return result


# ─────────────────────────────────────────────────────────────────────────────
# Individual rules
# ─────────────────────────────────────────────────────────────────────────────

def _rule_burnout_long_session(user_id: int, ctx: dict):
    """Fire if the user has been in a session for > 120 minutes continuously."""
    session = ctx.get("active_session")
    mins    = _active_session_minutes(session)
    if mins >= 120:
        return {
            "nudge": (
                f"You've been studying for {mins} minutes straight. "
                "Time for a 15-minute break — your brain will thank you!"
            ),
            "type": "burnout",
        }
    return None


def _rule_burnout_high_daily(user_id: int, ctx: dict):
    """Fire if daily study time exceeds 5 hours — risk of burnout."""
    total_mins = seconds_to_minutes(ctx["today_seconds"])
    if total_mins >= 300:
        return {
            "nudge": (
                f"You've already clocked {minutes_to_friendly(total_mins)} today. "
                "Amazing effort! Consider wrapping up — rest is part of learning."
            ),
            "type": "burnout",
        }
    return None


def _rule_laziness_low_study_evening(user_id: int, ctx: dict):
    """
    Fire after 18:00 if total study today < 60 minutes.
    Gently nudge the user to start small.
    """
    hour        = datetime.now().hour
    total_mins  = seconds_to_minutes(ctx["today_seconds"])
    if hour >= 18 and total_mins < 60:
        return {
            "nudge": (
                "It's evening and you haven't hit 60 minutes yet. "
                "Even a focused 25-minute Pomodoro now makes a difference!"
            ),
            "type": "laziness",
        }
    return None


def _rule_laziness_no_study_yet(user_id: int, ctx: dict):
    """Fire in the afternoon (after 14:00) if zero study recorded today."""
    hour        = datetime.now().hour
    total_mins  = seconds_to_minutes(ctx["today_seconds"])
    if hour >= 14 and total_mins == 0:
        return {
            "nudge": (
                "You haven't started studying yet today. "
                "Start with just 10 minutes — momentum builds quickly!"
            ),
            "type": "laziness",
        }
    return None


def _rule_reminder_neglected_subject(user_id: int, ctx: dict):
    """Fire if any subject hasn't been studied for >= 2 days."""
    last_studied  = ctx.get("last_studied_per_subject", {})
    today         = date.today()
    neglected     = [
        subj for subj, last_date in last_studied.items()
        if (today - last_date).days >= 2
    ]
    if neglected:
        subjects_str = ", ".join(neglected[:2])  # mention at most 2
        suffix       = " and more" if len(neglected) > 2 else ""
        return {
            "nudge": (
                f"You haven't studied {subjects_str}{suffix} in 2+ days. "
                "Today is a great day to revisit it!"
            ),
            "type": "reminder",
        }
    return None


def _rule_on_track(user_id: int, ctx: dict):
    """
    Fallback: user is doing well.
    Always fires — ensures get_nudge() never returns None.
    """
    total_mins = seconds_to_minutes(ctx["today_seconds"])
    if total_mins >= 60:
        return {
            "nudge": f"You've studied {minutes_to_friendly(total_mins)} today — keep it up!",
            "type": "on_track",
        }
    return {
        "nudge": "Ready to study? Pick a task and let's get started!",
        "type":  "on_track",
    }


# ─────────────────────────────────────────────────────────────────────────────
# Rule registry — evaluated top-to-bottom; first match wins.
# Add / reorder rules here without touching any other code.
# ─────────────────────────────────────────────────────────────────────────────
RULES = [
    _rule_burnout_long_session,
    _rule_burnout_high_daily,
    _rule_laziness_no_study_yet,
    _rule_laziness_low_study_evening,
    _rule_reminder_neglected_subject,
    _rule_on_track,            # always-match fallback
]


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

def get_nudge(user_id: int) -> dict:
    """
    Evaluate rules for `user_id` and return the first matching nudge.

    To replace with ML later:
        1. Delete the RULES list and helper functions.
        2. Call your model here.
        3. Return the same { "nudge": str, "type": str } shape.
    """
    # Build context once — avoids repeated DB hits inside each rule function
    ctx = {
        "today_seconds":           _today_study_seconds(user_id),
        "active_session":          _active_session(user_id),
        "last_studied_per_subject": _last_studied_per_subject(user_id),
    }

    for rule in RULES:
        result = rule(user_id, ctx)
        if result:
            return result

    # Should never reach here thanks to _rule_on_track, but just in case:
    return {"nudge": "Keep going! 💡", "type": "on_track"}
