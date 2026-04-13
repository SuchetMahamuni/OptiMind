"""
models/task.py – Task ORM Model
================================
Represents a study task created by a user, e.g. "Revise Chapter 3 – Physics".
Priority is stored as 1 (low) / 2 (medium) / 3 (high) so it can be sorted
numerically; the API layer can accept string labels and convert them.
"""

from datetime import datetime, timezone
from app import db


class Task(db.Model):
    __tablename__ = "tasks"

    id             = db.Column(db.Integer, primary_key=True)
    user_id        = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    subject        = db.Column(db.String(150), nullable=False)
    priority       = db.Column(db.Integer, default=2)        # 1=low, 2=medium, 3=high
    deadline       = db.Column(db.DateTime, nullable=True)   # optional hard deadline
    estimated_time = db.Column(db.Integer, default=60)       # in minutes
    is_completed   = db.Column(db.Boolean, default=False)
    created_at     = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # ── Relationships ──────────────────────────────────────────────────────────
    sessions = db.relationship("StudySession", backref="task", lazy=True, cascade="all, delete-orphan")

    # ── Priority helpers ───────────────────────────────────────────────────────
    PRIORITY_MAP  = {"low": 1, "medium": 2, "high": 3}
    PRIORITY_RMAP = {1: "low", 2: "medium", 3: "high"}

    @classmethod
    def priority_from_label(cls, label: str) -> int:
        return cls.PRIORITY_MAP.get(label.lower(), 2)

    def to_dict(self) -> dict:
        total_seconds = sum(s.duration for s in self.sessions if s.duration)
        estimated_seconds = self.estimated_time # Estimated time is already in seconds
        progress = (total_seconds / estimated_seconds) if estimated_seconds > 0 else 0
        print(f"Subject:{self.subject}\nSeconds elapsed: {total_seconds}\nTotal ETA: {estimated_seconds}\nProgress:{progress}")
        progress = min(progress, 1.0)  # Cap at 100% visually

        return {
            "id":             self.id,
            "user_id":        self.user_id,
            "subject":        self.subject,
            "priority":       self.PRIORITY_RMAP.get(self.priority, "medium"),
            "deadline":       self.deadline.isoformat() if self.deadline else None,
            "estimated_time": self.estimated_time,
            "is_completed":   self.is_completed,
            "created_at":     self.created_at.isoformat(),
            "total_seconds_spent": total_seconds,
            "progress_percentage": progress,
        }

    def __repr__(self) -> str:
        return f"<Task {self.subject!r} user={self.user_id}>"
