# Mealy (Flutter + Flask + Firebase)

Mealy is an AI-assisted meal planning app with:
- a **Flask** backend (Firestore + AI recipe generation)
- a **Flutter** mobile app (Android/iOS/Web)

## 📁 Repository structure

```
projet_web/
  backend/     # Flask API
  my_app/      # Flutter app
```

## ⚙️ Prerequisites

- Python 3.10+
- Flutter SDK (matches your app’s requirements in `my_app/`)
- A Firebase project (Firestore enabled)
- (Optional) Ollama for local LLM experiments

## 🚀 Quick start (Windows)

### 1) Backend (Flask API)

Create a virtualenv and install dependencies:

```bash
cd backend
py -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

Create `backend/.env` with at least:

```env
SECRET_KEY=dev-secret-key
FIREBASE_PROJECT_ID=mealy-41bf0
FIREBASE_CREDENTIAL_PATH=..\\mealy-41bf0-firebase-adminsdk-fbsvc-7d493e86ea.json
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Run the API:

```bash
python app.py
```


### 2) Flutter app

Install dependencies:

```bash
cd my_app
flutter pub get
```

Set the backend base URL in `my_app/lib/utils/constants.dart`:

- Android emulator: `http://10.0.2.2:5000/api`
- iOS simulator: `http://localhost:5000/api`
- Real device (same Wi‑Fi): `http://YOUR_PC_IP:5000/api`

Run:

```bash
flutter run
```

## 📡 Forward the backend to a real phone ("grok" / ngrok)

If your phone can’t reach your computer directly (different network, USB-only, etc.), you need a tunnel.

### Using ngrok (recommended)

1) Install ngrok and authenticate it (ngrok website instructions).
2) Start the tunnel:

```bash
ngrok http 5000
```

3) Copy the **https** forwarding URL and set:

```text
apiBaseUrl = https://YOUR_NGROK_DOMAIN/api
```

## 🧠 Ollama (optional)

This repo already includes the Python `ollama` client in `backend/requirements.txt`, but the backend currently uses **Gemini** for AI generation.

Install Ollama on Windows:
- Download and install from the official Ollama website.
- Verify installation:

```bash
ollama --version
```

Download and run a model:

```bash
ollama pull llama3.2
ollama run llama3.2
```

Ollama runs a local server (default `http://localhost:11434`).

## 🧪 Tests (backend)

```bash
cd backend
pytest
```

## Notes
- This repo contains a Firebase Admin service account JSON. Treat it as sensitive and avoid publishing it publicly.
- The backend's `/` route may reference a React build folder that isn't present in this workspace; the API endpoints under `/api/*` are the intended interface.
```
│   │   ├── pages/               # Page components
│   │   │   ├── HomePage.jsx
│   │   │   ├── YourFridgePage.jsx
│   │   │   ├── RecipeGeneratorPage.jsx
│   │   │   ├── MealPlannerPage.jsx
│   │   │   ├── NutritionTrackerPage.jsx
│   │   │   ├── GroceryListPage.jsx
│   │   │   └── LoginPage.jsx
│   │   ├── context/             # React Context
│   │   │   └── AuthContext.jsx
│   │   ├── services/            # API services
│   │   │   └── apiClient.js
│   │   ├── utils/               # Utilities
│   │   ├── config/              # Configuration
│   │   │   ├── api.js
│   │   │   └── firebase.js
│   │   ├── App.jsx              # Main app
│   │   └── main.jsx             # Entry point
│   ├── dist/                    # Production build
│   ├── package.json
│   ├── vite.config.js           # Vite config
│   └── README.md
├── frontend/                    # Legacy vanilla JS (deprecated)
├── backend/
│   ├── config.py                # Configuration management
│   ├── requirements.txt         # Python dependencies
│   ├── src/
│   │   └── app.py               # Main Flask app (serves React build)
│   ├── routes/                  # API endpoints
│   │   ├── ai_recipes.py       # AI recipe generation
│   │   ├── recipes.py          # Recipe CRUD
│   │   ├── users.py            # User management
│   │   └── ...
│   ├── services/               # Business logic
│   │   ├── ai_service.py       # Gemini AI integration
│   │   └── rag_service.py      # RAG system
│   ├── utils/                  # Utilities
│   │   ├── auth.py            # Authentication
│   │   ├── validators.py      # Input validation
│   │   ├── middleware.py      # Request/response middleware
│   │   ├── logging_config.py  # Logging setup
│   │   └── response_handler.py# Standardized responses
│   └── tests/                 # Test suite
│       ├── conftest.py        # Test fixtures
│       ├── test_*.py          # Test files
│       └── integration/       # Integration tests
├── frontend/
│   ├── index.html
│   ├── js/
│   │   ├── app.js             # Main app controller
│   │   ├── auth.js            # Authentication
│   │   ├── recipe-generator.js
│   │   └── ...
│   └── css/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # CI/CD pipeline
├── Dockerfile                 # Production container
├── docker-compose.yml         # Development stack
└── README.md
```

## 📚 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication
```bash
# Include X-User-Id header for all requests
X-User-Id: <user_id>
```

### Core Endpoints

#### Health Check
```http
GET /api/health
```

#### Fridge Management
```http
GET  /api/fridge/items          # Get all fridge items
POST /api/fridge/items          # Add item to fridge
DELETE /api/fridge/items/{id}   # Remove item from fridge
```

#### AI Recipe Generation
```http
POST /api/recipes/generate-with-ai
Content-Type: application/json

{
  "ingredients": ["chicken", "tomatoes"],
  "dietary_preferences": ["healthy"],
  "max_cooking_time": 45,
  "servings": 4
}
```

#### Meal Plans
```http
GET  /api/meal-plans/                    # Get all meal plans
GET  /api/meal-plans/week?start_date=    # Get weekly meal plans
POST /api/meal-plans/                    # Create meal plan
DELETE /api/meal-plans/{id}              # Delete meal plan
POST /api/meal-plans/ai-suggest          # Get AI meal suggestions
POST /api/meal-plans/generate-grocery    # Generate grocery from plans
```

#### Grocery Lists
```http
GET  /api/grocery/items                  # Get grocery items
POST /api/grocery/items                  # Add grocery item
PUT  /api/grocery/items/{index}          # Update item
DELETE /api/grocery/items/{index}        # Delete item
POST /api/grocery/toggle-purchased/{idx} # Toggle purchased status
POST /api/grocery/clear-purchased        # Clear all purchased items
POST /api/grocery/from-meal-plan         # Create list from meal plan
```

#### Nutrition Tracking
```http
GET /api/nutrition/daily/{date}          # Get daily nutrition
GET /api/nutrition/weekly                # Get weekly summary
POST /api/nutrition/log-meal             # Log a meal
```

See [API Documentation](docs/API.md) for complete reference.


## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.
