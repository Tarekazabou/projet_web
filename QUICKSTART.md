# Mealy Backend - Quick Start Guide

Get up and running with Mealy backend in under 5 minutes!

## Prerequisites

- Python 3.11+ installed
- Git installed
- Firebase project with Firestore enabled
- Google Gemini API key

## Quick Start (Development)

### 1. Clone and Navigate
```bash
git clone https://github.com/Tarekazabou/projet_web.git
cd projet_web/backend
```

### 2. Create Virtual Environment (Recommended)
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Set Up Environment Variables
```bash
# Copy template
cp .env.template .env

# Edit .env with your configuration
# Required: GEMINI_API_KEY, Firebase credentials
```

Example `.env`:
```env
FLASK_ENV=development
PORT=5000
SECRET_KEY=dev-secret-key
GEMINI_API_KEY=your-gemini-api-key-here
FIREBASE_PROJECT_ID=your-project-id
```

### 5. Run the Application

**Option A: Enhanced Version (v2.0 - Recommended)**
```bash
python src/app_enhanced.py
```

**Option B: Original Version (v1.0)**
```bash
python src/app.py
```

### 6. Test the Application
```bash
# Open browser
http://localhost:5000

# Test health check
curl http://localhost:5000/api/health

# Test API info
curl http://localhost:5000/api/info
```

## Quick Start (Docker)

### 1. Create Environment File
```bash
cp backend/.env.template backend/.env
# Edit with your configuration
```

### 2. Build and Run
```bash
# Development
docker-compose up

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 3. Access Application
```
http://localhost:5000
```

## Common Development Tasks

### Run Tests
```bash
# All tests
pytest

# With coverage
pytest --cov=backend --cov-report=html

# Specific test
pytest tests/test_response_handler.py -v
```

### Format Code
```bash
black backend/
```

### Lint Code
```bash
pylint backend/
flake8 backend/
```

### Check Dependencies
```bash
pip list --outdated
safety check -r requirements.txt
```

## Troubleshooting

### Issue: ModuleNotFoundError
```bash
# Ensure you're in the correct directory and virtual environment is activated
cd backend
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
```

### Issue: Firebase connection error
```bash
# Verify credentials file exists
ls mealy-41bf0-firebase-adminsdk-fbsvc-7d493e86ea.json

# Or set FIREBASE_CREDENTIAL_PATH in .env
FIREBASE_CREDENTIAL_PATH=/path/to/credentials.json
```

### Issue: GEMINI_API_KEY not found
```bash
# Set in .env file
echo "GEMINI_API_KEY=your-key-here" >> backend/.env

# Or export temporarily
export GEMINI_API_KEY=your-key-here
```

### Issue: Port already in use
```bash
# Change port in .env
PORT=5001

# Or kill process using port 5000
# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# macOS/Linux
lsof -ti:5000 | xargs kill -9
```

## Project Structure

```
backend/
├── config.py              # Configuration management
├── requirements.txt       # Dependencies
├── src/
│   ├── app.py            # Original app
│   └── app_enhanced.py   # Enhanced app (v2.0)
├── routes/               # API endpoints
├── services/             # Business logic
├── utils/                # Utilities
├── tests/                # Test suite
└── data/                 # Data files (embeddings, etc.)
```

## Key Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api/info` | GET | API information |
| `/api/recipes` | GET | List recipes |
| `/api/recipes/generate-with-ai` | POST | AI recipe generation |
| `/api/users` | GET/POST | User management |
| `/api/meal-plans` | GET/POST | Meal planning |

## Environment Variables

### Required
- `GEMINI_API_KEY` - Google Gemini API key
- `FIREBASE_PROJECT_ID` - Firebase project ID

### Optional
- `PORT` - Server port (default: 5000)
- `FLASK_ENV` - Environment (development/production)
- `SECRET_KEY` - Flask secret key
- `CORS_ORIGINS` - Allowed CORS origins
- `LOG_LEVEL` - Logging level (INFO/DEBUG/ERROR)

## Next Steps

1. **Read Documentation**: Check `README_ENHANCED.md` for full documentation
2. **Review API**: See API documentation for endpoint details
3. **Write Tests**: Add tests for your new features
4. **Deploy**: Follow `docs/DEPLOYMENT.md` for production deployment
5. **Contribute**: Submit PRs with your improvements!

## Getting Help

- 📚 Documentation: `docs/` folder
- 🐛 Issues: [GitHub Issues](https://github.com/Tarekazabou/projet_web/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/Tarekazabou/projet_web/discussions)

## Useful Commands Cheat Sheet

```bash
# Development
python src/app_enhanced.py           # Run server
pytest --cov                         # Run tests with coverage
black . && pylint .                  # Format and lint

# Docker
docker-compose up                    # Start all services
docker-compose logs -f backend       # View logs
docker-compose down                  # Stop all services

# Git
git pull origin main                 # Update code
git checkout -b feature/my-feature   # Create branch
git commit -m "Add feature"          # Commit changes
git push origin feature/my-feature   # Push changes

# Dependencies
pip install -r requirements.txt      # Install deps
pip freeze > requirements.txt        # Save current deps
pip list --outdated                  # Check for updates
```

---

**Happy Coding! 🚀**

For detailed information, see:
- `README_ENHANCED.md` - Full project documentation
- `docs/DEPLOYMENT.md` - Production deployment guide
- `docs/ENHANCEMENT_SUMMARY.md` - Version 2.0 changes
