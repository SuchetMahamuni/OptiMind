"""
run.py – Development Server Entry-Point
========================================
Run with:
    python run.py

For production (Render / Railway / Fly.io) use gunicorn:
    gunicorn "app:create_app()"
"""

from app import create_app

app = create_app()

if __name__ == "__main__":
    # host="0.0.0.0" makes the API reachable from a phone on the same LAN,
    # which is handy when testing against a Flutter emulator / real device.
    app.run(host="0.0.0.0", port=5000, debug=True)
