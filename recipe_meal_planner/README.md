# 🍽️ Personalized Recipe and Meal Planning App (Firebase Edition)

A comprehensive web application for personalized recipe generation, meal planning, nutrition tracking, fridge inventory management, and grocery list organization with AI-powered recommendations. Your complete kitchen companion for smarter cooking and healthier eating!

## ✨ Key Features Overview

### 🍳 AI-Powered Recipe Search
- **Smart Recipe Matching**: Advanced ingredient-based recipe discovery
- **Dietary Intelligence**: Support for 20+ dietary preferences (vegan, keto, gluten-free, paleo, etc.)
- **Cooking Customization**: Filter by prep time, difficulty, and cooking method
- **Nutritional Analysis**: Real-time nutrition facts and health scoring
- **Personalized Recommendations**: Learn from your preferences and cooking history

### 🥬 Your Fridge - Smart Inventory Management
- **Digital Pantry**: Track all ingredients in your fridge, freezer, and pantry
- **Expiration Tracking**: Never waste food with smart expiry date monitoring
- **Category Organization**: Organize items by type (produce, dairy, meat, frozen, etc.)
- **Recipe Suggestions**: Get recipe recommendations based on available ingredients
- **Bulk Import**: Quick addition of multiple items
- **Freshness Alerts**: Visual indicators for fresh, expiring soon, and expired items

### 📅 Intelligent Meal Planning
- **Manual Meal Plans**: Manually create balanced weekly meal schedules
- **Drag-and-Drop Interface**: Easy meal scheduling with visual calendar
- **Fridge Integration**: Plan meals using ingredients you already have
- **Export & Share**: Share meal plans with family and friends

### 📊 Advanced Nutrition Tracking
- **Daily Monitoring**: Track calories, macros, vitamins, and minerals
- **Goal Setting**: Personalized nutrition targets based on health goals
- **Progress Analytics**: Visual progress tracking with charts and insights
- **Water Intake**: Hydration tracking with smart reminders

### 🛒 Smart Grocery Management
- **Auto-Generation**: Create shopping lists from meal plans and low fridge inventory
- **Category Organization**: Organize by store layout for efficient shopping
- **Family Sharing**: Collaborative shopping lists for households
- **Pantry Sync**: Automatically update fridge inventory after shopping

## 🏗️ Technology Stack

### Backend Architecture
- **Framework**: Flask 2.3.3 with Blueprint modular design
- **Database**: Google Cloud Firestore for scalable, real-time data storage
- **Firebase Services**: Firebase Admin SDK for backend integration
- **Authentication**: Firebase-based user management
- **Data Models**: Comprehensive schemas for recipes, users, meal plans, and fridge inventory

### Frontend Technology
- **HTML5**: Semantic markup with ARIA accessibility features
- **CSS3**: Modern styling with CSS Grid, Flexbox, custom properties, and smooth animations
- **JavaScript**: Vanilla ES6+ with modular architecture and async/await patterns
- **UI Components**: Custom reusable component system
- **Responsive Design**: Mobile-first approach with breakpoint optimization

### Development Tools
- **Version Control**: Git with conventional commits
- **Package Management**: pip for Python dependencies
- **Environment**: Virtual environment support
- **Code Quality**: ESLint, Prettier, and Python Black formatting

## Project Structure

```
recipe_meal_planner/
├── app.py                          # Flask application entry point & configuration
├── backend/
│   ├── routes/
│   │   ├── recipes.py             # Recipe CRUD & search API endpoints
│   │   ├── meal_plans.py          # Meal planning & scheduling endpoints
│   │   ├── nutrition.py           # Nutrition tracking & analysis endpoints
│   │   ├── grocery.py             # Smart grocery list management endpoints
│   │   ├── feedback.py            # User feedback & rating endpoints
│   │   ├── users.py               # User management & preferences endpoints
│   │   └── fridge.py              # Fridge inventory management endpoints
│   └── utils/
│       ├── firebase_connector.py  # Firebase Admin SDK initialization
│       └── auth.py                # User authentication utilities
├── frontend/
│   ├── index.html                 # Single-page application interface
│   ├── css/
│   │   ├── styles.css             # Core styles, variables & base layout
│   │   └── components.css         # UI component library & fridge styles
│   └── js/
│       ├── app.js                 # Main application controller & router
│       ├── recipe-generator.js    # Recipe discovery & filtering module
│       ├── meal-planner.js        # Interactive meal planning interface
│       ├── nutrition-tracker.js   # Nutrition logging & progress tracking
│       ├── grocery-list.js        # Smart grocery list management
│       └── your-fridge.js         # Fridge inventory management system
├── static/                        # Static assets (images, icons, fonts)
├── requirements.txt               # Python dependencies & versions
├── firebase-credentials.json      # **IMPORTANT: DO NOT COMMIT** Firebase service account key
├── .env                           # Environment variables
├── .gitignore                     # Git ignore patterns
└── README.md                      # Comprehensive project documentation
```

## Installation & Setup

### Prerequisites
- Python 3.8+
- A Google Firebase project

### 🚀 Quick Start Guide

1.  **Clone the repository**
    ```bash
    git clone https://github.com/Tarekazabou/projet_web.git
    cd recipe_meal_planner
    ```

2.  **Set up Python environment**
    ```bash
    # Create virtual environment
    python -m venv venv
    
    # Activate environment
    # Windows:
    venv\Scripts\activate
    # macOS/Linux:
    source venv/bin/activate
    ```

3.  **Install dependencies**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Configure Firebase**
    - Go to your [Firebase project console](https://console.firebase.google.com/).
    - Navigate to **Project settings** > **Service accounts**.
    - Click **Generate new private key** and download the JSON file.
    - **Rename the downloaded file to `firebase-credentials.json`** and place it in the root of the `recipe_meal_planner` directory.
    - **IMPORTANT**: Add `firebase-credentials.json` to your `.gitignore` file to prevent it from being committed.

5.  **Set up environment variables**
    Create a `.env` file in the project root with the following content:
    ```env
    # Flask Application Settings
    FLASK_APP=app.py
    FLASK_ENV=development
    SECRET_KEY=your-super-secret-key-change-this-in-production
    
    # Server Configuration
    PORT=5000
    ```

6.  **Run the application**
    ```bash
    python app.py
    ```

7.  **Access the application**
    - Open your browser to `http://localhost:5000`
    - Start by exploring the Recipe Generator
    - Add items to Your Fridge to get personalized suggestions
    - Create your first meal plan

### 🔧 Environment Configuration

The `.env` file in the project root should contain:

```env
# Flask Application Settings
FLASK_APP=app.py
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-super-secret-key-change-this-in-production

# Server Configuration
PORT=5000
HOST=localhost
```

## 📡 API Documentation (Updated for Firebase)

### Recipe Management Endpoints
- `GET /api/recipes/search` - Search recipes with filters.
- `GET /api/recipes/{id}` - Get specific recipe details.
- `POST /api/recipes` - Create new recipe.
- `PUT /api/recipes/{id}` - Update existing recipe.
- `DELETE /api/recipes/{id}` - Delete recipe.

### Fridge Inventory Endpoints
- `GET /api/fridge/items` - Get all fridge items.
- `POST /api/fridge/items` - Add new item to fridge.
- `PUT /api/fridge/items/{id}` - Update fridge item.
- `DELETE /api/fridge/items/{id}` - Remove item from fridge.
- `POST /api/fridge/suggest-recipes` - Get recipe suggestions based on fridge contents.

### Meal Planning Endpoints
- `GET /api/meal-plans` - Get meal plans by date range.
- `POST /api/meal-plans` - Create new meal plan.
- `PUT /api/meal-plans/{id}` - Update meal plan.
- `DELETE /api/meal-plans/{id}` - Delete meal plan.

### Nutrition Tracking Endpoints
- `GET /api/nutrition/daily/{date}` - Get daily nutrition summary.
- `POST /api/nutrition/log-meal` - Log meal consumption.
- `DELETE /api/nutrition/meals/{mealId}` - Delete a logged meal.
- `GET /api/nutrition/goals` - Get user nutrition goals.
- `POST /api/nutrition/goals` - Set/update nutrition goals.
- `POST /api/nutrition/water-intake` - Log water intake.

### Grocery List Management Endpoints
- `GET /api/grocery-lists` - Get all grocery lists.
- `POST /api/grocery-lists` - Create new grocery list.
- `PUT /api/grocery-lists/{id}` - Update grocery list.
- `DELETE /api/grocery-lists/{id}` - Delete grocery list.
- `POST /api/grocery-lists/generate-from-meal-plan` - Generate from meal plan.

### User Management Endpoints
- `GET /api/users/me` - Get current user profile.
- `PUT /api/users/me` - Update user profile.
- `GET /api/users/me/favorites` - Get favorite recipes.
- `POST /api/users/me/favorites/{recipe_id}` - Add recipe to favorites.
- `DELETE /api/users/me/favorites/{recipe_id}` - Remove from favorites.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google Firebase** for a scalable and easy-to-use backend platform.
- **FontAwesome** for beautiful iconography.
- **Open Source Community** for tools and libraries.

---

**Built with ❤️ for healthier eating, smarter cooking, and zero food waste**

*Your complete kitchen companion for modern home cooking*