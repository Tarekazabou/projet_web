# Mealy: AI-Powered Recipe & Meal Planning Platform

> **Version 3.0** - Flutter Mobile App + Full Meal Planning & Smart Grocery Integration

[![CI/CD Pipeline](https://github.com/Tarekazabou/projet_web/workflows/CI%2FCD%20Pipeline/badge.svg)](https://github.com/Tarekazabou/projet_web/actions)
[![codecov](https://codecov.io/gh/Tarekazabou/projet_web/branch/main/graph/badge.svg)](https://codecov.io/gh/Tarekazabou/projet_web)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Mealy is an intelligent application that revolutionizes meal planning and recipe discovery using AI. From generating personalized recipes to tracking nutrition and managing grocery lists, Mealy is your comprehensive kitchen assistant.

## 🚀 What's New in Version 3.0

### Flutter Mobile App
- ✅ **Cross-Platform Mobile App**: Beautiful Flutter app for iOS, Android, and Web
- ✅ **Modern UI Design**: Inspired by fitness app templates with warm food-focused colors
- ✅ **Provider State Management**: Efficient state management with Provider pattern
- ✅ **Firebase Integration**: Firebase Auth and Firestore for real-time data
- ✅ **Responsive Design**: ScreenUtil for consistent scaling across devices

### Meal Planning System
- ✅ **Weekly Meal Planner**: Visual calendar with 7-day horizontal scroll
- ✅ **Meal Type Organization**: Breakfast, Lunch, Dinner, and Snack sections
- ✅ **AI Meal Suggestions**: Smart recommendations based on fridge contents
- ✅ **Fridge Match Percentage**: See which ingredients you already have
- ✅ **Quick Add Meals**: Easy form to add custom meals

### Smart Grocery Lists
- ✅ **Auto-Generate from Meal Plans**: Create shopping lists from weekly plans
- ✅ **Fridge-Aware**: Automatically subtracts items you already have
- ✅ **Category Organization**: Items grouped by Dairy, Produce, Meat, etc.
- ✅ **Progress Tracking**: Visual percentage of items purchased
- ✅ **Swipe to Delete**: Easy item removal with swipe gestures
- ✅ **Toggle Purchased**: Mark items as bought with animated checkmarks

### Backend Improvements
- ✅ **Enhanced Architecture**: Modular, maintainable code structure with separation of concerns
- ✅ **Robust Authentication**: JWT tokens, Firebase Auth integration, role-based access control
- ✅ **New API Endpoints**: Meal plans weekly view, AI suggestions, grocery management
- ✅ **Firestore Optimizations**: Efficient queries without composite index requirements
- ✅ **Structured Logging**: JSON logging with request tracing and monitoring

### Testing & Quality
- ✅ **Comprehensive Tests**: Unit, integration, and E2E tests with >80% coverage
- ✅ **CI/CD Pipeline**: Automated testing, linting, security scanning, and deployment
- ✅ **Code Quality**: Pylint, Black, ESLint integration

### DevOps
- ✅ **Docker Support**: Multi-stage builds with production-optimized images
- ✅ **Docker Compose**: Full-stack orchestration with Redis and Nginx
- ✅ **Monitoring**: Health checks, structured logging, and error tracking
- ✅ **Documentation**: Comprehensive API docs and deployment guides

## 📋 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Development](#-development)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [API Documentation](#-api-documentation)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

### Core Features
- **🤖 AI Recipe Generation**: Create personalized recipes using Google Gemini AI
- **📅 Meal Planning**: Plan your weekly meals with drag-and-drop interface
- **📊 Nutrition Tracking**: Monitor calories, macros, and nutritional goals
- **🛒 Smart Grocery Lists**: Auto-generate shopping lists from meal plans
- **🧊 Fridge Management**: Track ingredients and reduce food waste
- **🔍 Recipe Search**: Find recipes from 13,000+ curated recipes
- **👤 User Profiles**: Manage dietary preferences, allergies, and nutrition goals

### Technical Features
- **🔐 Secure Authentication**: Firebase Auth with JWT tokens
- **🌐 RESTful API**: Well-documented, consistent API design
- **📱 Responsive Design**: Mobile-first, accessible UI
- **⚡ Performance**: Caching, lazy loading, optimized queries
- **🔄 Real-time Updates**: Firebase Firestore integration
- **📈 Monitoring**: Health checks, logging, and error tracking

## 🛠 Tech Stack

### Backend
- **Framework**: Flask 2.3+
- **Database**: Google Firestore
- **Authentication**: Firebase Authentication + JWT
- **AI**: Google Gemini (RAG-powered generation)
- **Embeddings**: Sentence Transformers, FAISS
- **Server**: Gunicorn (production)
- **Testing**: Pytest, Coverage

### Flutter Mobile App
- **Framework**: Flutter 3.9+ / Dart
- **State Management**: Provider
- **UI**: flutter_screenutil, Custom Theme (MealyTheme)
- **Authentication**: Firebase Auth
- **Database**: Firebase Firestore
- **HTTP**: http package with custom ApiService
- **Animations**: Lottie, Built-in Flutter animations

### React Web Frontend
- **Framework**: React 18 with Vite
- **Routing**: React Router v6
- **Styling**: CSS3, Custom Components
- **Authentication**: Firebase SDK with React Context
- **Build**: Vite (fast HMR and optimized production builds)
- **State Management**: React Context API

### DevOps
- **Containerization**: Docker, Docker Compose
- **CI/CD**: GitHub Actions
- **Reverse Proxy**: Nginx (optional)
- **Caching**: Redis (optional)
- **Monitoring**: Structured logging, health checks

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Clients                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  Flutter App    │  │   React Web     │  │   API Clients   │     │
│  │ (iOS/Android)   │  │   (Browser)     │  │                 │     │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS / REST API
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Backend (Flask + Gunicorn)                        │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Middleware (Auth, Logging, CORS, X-User-Id Header)        │    │
│  └────────────────────────────────────────────────────────────┘    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Recipes  │  │MealPlans │  │ Grocery  │  │ Fridge   │           │
│  │  Routes  │  │  Routes  │  │  Routes  │  │  Routes  │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
└─────────────────────────────────────────────────────────────────────┘
        │                    │                   │
        ▼                    ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   Firebase   │   │Google Gemini │   │   Redis      │
│  Firestore   │   │   AI API     │   │  (Cache)     │
└──────────────┘   └──────────────┘   └──────────────┘
```

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- Node.js 18+ (for frontend tooling)
- Firebase project with Firestore
- Google Gemini API key
- Docker (optional, for containerized deployment)

### Quick Start (Development)

1. **Clone the repository**
   ```bash
   git clone https://github.com/Tarekazabou/projet_web.git
   cd projet_web
   ```

2. **Set up backend environment variables**
   ```bash
   cd backend
   cp .env.example .env
   # Edit .env with your configuration (Firebase credentials, API keys, etc.)
   ```

3. **Install backend dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the backend server**
   ```bash
   cd backend
   python app.py
   ```

5. **Open your browser**
   Navigate to `http://localhost:5000`

### Flutter Mobile App Setup

1. **Install Flutter dependencies**
   ```bash
   cd my_app
   flutter pub get
   ```

2. **Configure API URL** in `lib/utils/constants.dart`:
   - **iOS Simulator**: `http://localhost:5000/api`
   - **Android Emulator**: `http://10.0.2.2:5000/api`
   - **Real Device**: `http://YOUR_COMPUTER_IP:5000/api`

3. **Run the Flutter app**
   ```bash
   flutter run
   ```

4. **Available platforms**
   ```bash
   flutter run -d chrome    # Web
   flutter run -d windows   # Windows Desktop
   flutter run -d android   # Android
   flutter run -d ios       # iOS
   ```

### React Web Frontend Setup (Optional)

1. **Set up React frontend**
   ```bash
   cd frontend-react
   npm install
   ```

2. **Development mode with Hot Reload**
   ```bash
   npm run dev
   ```

3. **Production build**
   ```bash
   npm run build
   ```

### Quick Start (Docker)

1. **Create .env file**
   ```bash
   cp backend/.env.template backend/.env
   # Edit .env with your configuration
   ```

2. **Build and run**
   ```bash
   docker-compose up --build
   ```

3. **Access the application**
   - Backend API: `http://localhost:5000`
   - Health check: `http://localhost:5000/api/health`

## 💻 Development

### Project Structure

```
projet_web/
├── frontend-react/              # React frontend (NEW)
│   ├── src/
│   │   ├── components/          # Reusable components
│   │   │   └── Navbar.jsx
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

### Running Tests

```bash
# All tests
pytest

# With coverage
pytest --cov=backend --cov-report=html --cov-report=term

# Specific test file
pytest tests/test_auth.py -v

# Integration tests
pytest tests/integration/ -v
```

### Code Quality

```bash
# Format code
black backend/

# Lint
pylint backend/
flake8 backend/

# Type checking
mypy backend/
```

## 🧪 Testing

### Test Coverage
- Overall: >80%
- Critical paths: >90%
- CI integration with Codecov

### Test Types
- **Unit Tests**: Individual functions and classes
- **Integration Tests**: API endpoints and database operations
- **E2E Tests**: Full user workflows (planned)

## 🚢 Deployment

### Environment Variables

Required environment variables (see `backend/.env.template`):

```env
FLASK_ENV=production
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret
GEMINI_API_KEY=your-gemini-key
FIREBASE_PROJECT_ID=your-project-id
CORS_ORIGINS=https://yourdomain.com
```

### Docker Deployment

```bash
# Build image
docker build -t mealy:latest .

# Run container
docker run -d \
  -p 5000:5000 \
  --env-file backend/.env \
  mealy:latest
```

### Docker Compose (Full Stack)

```bash
docker-compose up -d
```

Includes:
- Flask backend (Gunicorn)
- Nginx reverse proxy
- Redis caching
- Automatic health checks

### Cloud Deployment

See detailed guides for:
- [Google Cloud Run](docs/deploy-cloud-run.md)
- [AWS ECS](docs/deploy-aws.md)
- [Azure Container Instances](docs/deploy-azure.md)
- [Heroku](docs/deploy-heroku.md)

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

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`pytest`)
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Tarek Azabou** - *Initial work* - [Tarekazabou](https://github.com/Tarekazabou)

## 🙏 Acknowledgments

- Google Gemini for AI capabilities
- Firebase for backend infrastructure
- Open source community for tools and libraries
- 13k Recipe dataset contributors

## 📞 Support

- 📧 Email: support@mealy.com
- 🐛 Issues: [GitHub Issues](https://github.com/Tarekazabou/projet_web/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/Tarekazabou/projet_web/discussions)

---

**Built with ❤️ using Flask, Firebase, and Google Gemini**
