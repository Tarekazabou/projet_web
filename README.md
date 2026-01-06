# Mealy (Flutter + Flask + Firebase)

Mealy is an AI-assisted meal planning app with:
- a **Flask** backend (Firestore + AI recipe generation)
- a **Flutter** mobile app (Android/iOS/Web)

## 📁 Repository structure

```
projet_web/
├── backend/                    
│   ├── app.py                 
│   ├── config.py              
│   ├── requirements.txt       
│   ├── pyproject.toml         
│   ├── routes/                
│   │   ├── __init__.py
│   │   ├── ai_recipes.py      
│   │   ├── dashboard.py       
│   │   ├── food_scanner.py    
│   │   ├── fridge.py          
│   │   ├── grocery.py         
│   │   ├── meal_plans.py      
│   │   ├── nutrition.py      
│   │   ├── receipt_scanner.py 
│   │   └── users.py           
│   ├── services/              
│   │   ├── __init__.py
│   │   └── ai_service.py     
│   ├── utils/                
│   │   ├── __init__.py
│   │   ├── auth.py          
│   │   ├── firebase_connector.py 
│   │   └── response_handler.py   
│   ├── data/                 
│   └── tests/                
├── my_app/                   
│   ├── lib/
│   │   ├── main.dart          
│   │   ├── models/            
│   │   │   ├── user.dart
│   │   │   ├── recipe.dart
│   │   │   ├── fridge_item.dart
│   │   │   ├── meal_plan.dart
│   │   │   ├── grocery_item.dart
│   │   │   └── tab_icon_data.dart
│   │   ├── providers/         
│   │   │   ├── auth_provider.dart
│   │   │   ├── fridge_provider.dart
│   │   │   ├── recipe_provider.dart
│   │   │   ├── meal_plan_provider.dart
│   │   │   ├── grocery_provider.dart
│   │   │   ├── nutrition_provider.dart
│   │   │   └── dashboard_provider.dart
│   │   ├── screens/           
│   │   │   ├── home_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── fridge_screen.dart
│   │   │   ├── recipe_generator_screen.dart
│   │   │   ├── meal_planner_screen.dart
│   │   │   ├── grocery_list_screen.dart
│   │   │   ├── nutrition_screen.dart
│   │   │   └── profile_screen.dart
│   │   ├── services/        
│   │   │   └── api_service.dart
│   │   ├── utils/            
│   │   │   ├── constants.dart
│   │   │   ├── logger.dart
│   │   │   ├── extensions.dart
│   │   │   ├── app_theme.dart
│   │   │   ├── mealy_theme.dart
│   │   │   └── validators.dart
│   │   ├── widgets/           # Reusable components
│   │   │   ├── recipe_card.dart
│   │   │   ├── recipe_detail_sheet.dart
│   │   │   ├── meal_slot_card.dart
│   │   │   ├── grocery_item_tile.dart
│   │   │   ├── bottom_bar_view.dart
│   │   │   ├── app_buttons.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── empty_state_widget.dart
│   │   │   ├── gradient_scaffold.dart
│   │   │   └── loading_widgets.dart
│   │   └── firebase_options.dart 
│   ├── android/             
│   ├── ios/                   
│   ├── web/                 
│   ├── windows/               
│   ├── linux/                 
│   ├── macos/                 
│   ├── assets/                
│   ├── test/                  
│   ├── pubspec.yaml          
│   └── README.md
├── .github/              
├── firebase.json            
├── firestore.indexes.json   
├── firestore.rules           
├── renovate.json              
└── README.md                  
```

## ⚙️ Prerequisites

- Python 3.10+
- Flutter SDK (matches your app's requirements in `my_app/`)
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
FIREBASE_CREDENTIAL_PATH=..\mealy-41bf0-firebase-adminsdk-fbsvc-7d493e86ea.json
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

If your phone can't reach your computer directly (different network, USB-only, etc.), you need a tunnel.

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

## Notes
- This repo contains a Firebase Admin service account JSON. Treat it as sensitive and avoid publishing it publicly.
- The backend's `/` route may reference a React build folder that isn't present in this workspace; the API endpoints under `/api/*` are the intended interface.

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.
