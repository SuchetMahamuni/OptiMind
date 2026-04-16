# 🚀 OptiMind – Study Productivity Booster

**OptiMind** is a behavior-driven study productivity application designed to help students stay consistent, avoid burnout, and improve focus through intelligent tracking, feedback, and insights.

Unlike traditional to-do or timer apps, OptiMind focuses on maintaining an **optimal productivity balance** using structured workflows, smart nudges, and performance analytics.

---

## 🧠 Core Idea

Students often struggle with:

* ❌ Overworking → Burnout
* ❌ Underworking → Procrastination

OptiMind solves this by keeping users in their:

> ⚡ **Optimal Productivity Zone**

---

## ✨ Features

### 📋 Task Management

* Create, update, and delete study tasks
* Set priorities, deadlines, and estimated time
* Track real-time progress through session integration

---

### ⏱️ Study Sessions

* Start, pause, resume, and stop sessions
* Track interruptions during sessions
* Task-linked sessions for structured progress
* Visual progress indicators (time-based completion)

---

### 📊 Dashboard

* Focus Score (0–100) based on performance
* Daily study goal (adaptive or user-defined)
* Smart nudges based on behavior
* Real-time study summaries

---

### 🔔 Intelligent Nudges

* Prevent burnout and laziness
* Context-aware suggestions
* Rule-based behavior correction system

---

### 📜 Session History

* View all completed sessions
* Track duration and interruptions
* Analyze study consistency

---

### 📈 Insights (Key Differentiator 🔥)

OptiMind provides meaningful analytics to help users understand and improve their study behavior:

* 🔥 **Streak Tracking** – Maintain consistency over time
* 📊 **Study Time Analysis** – Daily, weekly, and monthly trends
* 🎯 **Focus Score Trends** – Track improvement in focus quality
* ⚠️ **Interruptions Analysis** – Understand distractions
* 📋 **Task Contribution** – Time spent progressing on tasks

> These insights transform raw data into actionable understanding.

---

### ⚙️ Settings

* Custom daily study goals
* Persistent login
* User preferences

---

## 🧱 Tech Stack

### 📱 Frontend

* Flutter (Dart)
* Provider (State Management)
* Hive (Local Storage)

### 🧠 Backend

* Flask (Python)
* SQLAlchemy (ORM)
* SQLite (Development DB)
* JWT Authentication

---

## 🏗️ Project Structure

### Frontend (Flutter)

```
lib/
├── core/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── tasks/
│   ├── sessions/
│   ├── insights/
├── providers/
├── services/
├── widgets/
```

---

### Backend (Flask)

```
backend/
├── routes/
├── models/
├── services/
├── utils/
├── app.py
├── config.py
```

---

## ⚙️ Setup Instructions

### 🔧 Backend Setup

1. Clone repository:

```bash
git clone https://github.com/SuchetMahamuni/OptiMind.git
cd backend
```

2. Create virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # (Linux/Mac)
venv\Scripts\activate     # (Windows)
```

3. Install dependencies:

```bash
pip install -r requirements.txt
```

4. Run server:

```bash
python app.py
```

---

### 📱 Frontend Setup

1. Navigate to frontend:

```bash
cd optimind_app
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run app:

```bash
flutter run
```

---

## 🌐 Deployment

* Backend deployed on **PythonAnywhere**
* Frontend runs on Android/iOS devices

---

## 🔮 Future Scope

* Machine Learning-based recommendations
* Advanced behavioral analytics
* Calendar & event integration
* Voice-based interaction
* Smart habit tracking

---

## 👨‍💻 Author

Developed by **Suchet Mahamuni**

---

## 💡 Philosophy

> “Optimize your focus. Balance your grind.”
