"""
routes/auth_routes.py – Authentication Endpoints
=================================================
POST /api/auth/register  — create account
POST /api/auth/login     — exchange credentials for a JWT
GET  /api/auth/me        — return the profile of the logged-in user
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash

from app import db
from models.user import User

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/")
def auth_health():
    return jsonify({"message": "Auth is alive"}), 200


# ── Register ───────────────────────────────────────────────────────────────────
@auth_bp.route("/register", methods=["POST"])
def register():
    """
    Body: { "name": str, "email": str, "password": str }
    Returns: user dict + JWT access token
    """
    data = request.get_json(silent=True) or {}

    # ── Validate required fields ───────────────────────────────────────────────
    missing = [f for f in ("name", "email", "password") if not data.get(f)]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    if User.query.filter_by(email=data["email"].lower()).first():
        return jsonify({"error": "Email already registered"}), 409

    user = User(
        name=data["name"].strip(),
        email=data["email"].lower().strip(),
        password_hash=generate_password_hash(data["password"]),
    )
    db.session.add(user)
    db.session.commit()

    token = create_access_token(identity=str(user.id))
    return jsonify({"user": user.to_dict(), "access_token": token}), 201


# ── Login ──────────────────────────────────────────────────────────────────────
@auth_bp.route("/login", methods=["POST"])
def login():
    """
    Body: { "email": str, "password": str }
    Returns: user dict + JWT access token
    """
    data = request.get_json(silent=True) or {}

    email    = data.get("email", "").lower().strip()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({"error": "Email and password are required"}), 400

    user = User.query.filter_by(email=email).first()
    if not user or not check_password_hash(user.password_hash, password):
        return jsonify({"error": "Invalid credentials"}), 401

    token = create_access_token(identity=str(user.id))
    return jsonify({"user": user.to_dict(), "access_token": token}), 200


# ── Profile ────────────────────────────────────────────────────────────────────
@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def me():
    """Returns the profile of the currently authenticated user."""
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)
    return jsonify({"user": user.to_dict()}), 200
