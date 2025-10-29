import os
from datetime import datetime
from typing import Optional

from bson import ObjectId
from flask import current_app, g, request

DEMO_USER_ID = os.getenv('DEMO_USER_ID', '64b7d2f2c5f1e3a1a0b0c0d0')


def get_mongo_db():
    """Safely obtain the MongoDB handle from the current Flask app."""
    mongo = getattr(current_app, 'mongo', None)

    if mongo is None:
        extension = current_app.extensions.get('pymongo')
        if isinstance(extension, dict):
            mongo = next(iter(extension.values()), None)
        else:
            mongo = extension

    if mongo is None or getattr(mongo, 'db', None) is None:
        raise RuntimeError('Mongo client is not initialized; ensure PyMongo is configured correctly.')

    return mongo.db


def _ensure_demo_user() -> dict:
    """Guarantee a demo user exists for development and return it."""
    db = get_mongo_db()
    demo_object_id = ObjectId(DEMO_USER_ID)
    user = db.users.find_one({'_id': demo_object_id})
    if user:
        return user

    demo_user = {
        '_id': demo_object_id,
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
    db.users.insert_one(demo_user)
    return demo_user


def _load_user_from_header(user_token: Optional[str]) -> Optional[dict]:
    """Attempt to resolve a user document from a header token."""
    if not user_token or not ObjectId.is_valid(user_token):
        return None

    db = get_mongo_db()
    return db.users.find_one({'_id': ObjectId(user_token)})


def attach_current_user() -> dict:
    """Populate flask.g with the authenticated (or demo) user."""
    header_token = request.headers.get('X-User-Id')
    bearer_token = request.headers.get('Authorization')
    token = header_token or (bearer_token.replace('Bearer ', '').strip() if bearer_token else None)

    user = _load_user_from_header(token)
    if not user:
        user = _ensure_demo_user()

    g.current_user = user
    g.current_user_id = str(user['_id'])
    return user


def require_current_user() -> str:
    """Ensure a user is attached to the request context and return the id."""
    if not hasattr(g, 'current_user_id'):
        attach_current_user()
    return g.current_user_id
