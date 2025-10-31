# Backend Testing Configuration

## Test Structure
```
backend/tests/
├── __init__.py
├── conftest.py                 # Pytest fixtures
├── test_auth.py                # Authentication tests
├── test_response_handler.py    # Response handler tests
├── test_validators.py          # Validation tests
├── test_config.py              # Configuration tests
├── integration/
│   ├── test_recipes_api.py     # Recipe endpoints
│   ├── test_users_api.py       # User endpoints
│   └── test_ai_recipes_api.py  # AI generation endpoints
└── unit/
    ├── test_ai_service.py      # AI service unit tests
    └── test_rag_service.py     # RAG service unit tests
```

## Running Tests

### All tests
```bash
pytest
```

### With coverage
```bash
pytest --cov=backend --cov-report=html --cov-report=term
```

### Specific test file
```bash
pytest tests/test_auth.py -v
```

### Integration tests only
```bash
pytest tests/integration/ -v
```

### Unit tests only
```bash
pytest tests/unit/ -v
```

## Test Coverage Goals
- Overall: >80%
- Critical paths (auth, API endpoints): >90%
- Utilities: >85%
