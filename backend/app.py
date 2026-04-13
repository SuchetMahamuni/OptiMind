"""
OptiMind – Application Factory
===============================
Entry-point that wires together Flask, SQLAlchemy, JWT, and all blueprints.
Keeping startup logic here makes the app easy to test and deploy on any WSGI
host (Render, Railway, Fly.io …).
"""

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager

# ──────────────────────────────────────────────────────────────────────────────
# Shared extension instances (imported by models / routes as needed)
# ──────────────────────────────────────────────────────────────────────────────
db = SQLAlchemy()
jwt = JWTManager()


def create_app():
    """Application factory – returns a fully configured Flask instance."""
    app = Flask(__name__)

    # ── Configuration ──────────────────────────────────────────────────────────
    from config import Config
    app.config.from_object(Config)

    # ── Initialise extensions ──────────────────────────────────────────────────
    db.init_app(app)
    jwt.init_app(app)

    # ── Register blueprints ────────────────────────────────────────────────────
    from routes.auth_routes import auth_bp
    from routes.task_routes import task_bp
    from routes.session_routes import session_bp
    from routes.dashboard_routes import dashboard_bp
    from routes.intelligence_routes import intelligence_bp

    app.register_blueprint(auth_bp,         url_prefix="/api/auth")
    app.register_blueprint(task_bp,         url_prefix="/api/tasks")
    app.register_blueprint(session_bp,      url_prefix="/api/sessions")
    app.register_blueprint(dashboard_bp,    url_prefix="/api/dashboard")
    app.register_blueprint(intelligence_bp, url_prefix="/api")

    # ── Create database tables on first run ────────────────────────────────────
    with app.app_context():
        # Import all models so SQLAlchemy knows about them before create_all()
        import models  # noqa: F401
        db.create_all()

    return app
