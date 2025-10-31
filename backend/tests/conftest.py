"""
Pytest Configuration and Fixtures
Shared test fixtures and configuration for all tests
"""
import pytest
import sys
from pathlib import Path

# Add backend to path
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from src.app_enhanced import create_app
from config import TestingConfig
from utils.firebase_connector import get_db


@pytest.fixture(scope='session')
def app():
    """Create application for testing"""
    test_app = create_app(TestingConfig)
    test_app.config['TESTING'] = True
    
    yield test_app


@pytest.fixture(scope='function')
def client(app):
    """Create test client"""
    return app.test_client()


@pytest.fixture(scope='function')
def runner(app):
    """Create CLI runner"""
    return app.test_cli_runner()


@pytest.fixture(scope='function')
def auth_headers():
    """Generate authorization headers"""
    def _auth_headers(user_id='test_user_123', token=None):
        headers = {
            'Content-Type': 'application/json',
        }
        if user_id:
            headers['X-User-Id'] = user_id
        if token:
            headers['Authorization'] = f'Bearer {token}'
        return headers
    
    return _auth_headers


@pytest.fixture
def sample_recipe():
    """Sample recipe data for testing"""
    return {
        'title': 'Test Recipe',
        'description': 'A delicious test recipe',
        'ingredients': [
            {'name': 'flour', 'quantity': '2', 'unit': 'cups'},
            {'name': 'sugar', 'quantity': '1', 'unit': 'cup'},
        ],
        'instructions': [
            'Mix flour and sugar',
            'Bake at 350F for 30 minutes'
        ],
        'prepTimeMinutes': 10,
        'cookTimeMinutes': 30,
        'servingSize': 4,
        'difficulty': 'easy',
        'cuisine': 'american',
        'nutrition': {
            'calories': 300,
            'protein': 5,
            'carbs': 50,
            'fat': 10,
            'fiber': 2
        }
    }


@pytest.fixture
def sample_user():
    """Sample user data for testing"""
    return {
        'displayName': 'Test User',
        'email': 'test@example.com',
        'dietary_preferences': ['vegetarian'],
        'allergies': ['peanuts'],
        'nutritionGoals': {
            'calories': 2000,
            'protein': 150,
            'carbs': 250,
            'fat': 65,
            'fiber': 25,
            'water': 8
        }
    }


@pytest.fixture
def mock_firebase_user():
    """Mock Firebase user token data"""
    return {
        'uid': 'firebase_test_user_123',
        'email': 'firebase@example.com',
        'name': 'Firebase Test User',
        'picture': 'https://example.com/photo.jpg'
    }


@pytest.fixture(autouse=True)
def cleanup_test_data(app):
    """Cleanup test data after each test"""
    yield
    
    # Add cleanup logic here if needed
    # For example, delete test documents from Firestore
    # This keeps the test database clean


class MockResponse:
    """Mock HTTP response for testing"""
    
    def __init__(self, json_data, status_code=200, text=None):
        self.json_data = json_data
        self.status_code = status_code
        self.text = text or str(json_data)
    
    def json(self):
        return self.json_data


@pytest.fixture
def mock_ai_response():
    """Mock AI service response"""
    def _mock_ai_response(recipe_data=None):
        if recipe_data is None:
            recipe_data = {
                'title': 'AI Generated Recipe',
                'description': 'An AI-created dish',
                'ingredients': [
                    {'name': 'chicken', 'quantity': '1', 'unit': 'lb'},
                    {'name': 'tomatoes', 'quantity': '3', 'unit': 'whole'}
                ],
                'instructions': [
                    'Prepare the chicken',
                    'Cook with tomatoes'
                ],
                'prepTimeMinutes': 15,
                'cookTimeMinutes': 25,
                'servingSize': 4,
                'difficulty': 'medium',
                'nutrition': {
                    'calories': 400,
                    'protein': 35,
                    'carbs': 20,
                    'fat': 15,
                    'fiber': 3
                }
            }
        return recipe_data
    
    return _mock_ai_response
