# Mealy Backend (Flask API)

Flask REST API for Mealy (Firestore + AI recipe generation + meal planning).

## 📁 Project structure

```
backend/
	app.py
	config.py
	requirements.txt
	routes/
		ai_recipes.py
		dashboard.py
		food_scanner.py
		fridge.py
		grocery.py
		meal_plans.py
		nutrition.py
		receipt_scanner.py
		users.py
	services/
		ai_service.py
	utils/
		auth.py
		firebase_connector.py
		response_handler.py
	tests/
		test_*.py
```

## ✅ Prerequisites

- Python 3.10+
- Firebase project (Firestore enabled)
- Gemini API key (for AI generation endpoints)

## 🚀 Setup

### Install dependencies

```bash
cd backend
py -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

### Environment variables

Create `backend/.env`:

```env
FLASK_ENV=development
SECRET_KEY=dev-secret-key

# Firebase
FIREBASE_PROJECT_ID=mealy-41bf0
FIREBASE_CREDENTIAL_PATH=..\\mealy-41bf0-firebase-adminsdk-fbsvc-7d493e86ea.json

# AI (Gemini)
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Notes:
- If `FIREBASE_CREDENTIAL_PATH` is missing or invalid, the backend falls back to Application Default Credentials.
- If `GEMINI_API_KEY` is missing, AI endpoints will return a “service not initialized” error.

## ▶️ Run

### Development (Windows)

```bash
cd backend
python app.py
```

### Production-style server on Windows (recommended)

`gunicorn` is primarily for Linux/WSL. On Windows you can use `waitress` (already in requirements):

```bash
cd backend
python -m waitress --listen=0.0.0.0:5000 app:app
```

Health check:

```text
GET http://localhost:5000/api/health
```

## 📡 API overview

Registered prefixes (see `backend/app.py`):

| Prefix | Purpose |
|--------|---------|
| `/api/recipes` | AI recipe generation + listing |
| `/api/fridge` | Fridge inventory + recipe suggestions |
| `/api/meal-plans` | Meal planning + AI suggestions |
| `/api/grocery` | Grocery list + stats |
| `/api/nutrition` | Nutrition goals + daily logs |
| `/api/users` | Register/login |
| `/api/dashboard` | Dashboard data |
| `/api/receipt` | Receipt scanning |
| `/api/food` | Food scanning |
| `/api/health` | Health check |

## 🧪 Tests

```bash
cd backend
pytest
```
