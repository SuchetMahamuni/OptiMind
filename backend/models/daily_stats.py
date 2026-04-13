"""
models/daily_stats.py – DailyStats ORM Model
=============================================
One row per user per calendar day.  Scores are computed by
services/scoring.py and written here so the dashboard can read them
cheaply without re-computing anything.
"""

from datetime import datetime, date, timezone
from app import db


class DailyStats(db.Model):
    __tablename__ = "daily_stats"

    id                = db.Column(db.Integer, primary_key=True)
    user_id           = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    date              = db.Column(db.Date,    nullable=False,
                                  default=lambda: datetime.now(timezone.utc).date())
    total_study_time  = db.Column(db.Integer, default=0)    # seconds
    focus_score       = db.Column(db.Float,   default=0.0)  # 0–100
    consistency_score = db.Column(db.Float,   default=0.0)  # 0–100

    # Unique constraint: one stats row per user per day.
    __table_args__ = (
        db.UniqueConstraint("user_id", "date", name="uq_user_date"),
    )

    def to_dict(self) -> dict:
        return {
            "id":                self.id,
            "user_id":           self.user_id,
            "date":              self.date.isoformat(),
            "total_study_time":  self.total_study_time,   # seconds
            "focus_score":       round(self.focus_score, 2),
            "consistency_score": round(self.consistency_score, 2),
        }

    def __repr__(self) -> str:
        return f"<DailyStats user={self.user_id} date={self.date}>"
