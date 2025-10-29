# Backend Server - Running Guide

## Fixed Issues

### ✅ 1. Firestore Index Error
**Status**: FIXED
- Added composite indexes for Recipe collection queries
- Added indexes for MealPlan, NutritionLog, WaterIntake, FridgeItem, and GroceryList
- All indexes have been deployed to Firebase

### ✅ 2. Missing API Endpoints  
**Status**: FIXED
- Added all missing nutrition endpoints:
  - `GET /api/nutrition/goals` - Get user's nutrition goals
  - `POST /api/nutrition/goals` - Set nutrition goals
  - `GET /api/nutrition/daily/<date>` - Get daily nutrition data
  - `POST /api/nutrition/log-meal` - Log a meal
  - `DELETE /api/nutrition/meals/<meal_id>` - Delete meal log
  - `POST /api/nutrition/water-intake` - Log water intake

- Added grocery list endpoints:
  - `GET /api/grocery-lists` - Get all grocery lists
  - `POST /api/grocery-lists` - Create grocery list
  - `GET /api/grocery-lists/<id>` - Get specific list
  - `PUT /api/grocery-lists/<id>` - Update list
  - `DELETE /api/grocery-lists/<id>` - Delete list

- Added meal plan query endpoint:
  - `GET /api/meal-plans?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` - Get meal plans with date filtering

### ✅ 3. Socket Error on Reload
**Status**: FIXED
- Modified Flask development server to use 'stat' reloader (more stable on Windows)
- Added waitress server as an alternative (recommended for Windows)
- Created `run_server.py` script for easier server management

## Running the Server

### Option 1: Using Waitress (Recommended for Windows)
```powershell
cd backend
python run_server.py
```
This will start the server on http://0.0.0.0:5000 using Waitress, which is more stable on Windows and doesn't have socket reload issues.

### Option 2: Using Flask Development Server
```powershell
cd backend\src
python app.py
```
This will start the Flask development server with the 'stat' reloader to minimize socket errors.

### Option 3: Using VS Code Debugger
The existing launch configuration will work, but you might still see occasional socket errors on reload.

## Environment Variables

Create a `.env` file in the `backend` directory:
```env
FLASK_ENV=development
PORT=5000
SECRET_KEY=your-secret-key
USE_WAITRESS=true
```

## Testing the API

### Health Check
```powershell
curl http://localhost:5000/api/health
```

### Test Recipe Search
```powershell
curl "http://localhost:5000/api/recipes/search?q=chicken&sort_by=rating"
```

### Test Meal Plans (requires authentication)
```powershell
curl "http://localhost:5000/api/meal-plans?start_date=2025-10-01&end_date=2025-10-31"
```

## Complete API Endpoints

### Recipes
- `GET /api/recipes/search` - Search recipes
- `GET /api/recipes/<id>` - Get recipe by ID
- `POST /api/recipes` - Create recipe
- `PUT /api/recipes/<id>` - Update recipe
- `DELETE /api/recipes/<id>` - Delete recipe
- `GET /api/recipes/categories` - Get available categories

### Nutrition
- `POST /api/nutrition/analyze` - Analyze recipe nutrition
- `GET /api/nutrition/ingredients/search` - Search ingredients
- `GET /api/nutrition/ingredients/<id>` - Get ingredient details
- `GET /api/nutrition/goals` - Get nutrition goals
- `POST /api/nutrition/goals` - Set nutrition goals
- `GET /api/nutrition/daily/<date>` - Get daily nutrition
- `POST /api/nutrition/log-meal` - Log a meal
- `DELETE /api/nutrition/meals/<id>` - Delete meal log
- `POST /api/nutrition/water-intake` - Log water intake

### Meal Plans
- `GET /api/meal-plans` - Get meal plans (with date filtering)
- `POST /api/meal-plans` - Create meal plan
- `GET /api/meal-plans/<id>` - Get meal plan by ID
- `PUT /api/meal-plans/<id>` - Update meal plan
- `DELETE /api/meal-plans/<id>` - Delete meal plan
- `GET /api/meal-plans/user/<user_id>` - Get user's meal plans

### Grocery Lists
- `GET /api/grocery-lists` - Get all lists
- `POST /api/grocery-lists` - Create list
- `GET /api/grocery-lists/<id>` - Get list by ID
- `PUT /api/grocery-lists/<id>` - Update list
- `DELETE /api/grocery-lists/<id>` - Delete list
- `POST /api/grocery/generate` - Generate list from recipes

### Fridge
- `GET /api/fridge/items` - Get fridge items
- `POST /api/fridge/items` - Add fridge item
- `PUT /api/fridge/items/<id>` - Update item
- `DELETE /api/fridge/items/<id>` - Delete item

### Feedback
- `POST /api/feedback` - Submit feedback
- `GET /api/feedback/recipe/<id>` - Get recipe feedback
- `GET /api/feedback/user/<id>` - Get user feedback
- `DELETE /api/feedback/<id>` - Delete feedback

### Users
- `POST /api/users` - Create user
- `GET /api/users/<id>` - Get user
- `PUT /api/users/<id>` - Update user

## Notes

- Most endpoints require authentication (X-User-Id header)
- Firestore indexes may take a few minutes to build after deployment
- The waitress server doesn't support auto-reload - restart manually after code changes
- For development with auto-reload, use Flask's development server (Option 2)
