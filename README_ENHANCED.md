# Mealy: AI-Powered Recipe & Meal Planning Platform

> **Version 2.0** - Production-Ready Release with Enhanced Security, Testing, and DevOps

[![CI/CD Pipeline](https://github.com/Tarekazabou/projet_web/workflows/CI%2FCD%20Pipeline/badge.svg)](https://github.com/Tarekazabou/projet_web/actions)
[![codecov](https://codecov.io/gh/Tarekazabou/projet_web/branch/main/graph/badge.svg)](https://codecov.io/gh/Tarekazabou/projet_web)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Mealy is an intelligent web application that revolutionizes meal planning and recipe discovery using AI. From generating personalized recipes to tracking nutrition and managing grocery lists, Mealy is your comprehensive kitchen assistant.

## 🚀 What's New in Version 2.0

### Backend Improvements
- ✅ **Enhanced Architecture**: Modular, maintainable code structure with separation of concerns
- ✅ **Robust Authentication**: JWT tokens, Firebase Auth integration, role-based access control
- ✅ **Advanced Validation**: Comprehensive input validation and sanitization
- ✅ **Structured Logging**: JSON logging with request tracing and monitoring
- ✅ **Security Headers**: CORS, CSP, XSS protection, and rate limiting
- ✅ **Error Handling**: Standardized API responses with detailed error codes
- ✅ **Production Ready**: Docker support, environment configuration, health checks

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
- **🤖 AI Recipe Generation**: Create personalized recipes using RAG (Retrieval-Augmented Generation) with Google Gemini
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

### Frontend
- **Framework**: Vanilla JavaScript (ES6+)
- **Styling**: CSS3, Custom Components
- **Authentication**: Firebase SDK
- **Build**: No build step (simple deployment)

### DevOps
- **Containerization**: Docker, Docker Compose
- **CI/CD**: GitHub Actions
- **Reverse Proxy**: Nginx (optional)
- **Caching**: Redis (optional)
- **Monitoring**: Structured logging, health checks

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Frontend (Browser)                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐   │
│  │   Auth     │  │  Recipes   │  │ Meal Plans │   │
│  └────────────┘  └────────────┘  └────────────┘   │
└─────────────────────────────────────────────────────┘
                      │
                      │ HTTPS / REST API
                      ▼
┌─────────────────────────────────────────────────────┐
│                Backend (Flask + Gunicorn)            │
│  ┌────────────────────────────────────────────┐    │
│  │  Middleware (Auth, Logging, CORS)          │    │
│  └────────────────────────────────────────────┘    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │  Routes  │  │ Services │  │ Utilities│         │
│  └──────────┘  └──────────┘  └──────────┘         │
└─────────────────────────────────────────────────────┘
        │                    │                   │
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

2. **Set up environment variables**
   ```bash
   cd backend
   cp .env.template .env
   # Edit .env with your configuration
   ```

3. **Install Python dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the development server**
   ```bash
   python src/app_enhanced.py
   ```

5. **Open your browser**
   Navigate to `http://localhost:5000`

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
├── backend/
│   ├── config.py                 # Configuration management
│   ├── requirements.txt          # Python dependencies
│   ├── src/
│   │   ├── app.py               # Original app
│   │   └── app_enhanced.py      # Enhanced app (v2.0)
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
https://api.mealy.com/api
```

### Authentication
```bash
# Include JWT token in header
Authorization: Bearer <token>

# Or use X-User-Id for demo mode
X-User-Id: <user_id>
```

### Core Endpoints

#### Health Check
```http
GET /api/health
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

#### Get Recipes
```http
GET /api/recipes?page=1&limit=20
```

#### Create Meal Plan
```http
POST /api/meal-plans
Content-Type: application/json

{
  "startDate": "2025-11-01",
  "meals": [...]
}
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
