"""
utils/helpers.py – General-Purpose Utility Functions
======================================================
Miscellaneous helpers that don't belong to a specific domain.
"""

from flask import jsonify
import re


# ── Response builders ──────────────────────────────────────────────────────────

def success(data: dict, status: int = 200):
    """Wrap data in a standard success envelope."""
    return jsonify({"status": "success", **data}), status


def error(message: str, status: int = 400):
    """Wrap a message in a standard error envelope."""
    return jsonify({"status": "error", "error": message}), status


# ── Validation ─────────────────────────────────────────────────────────────────

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

def is_valid_email(email: str) -> bool:
    return bool(EMAIL_RE.match(email))


def is_strong_password(password: str) -> bool:
    """
    Minimum requirements:
    • 8 characters
    • at least one digit
    • at least one letter
    """
    return (
        len(password) >= 8
        and any(c.isdigit() for c in password)
        and any(c.isalpha() for c in password)
    )


# ── Data helpers ───────────────────────────────────────────────────────────────

def paginate_list(items: list, page: int, per_page: int) -> dict:
    """
    Slice a plain Python list for manual pagination.
    (Use Flask-SQLAlchemy's .paginate() when working with ORM queries.)
    """
    total  = len(items)
    start  = (page - 1) * per_page
    end    = start + per_page
    return {
        "items":    items[start:end],
        "total":    total,
        "page":     page,
        "pages":    max(1, -(-total // per_page)),  # ceiling division
        "per_page": per_page,
    }


def clamp(value: float, lo: float, hi: float) -> float:
    """Constrain `value` to [lo, hi]."""
    return max(lo, min(hi, value))
