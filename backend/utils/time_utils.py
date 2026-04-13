"""
utils/time_utils.py – Time & Duration Helpers
===============================================
Keep all date/time arithmetic in one place so service modules stay readable.
"""

from datetime import datetime, date, timedelta, timezone


def now_utc() -> datetime:
    """Return the current UTC datetime (timezone-aware)."""
    return datetime.now(timezone.utc)


def today() -> date:
    """Return today's local date."""
    return date.today()


def seconds_to_minutes(seconds: int) -> int:
    """Convert seconds to whole minutes."""
    return int(seconds // 60)


def minutes_to_seconds(minutes: int) -> int:
    return minutes * 60


def minutes_to_friendly(minutes: int) -> str:
    """
    Convert minutes to a human-readable string.
    Examples:
        90  → "1 hr 30 min"
        45  → "45 min"
        60  → "1 hr"
    """
    hours = minutes // 60
    mins  = minutes % 60
    if hours and mins:
        return f"{hours} hr {mins} min"
    if hours:
        return f"{hours} hr"
    return f"{mins} min"


def days_since(d: date) -> int:
    """Return how many days ago `d` was relative to today."""
    return (date.today() - d).days


def ensure_utc(dt: datetime) -> datetime:
    """Return `dt` with UTC timezone if it has no tzinfo."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def date_range(start: date, end: date):
    """Yield each date from `start` to `end` inclusive."""
    current = start
    while current <= end:
        yield current
        current += timedelta(days=1)
