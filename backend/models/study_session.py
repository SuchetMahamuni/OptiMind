"""
models/study_session.py – StudySession ORM Model
=================================================
Tracks a single contiguous study block.  The Flutter client calls
POST /sessions/start when the user begins and POST /sessions/end when
they stop (or when they are interrupted and choose to end).

duration      – computed in seconds when the session ends.
interruptions – count of times the user tapped "I got distracted".
"""

from datetime import datetime, timezone
from app import db


class StudySession(db.Model):
    __tablename__ = "study_sessions"

    id            = db.Column(db.Integer, primary_key=True)
    user_id       = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    task_id       = db.Column(db.Integer, db.ForeignKey("tasks.id"), nullable=True)
    start_time    = db.Column(db.DateTime, nullable=False,
                              default=lambda: datetime.now(timezone.utc))
    end_time      = db.Column(db.DateTime, nullable=True)
    duration      = db.Column(db.Integer, nullable=True)   # seconds; filled on /end
    interruptions = db.Column(db.Integer, default=0)
    is_active     = db.Column(db.Boolean, default=True)    # False after /end

    def to_dict(self) -> dict:
        return {
            "id":            self.id,
            "user_id":       self.user_id,
            "task_id":       self.task_id,
            "start_time":    self.start_time.isoformat(),
            "end_time":      self.end_time.isoformat() if self.end_time else None,
            "duration":      self.duration,       # seconds
            "interruptions": self.interruptions,
            "is_active":     self.is_active,
        }

    def __repr__(self) -> str:
        return f"<StudySession id={self.id} user={self.user_id} active={self.is_active}>"
