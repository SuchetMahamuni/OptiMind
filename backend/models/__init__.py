"""
models/__init__.py
==================
Re-exports every model so that `import models` in app.py pulls them all
into SQLAlchemy's metadata before db.create_all() is called.
"""

from models.user import User          # noqa: F401
from models.task import Task          # noqa: F401
from models.study_session import StudySession  # noqa: F401
from models.daily_stats import DailyStats      # noqa: F401
