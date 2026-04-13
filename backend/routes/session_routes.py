"""
routes/session_routes.py – Study Session Endpoints
===================================================
POST /api/sessions/start          — begin a new study session
POST /api/sessions/end            — end the active session
POST /api/sessions/<id>/interrupt — increment interruption counter
GET  /api/sessions/               — list past sessions (most recent first)
GET  /api/sessions/active         — get the currently active session, if any
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, timezone

from app import db
from models.study_session import StudySession
from services.scoring import compute_and_save_daily_stats

session_bp = Blueprint("sessions", __name__)


# ── Start session ──────────────────────────────────────────────────────────────
# @session_bp.route("/start", methods=["POST"])
# @jwt_required()
# def start_session():
#     """
#     Body: { "task_id": int (optional) }
#     A user cannot have two active sessions simultaneously.
#     """
#     user_id = int(get_jwt_identity())

#     # Guard: prevent double-starting
#     existing = StudySession.query.filter_by(user_id=user_id, is_active=True).first()
#     if existing:
#         return jsonify({
#             "error": "A session is already active",
#             "session": existing.to_dict()
#         }), 409

#     data    = request.get_json(silent=True) or {}
#     task_id = data.get("task_id")

#     session = StudySession(
#         user_id=user_id,
#         task_id=task_id,
#         start_time=datetime.now(timezone.utc),
#     )
#     db.session.add(session)
#     db.session.commit()
#     return jsonify({"session": session.to_dict()}), 201


# ── End session ────────────────────────────────────────────────────────────────
@session_bp.route("/add_session", methods=["POST"])
@jwt_required()
def end_session():
    """
    Body: { "start_time": iso8601, "end_time": iso8601, "interruptions": int, "task_id": int }
    Calculates duration, marks session inactive, then refreshes daily stats.
    """
    user_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}

    # ── 1. Parse timestamps ───────────────────────────────────────────────────
    now = datetime.now(timezone.utc)
    
    start_str = data.get("start_time")
    end_str   = data.get("end_time")

    try:
        if start_str:
            start_time = datetime.fromisoformat(start_str.replace("Z", "+00:00"))
        else:
            start_time = now

        if end_str:
            end_time = datetime.fromisoformat(end_str.replace("Z", "+00:00"))
        else:
            end_time = now
    except (ValueError, TypeError):
        start_time = now
        end_time   = now

    # Ensure timezone awareness for calculation
    if start_time.tzinfo is None:
        start_time = start_time.replace(tzinfo=timezone.utc)
    if end_time.tzinfo is None:
        end_time = end_time.replace(tzinfo=timezone.utc)

    # ── 2. Create and configure session ───────────────────────────────────────
    duration = data.get("duration")
    if duration < 0:
        duration = 0

    session = StudySession(
        user_id=user_id,
        task_id=data.get("task_id"), # Optional: links to future tasks feature
        start_time=start_time,
        end_time=end_time,
        duration=duration,
        interruptions=int(data.get("interruptions", 0)),
        is_active=False
    )

    db.session.add(session)
    db.session.commit()

    # ── 3. Update analytics ─────────────────────────────────────────────────
    compute_and_save_daily_stats(user_id)

    return jsonify({
        "message": "Session recorded successfully",
        "session": session.to_dict()
    }), 201


# ── Interrupt (mid-session tap) ────────────────────────────────────────────────
# @session_bp.route("/<int:session_id>/interrupt", methods=["POST"])
# @jwt_required()
# def add_interruption(session_id: int):
#     """Increments the interruption counter without ending the session."""
#     user_id = int(get_jwt_identity())
#     session = StudySession.query.filter_by(id=session_id, user_id=user_id, is_active=True).first_or_404()
#     session.interruptions += 1
#     db.session.commit()
#     return jsonify({"interruptions": session.interruptions}), 200


# ── Get active session ─────────────────────────────────────────────────────────
# @session_bp.route("/active", methods=["GET"])
# @jwt_required()
# def get_active():
#     user_id = int(get_jwt_identity())
#     session = StudySession.query.filter_by(user_id=user_id, is_active=True).first()
#     if not session:
#         return jsonify({"active_session": None}), 200
#     return jsonify({"active_session": session.to_dict()}), 200


# ── Session history ────────────────────────────────────────────────────────────
@session_bp.route("/get_history", methods=["GET"])
@jwt_required()
def list_sessions():
    user_id = int(get_jwt_identity())
    page    = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)

    paginated = (
        StudySession.query
        .filter_by(user_id=user_id, is_active=False)
        .order_by(StudySession.start_time.desc())
        .paginate(page=page, per_page=per_page, error_out=False)
    )
    return jsonify({
        "sessions":    [s.to_dict() for s in paginated.items],
        "total":       paginated.total,
        "page":        paginated.page,
        "pages":       paginated.pages,
    }), 200

# AppButton(
#             text: AppStrings.startSessionButton,
#             onPressed: () {
#               setState(() {
#                 _isSessionExited = false;
#                 _isCompletionDialogShown = false;
#               });
#               provider.startSession();
#             },
#             isFullWidth: false,
#             icon: Icons.play_arrow_rounded,
#           ),
# suchet@gmail.com 12345678