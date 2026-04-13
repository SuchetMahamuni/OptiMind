"""
routes/task_routes.py – Task Management Endpoints
==================================================
All routes require a valid JWT.

GET    /api/tasks/         — list all tasks for the logged-in user
POST   /api/tasks/         — create a new task
PUT    /api/tasks/<id>     — update a task (partial update supported)
DELETE /api/tasks/<id>     — delete a task
PATCH  /api/tasks/<id>/complete — mark task as completed
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, timezone
from typing import Optional

from app import db
from models.task import Task

task_bp = Blueprint("tasks", __name__)


def _parse_deadline(raw: Optional[str]):
    """Parse ISO-8601 deadline string; returns a datetime or None."""
    if not raw:
        return None
    try:
        return datetime.fromisoformat(raw)
    except ValueError:
        return None


# ── List tasks ─────────────────────────────────────────────────────────────────
@task_bp.route("/", methods=["GET"])
@jwt_required()
def get_tasks():
    user_id = int(get_jwt_identity())
    tasks = Task.query.filter_by(user_id=user_id).order_by(Task.priority.desc(), Task.deadline).all()
    return jsonify({"tasks": [t.to_dict() for t in tasks]}), 200


# ── Create task ────────────────────────────────────────────────────────────────
@task_bp.route("/", methods=["POST"])
@jwt_required()
def create_task():
    """
    Body: {
        "subject":        str,                     # required
        "priority":       "low"|"medium"|"high",   # optional, default medium
        "deadline":       ISO-8601 string,          # optional
        "estimated_time": int (seconds)            # optional, default 60
    }
    """
    user_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}

    if not data.get("subject"):
        return jsonify({"error": "subject is required"}), 400

    task = Task(
        user_id=user_id,
        subject=data["subject"].strip(),
        priority=Task.priority_from_label(data.get("priority", "medium")),
        deadline=_parse_deadline(data.get("deadline")),
        estimated_time=int(data.get("estimated_time", 3600)),
    )
    db.session.add(task)
    db.session.commit()
    return jsonify({"task": task.to_dict()}), 201


# ── Update task (partial) ──────────────────────────────────────────────────────
@task_bp.route("/<int:task_id>", methods=["PUT"])
@jwt_required()
def update_task(task_id: int):
    user_id = int(get_jwt_identity())
    task = Task.query.filter_by(id=task_id, user_id=user_id).first_or_404()

    data = request.get_json(silent=True) or {}

    if "subject"        in data: task.subject        = data["subject"].strip()
    if "priority"       in data: task.priority       = Task.priority_from_label(data["priority"])
    if "deadline"       in data: task.deadline       = _parse_deadline(data["deadline"])
    if "estimated_time" in data: task.estimated_time = int(data["estimated_time"])
    if "is_completed"   in data: task.is_completed   = bool(data["is_completed"])

    db.session.commit()
    return jsonify({"task": task.to_dict()}), 200


# ── Mark complete ──────────────────────────────────────────────────────────────
@task_bp.route("/<int:task_id>/complete", methods=["PATCH"])
@jwt_required()
def complete_task(task_id: int):
    user_id = int(get_jwt_identity())
    task = Task.query.filter_by(id=task_id, user_id=user_id).first_or_404()
    task.is_completed = True
    db.session.commit()
    return jsonify({"task": task.to_dict()}), 200


# ── Delete task ────────────────────────────────────────────────────────────────
@task_bp.route("/<int:task_id>", methods=["DELETE"])
@jwt_required()
def delete_task(task_id: int):
    user_id = int(get_jwt_identity())
    task = Task.query.filter_by(id=task_id, user_id=user_id).first_or_404()
    db.session.delete(task)
    db.session.commit()
    return jsonify({"message": "Task deleted"}), 200
