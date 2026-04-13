"""
config.py – Centralised Application Configuration
===================================================
All runtime settings are read from environment variables (via .env in dev).
Add new Config subclasses (TestingConfig, ProductionConfig) as the project
grows without touching any other file.
"""

import os
from dotenv import load_dotenv

# Load .env file values into the environment (no-op in production where
# real env vars are injected by the host platform)
load_dotenv()


class Config:
    # ── Security ───────────────────────────────────────────────────────────────
    SECRET_KEY: str = os.getenv("SECRET_KEY", "dev-secret-change-me")
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "dev-jwt-secret-change-me")

    # ── Database ───────────────────────────────────────────────────────────────
    # SQLite path is relative to the project root; swap for a Postgres URL on
    # Render / Railway without any other code changes.
    SQLALCHEMY_DATABASE_URI: str = os.getenv(
        "DATABASE_URL", "sqlite:///optimind.db"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS: bool = False

    # ── JWT ────────────────────────────────────────────────────────────────────
    # Tokens expire after 7 days — good for mobile apps that stay logged in.
    JWT_ACCESS_TOKEN_EXPIRES: int = 60 * 60 * 24 * 7  # seconds

    # ── Flask ──────────────────────────────────────────────────────────────────
    DEBUG: bool = os.getenv("FLASK_ENV", "production") == "development"
