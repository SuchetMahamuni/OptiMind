"""
routes/dashboard_routes.py – Dashboard Endpoints
=================================================
GET /api/dashboard/stats         — today's DailyStats row
GET /api/dashboard/summary       — productivity summary (totals, streak, subject dist.)
GET /api/dashboard/stats/history — last N days of stats
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import date, timedelta, datetime, timezone
from collections import defaultdict

from app import db
from models.daily_stats import DailyStats
from models.study_session import StudySession
from models.task import Task
from services.scoring import compute_and_save_daily_stats

dashboard_bp = Blueprint("dashboard", __name__)


# ── Today's stats ──────────────────────────────────────────────────────────────
@dashboard_bp.route("/stats", methods=["GET"])
@jwt_required()
def get_daily_stats():
    user_id = int(get_jwt_identity())
    today   = date.today()

    # Dynamic Refresh: ensure today's row is updated with latest session data
    stats = compute_and_save_daily_stats(user_id)
    
    if not stats:
        # Return zeroed stats rather than 404 — makes mobile UI simpler.
        return jsonify({
            "stats": {
                "date":              today.isoformat(),
                "total_study_time":  0,
                "focus_score":       0,
                "consistency_score": 0,
            }
        }), 200

    return jsonify({"stats": stats.to_dict()}), 200


# ── Historical stats ───────────────────────────────────────────────────────────
@dashboard_bp.route("/stats/history", methods=["GET"])
@jwt_required()
def get_stats_history():
    user_id = int(get_jwt_identity())
    days    = request.args.get("days", 7, type=int)  # default: last 7 days

    since = date.today() - timedelta(days=days - 1)
    stats = (
        DailyStats.query
        .filter(DailyStats.user_id == user_id, DailyStats.date >= since)
        .order_by(DailyStats.date.asc())
        .all()
    )
    return jsonify({"history": [s.to_dict() for s in stats]}), 200


# ── Productivity summary ───────────────────────────────────────────────────────
@dashboard_bp.route("/summary", methods=["GET"])
@jwt_required()
def productivity_summary():
    """
    Returns:
        - total_study_time_today  (seconds)
        - weekly_study_time       (seconds, last 7 days)
        - current_streak          (consecutive days with ≥1 study session)
        - subject_distribution    { subject: total_seconds }
        - pending_tasks           count of incomplete tasks
        - completed_tasks         count of completed tasks
    """
    user_id = int(get_jwt_identity())
    today   = date.today()

    # ── Weekly total ───────────────────────────────────────────────────────────
    week_start = today - timedelta(days=6)
    weekly_stats = DailyStats.query.filter(
        DailyStats.user_id == user_id,
        DailyStats.date   >= week_start,
    ).all()
    weekly_total = sum(s.total_study_time for s in weekly_stats)

    # Today's total
    today_stats = next((s for s in weekly_stats if s.date == today), None)
    today_total = today_stats.total_study_time if today_stats else 0

    # ── Streak ─────────────────────────────────────────────────────────────────
    streak = _compute_streak(user_id, today)

    # ── Subject distribution ───────────────────────────────────────────────────
    subject_dist = _subject_distribution(user_id, week_start)

    # ── Task counts ────────────────────────────────────────────────────────────
    all_tasks = Task.query.filter_by(user_id=user_id).all()
    pending   = sum(1 for t in all_tasks if not t.is_completed)
    completed = sum(1 for t in all_tasks if t.is_completed)
    print(f"Pending: {pending}\nCompleted: {completed}")

    return jsonify({
        "summary": {
            "total_study_time_today": today_total,
            "weekly_study_time":      weekly_total,
            "current_streak":         streak,
            "subject_distribution":   subject_dist,
            "pending_tasks":          pending,
            "completed_tasks":        completed,
        }
    }), 200


# ── Internal helpers ───────────────────────────────────────────────────────────

def _compute_streak(user_id: int, today: date) -> int:
    """Count consecutive days (ending today) on which the user had ≥1 session."""
    streak  = 0
    current = today
    while True:
        had_session = StudySession.query.filter(
            StudySession.user_id  == user_id,
            StudySession.is_active == False,
            db.func.date(StudySession.start_time) == current.isoformat(),
        ).first()
        if had_session:
            streak  += 1
            current  = current - timedelta(days=1)
        else:
            break
    return streak


def _subject_distribution(user_id: int, since: date) -> dict:
    """Return { subject: total_seconds_studied } for sessions since `since`."""
    sessions = (
        StudySession.query
        .filter(
            StudySession.user_id  == user_id,
            StudySession.is_active == False,
            db.func.date(StudySession.start_time) >= since.isoformat(),
        )
        .all()
    )
    dist = defaultdict(int)
    for s in sessions:
        if s.task_id and s.task:
            dist[s.task.subject] += (s.duration or 0)
        else:
            dist["General"] += (s.duration or 0)
    return dict(dist)
