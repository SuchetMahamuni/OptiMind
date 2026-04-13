"""
models/user.py – User ORM Model
================================
Stores account credentials.  Passwords are NEVER stored in plain text —
only the hash produced by werkzeug.security is persisted.
"""

from datetime import datetime, timezone
from app import db


class User(db.Model):
    __tablename__ = "users"

    id         = db.Column(db.Integer, primary_key=True)
    name       = db.Column(db.String(100), nullable=False)
    email      = db.Column(db.String(150), unique=True, nullable=False, index=True)
    # werkzeug produces a ~93-char hash; 256 gives comfortable headroom.
    password_hash = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # ── Relationships ──────────────────────────────────────────────────────────
    tasks        = db.relationship("Task",         backref="owner",  lazy=True, cascade="all, delete-orphan")
    sessions     = db.relationship("StudySession", backref="owner",  lazy=True, cascade="all, delete-orphan")
    daily_stats  = db.relationship("DailyStats",   backref="owner",  lazy=True, cascade="all, delete-orphan")

    def to_dict(self) -> dict:
        """Safe serialisation — password hash is intentionally excluded."""
        return {
            "id":         self.id,
            "name":       self.name,
            "email":      self.email,
            "created_at": self.created_at.isoformat(),
        }

    def __repr__(self) -> str:
        return f"<User {self.email}>"
