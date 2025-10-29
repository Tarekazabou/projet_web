from datetime import datetime
from typing import Optional

from flask import g, request
from utils.firebase_connector import get_db

DEMO_USER_ID = 'demo_user_01'


def _ensure_demo_user() -> dict:
    """Guarantee a demo user exists for development and return it."""
    db = get_db()
    user_ref = db.collection('users').document(DEMO_USER_ID)
    user = user_ref.get()
    if user.exists:
        user_data = user.to_dict()
        user_data['id'] = user.id
        return user_data

    demo_user = {
        'id': DEMO_USER_ID,
        'username': 'demo_user',
        'email': 'demo@example.com',
        'dietary_preferences': ['balanced'],
        'allergies': [],
        'nutritional_goals': {
            'calories': 2000,
            'protein': 150,
            'carbs': 250,
            'fat': 65,
            'fiber': 25,
            'sodium': 2300,
            'sugar': 50
        },
        'favorite_recipes': [],
        'meal_plans': [],
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow(),
        'is_active': True
    }
    db.collection('users').document(DEMO_USER_ID).set(demo_user)
    return demo_user


def _load_user_from_header(user_token: Optional[str]) -> Optional[dict]:
    """Attempt to resolve a user document from a header token."""
    if not user_token:
        return None

    db = get_db()
    user_ref = db.collection('users').document(user_token)
    user = user_ref.get()
    if user.exists:
        user_data = user.to_dict()
        user_data['id'] = user.id
        return user_data
    return None


def attach_current_user() -> dict:
    """Populate flask.g with the authenticated (or demo) user."""
    header_token = request.headers.get('X-User-Id')
    bearer_token = request.headers.get('Authorization')
    token = header_token or (bearer_token.replace('Bearer ', '').strip() if bearer_token else None)

    user = _load_user_from_header(token)
    if not user:
        user = _ensure_demo_user()

    g.current_user = user
    g.current_user_id = user['id']
    return user


def require_current_user() -> str:
    """Ensure a user is attached to the request context and return the id."""
    if not hasattr(g, 'current_user_id'):
        attach_current_user()
    return g.current_user_id
