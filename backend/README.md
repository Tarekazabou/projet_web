# Mealy Backend

Flask-based REST API for the Mealy recipe planning application.

## 📁 Project Structure

```
backend/
├── app.py                 # Main Flask application entry point
├── config.py              # Configuration settings
├── requirements.txt       # Python dependencies
├── .env                   # Environment variables (not in git)
│
├── routes/                # API endpoint blueprints
│   ├── __init__.py
│   ├── ai_recipes.py      # AI-powered recipe generation
│   ├── dashboard.py       # Dashboard data endpoints
│   ├── feedback.py        # User feedback endpoints
│   ├── fridge.py          # Fridge inventory management
│   ├── grocery.py         # Grocery list endpoints
│   ├── meal_plans.py      # Meal planning endpoints
│   ├── nutrition.py       # Nutrition tracking
│   ├── settings.py        # User settings
│   └── users.py           # User management
│
├── services/              # Business logic
│   ├── __init__.py
│   └── ai_service.py      # AI/Gemini integration
│
├── utils/                 # Utility functions
│   ├── __init__.py
│   ├── auth.py            # Authentication helpers
│   ├── firebase_connector.py  # Firebase/Firestore connection
│   └── response_handler.py    # API response formatting
│
├── tests/                 # Test files
│   ├── conftest.py
│   └── test_*.py
│
├── data/                  # Data storage (gitignored)
└── logs/                  # Application logs (gitignored)
```

## 🚀 Getting Started

### Prerequisites
- Python 3.10+
- Firebase project with Firestore
- Gemini API key

### Installation

```bash
cd backend
pip install -r requirements.txt
```

### Environment Variables

Create a `.env` file:
```env
FLASK_ENV=development
SECRET_KEY=your-secret-key
GEMINI_API_KEY=your-gemini-api-key
FIREBASE_PROJECT_ID=your-firebase-project
```

### Running the Server

```bash
python app.py
```

Server runs at `http://localhost:5000`

## 📡 API Endpoints

| Prefix | Blueprint | Description |
|--------|-----------|-------------|
| `/api/recipes` | ai_recipes | AI recipe generation |
| `/api/fridge` | fridge | Fridge inventory |
| `/api/meal-plans` | meal_plans | Meal planning |
| `/api/grocery-lists` | grocery | Grocery lists |
| `/api/nutrition` | nutrition | Nutrition tracking |
| `/api/users` | users | User management |
| `/api/settings` | settings | User settings |
| `/api/dashboard` | dashboard | Dashboard data |
| `/api/feedback` | feedback | User feedback |
| `/api/health` | - | Health check |

## 🔧 Development

### Running Tests
```bash
pytest tests/
```

### Code Structure
- **routes/**: Each file is a Flask Blueprint handling specific API endpoints
- **services/**: Business logic separated from routes
- **utils/**: Shared utilities (auth, database, response formatting)
