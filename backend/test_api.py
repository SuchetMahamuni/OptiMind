"""
test_api.py - End-to-end smoke test for OptiMind backend.
Run with: venv\Scripts\python test_api.py
(Server must already be running on port 5000)

Uses a timestamped email so it is safe to run multiple times.
"""
import requests
import time

BASE = "http://127.0.0.1:5000/api"

def check(label, condition, detail=""):
    icon = "PASS" if condition else "FAIL"
    suffix = f"  [{detail}]" if detail else ""
    print(f"  {icon}  {label}{suffix}")
    return bool(condition)

results = []
print("\n=== OptiMind API Smoke Test ===\n")

# Use a unique email per run so the DB doesn't reject duplicate registrations
unique_email = f"alice_{int(time.time())}@test.com"

# ── 1. Auth ────────────────────────────────────────────────────────────────────
print("1. Auth")

r = requests.post(f"{BASE}/auth/register", json={
    "name": "Alice", "email": unique_email, "password": "secret123"
})
results.append(check("Register user", r.status_code == 201, r.status_code))

# Always get a fresh token via login so subsequent steps don't depend on register
r = requests.post(f"{BASE}/auth/login", json={
    "email": unique_email, "password": "secret123"
})
results.append(check("Login", r.status_code == 200, r.status_code))
results.append(check("JWT token returned", bool(r.json().get("access_token"))))

token = r.json().get("access_token", "")
H = {"Authorization": f"Bearer {token}"}

r = requests.get(f"{BASE}/auth/me", headers=H)
results.append(check(
    "GET /me",
    r.status_code == 200,
    r.json().get("user", {}).get("email", "no email")
))

# ── 2. Tasks ───────────────────────────────────────────────────────────────────
print("\n2. Tasks")

r = requests.post(f"{BASE}/tasks/", headers=H, json={
    "subject": "Organic Chemistry",
    "priority": "high",
    "estimated_time": 90,
})
results.append(check("Create task", r.status_code == 201,
                     r.json().get("task", {}).get("subject", "?")))
task_id = r.json().get("task", {}).get("id")

r = requests.get(f"{BASE}/tasks/", headers=H)
results.append(check("List tasks", r.status_code == 200,
                     f"{len(r.json().get('tasks', []))} task(s)"))

r = requests.put(f"{BASE}/tasks/{task_id}", headers=H, json={"priority": "medium"})
results.append(check("Update task", r.status_code == 200,
                     r.json().get("task", {}).get("priority", "?")))

r = requests.patch(f"{BASE}/tasks/{task_id}/complete", headers=H)
results.append(check("Complete task",
                     r.status_code == 200 and r.json().get("task", {}).get("is_completed") is True))

# ── 3. Study Sessions ──────────────────────────────────────────────────────────
print("\n3. Study Sessions")

# Create a fresh (incomplete) task to link to the session
r2 = requests.post(f"{BASE}/tasks/", headers=H, json={"subject": "Physics"})
task_id2 = r2.json().get("task", {}).get("id")

r = requests.post(f"{BASE}/sessions/start", headers=H, json={"task_id": task_id2})
results.append(check("Start session", r.status_code == 201,
                     f"active={r.json().get('session', {}).get('is_active')}"))
session_id = r.json().get("session", {}).get("id")

r = requests.post(f"{BASE}/sessions/{session_id}/interrupt", headers=H)
results.append(check("Log interruption", r.status_code == 200,
                     f"interruptions={r.json().get('interruptions')}"))

r = requests.get(f"{BASE}/sessions/active", headers=H)
results.append(check("GET active session", r.status_code == 200,
                     f"id={r.json().get('active_session', {}).get('id')}"))

r = requests.post(f"{BASE}/sessions/end", headers=H, json={"interruptions": 1})
results.append(check("End session", r.status_code == 200,
                     f"duration={r.json().get('session', {}).get('duration')}s"))

r = requests.get(f"{BASE}/sessions/", headers=H)
results.append(check("List sessions history", r.status_code == 200,
                     f"total={r.json().get('total')}"))

# ── 4. Dashboard ───────────────────────────────────────────────────────────────
print("\n4. Dashboard")

r = requests.get(f"{BASE}/dashboard/stats", headers=H)
stats = r.json().get("stats", {})
results.append(check("GET today stats", r.status_code == 200,
                     f"study_time={stats.get('total_study_time')}s  "
                     f"focus={stats.get('focus_score')}"))

r = requests.get(f"{BASE}/dashboard/summary", headers=H)
summary = r.json().get("summary", {})
results.append(check("GET productivity summary", r.status_code == 200,
                     f"streak={summary.get('current_streak')}d  "
                     f"weekly={summary.get('weekly_study_time')}s"))

r = requests.get(f"{BASE}/dashboard/stats/history?days=7", headers=H)
results.append(check("GET stats history (7d)", r.status_code == 200,
                     f"{len(r.json().get('history', []))} record(s)"))

# ── 5. Intelligence Layer ──────────────────────────────────────────────────────
print("\n5. Intelligence")

r = requests.get(f"{BASE}/nudge", headers=H)
nudge = r.json()
results.append(check("GET /nudge", r.status_code == 200 and "nudge" in nudge,
                     f"type={nudge.get('type')}  msg='{nudge.get('nudge', '')[:50]}'"))

r = requests.get(f"{BASE}/focus-score", headers=H)
fs = r.json()
results.append(check("GET /focus-score", r.status_code == 200,
                     f"focus={fs.get('focus_score')}  "
                     f"consistency={fs.get('consistency_score')}"))

r = requests.get(f"{BASE}/daily-goal", headers=H)
dg = r.json()
results.append(check("GET /daily-goal", r.status_code == 200,
                     f"goal={dg.get('goal_minutes')} min  "
                     f"rationale='{dg.get('rationale', '')[:50]}'"))

# ── 6. Edge-case: duplicate session guard ──────────────────────────────────────
print("\n6. Edge Cases")

requests.post(f"{BASE}/sessions/start", headers=H, json={})  # open one session
r = requests.post(f"{BASE}/sessions/start", headers=H, json={})  # try to open another
results.append(check("Reject double-start session", r.status_code == 409,
                     r.json().get("error", "?")))
requests.post(f"{BASE}/sessions/end", headers=H)  # clean up

r = requests.delete(f"{BASE}/tasks/{task_id}", headers=H)
results.append(check("Delete task", r.status_code == 200,
                     r.json().get("message", "?")))

# ── Summary ────────────────────────────────────────────────────────────────────
passed = sum(results)
total  = len(results)
print(f"\n{'=' * 45}")
print(f"  Result: {passed}/{total} tests passed")
if passed == total:
    print("  >>> All systems go! <<<")
else:
    print(f"  *** {total - passed} test(s) FAILED — see above ***")
print("=" * 45)

# Fail the process so CI catches regressions
raise SystemExit(0 if passed == total else 1)
