# Backend Tests

This folder contains pytest tests for the Flask backend.

## Test structure

```
backend/tests/
    conftest.py
    test_ai_endpoints.py
    test_complete_flow.py
    test_firestore_fridge.py
    test_fridge_recipe.py
    test_response_handler.py
    test_suggest_recipes.py
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
pytest tests/test_complete_flow.py -v
```

## Test Coverage Goals
- Overall: >80%
- Critical paths (auth, API endpoints): >90%
- Utilities: >85%
