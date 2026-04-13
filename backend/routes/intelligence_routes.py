"""
routes/intelligence_routes.py – Intelligence / AI-layer Endpoints
==================================================================
These endpoints expose the outputs of the rule engine, scoring system,
and adaptive goal planner.  When you later swap rule-based logic for ML
models, only the service layer changes — routes stay identical.

GET /api/nudge        — behavioural nudge for the user right now
GET /api/focus-score  — current focus score (0–100)
GET /api/daily-goal   — adaptive daily study goal in minutes
"""

from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from services.rule_engine import get_nudge
from services.scoring import get_focus_score, get_consistency_score
from services.adaptive_goal import get_daily_goal

intelligence_bp = Blueprint("intelligence", __name__)


# ── Nudge ──────────────────────────────────────────────────────────────────────
@intelligence_bp.route("/nudge", methods=["GET"])
@jwt_required()
def nudge():
    """
    Returns a contextual behavioural nudge based on the user's current
    study pattern.  Example response:
        {
            "nudge": "You haven't studied Physics in 3 days — time to revisit it!",
            "type":  "reminder"
        }
    """
    user_id = int(get_jwt_identity())
    result  = get_nudge(user_id)
    return jsonify(result), 200


# ── Focus Score ────────────────────────────────────────────────────────────────
@intelligence_bp.route("/focus-score", methods=["GET"])
@jwt_required()
def focus_score():
    """
    Returns the user's current focus score (0–100) and its breakdown.
    Example response:
        {
            "focus_score":       72.5,
            "consistency_score": 60.0,
            "breakdown": {
                "session_completion": 80,
                "interruption_penalty": 15,
                "balance_bonus": 10
            }
        }
    """
    user_id        = int(get_jwt_identity())
    f_score        = get_focus_score(user_id)
    c_score        = get_consistency_score(user_id)

    return jsonify({
        "focus_score":       f_score["score"],
        "consistency_score": c_score,
        "breakdown":         f_score.get("breakdown", {}),
    }), 200


# ── Daily Adaptive Goal ────────────────────────────────────────────────────────
@intelligence_bp.route("/daily-goal", methods=["GET"])
@jwt_required()
def daily_goal():
    """
    Returns a suggested study goal for today in minutes.
    Example response:
        {
            "goal_minutes": 120,
            "rationale":    "Based on your 90-min average and 2 pending tasks."
        }
    """
    user_id = int(get_jwt_identity())
    result  = get_daily_goal(user_id)
    return jsonify(result), 200
