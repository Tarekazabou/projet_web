"""
Enhanced Authentication and Authorization System
Supports Firebase Authentication, JWT tokens, and role-based access control
"""
import logging
from datetime import datetime, timedelta
from typing import Optional, Callable
from functools import wraps

from flask import g, request
from firebase_admin import auth as firebase_auth
from google.cloud import exceptions
import jwt

from utils.firebase_connector import get_db
from utils.response_handler import APIResponse

DEMO_USER_ID = 'demo_user_01'
logger = logging.getLogger(__name__)


def _users_collection():
    return get_db().collection('User')


def _ensure_demo_user() -> dict:
    """Guarantee a demo user exists for development and return it."""

    user_ref = _users_collection().document(DEMO_USER_ID)
    snapshot = user_ref.get()
    if snapshot.exists:
        user_data = snapshot.to_dict()
        user_data['id'] = snapshot.id
        return user_data

    demo_user = {
        'id': DEMO_USER_ID,
        'displayName': 'Demo User',
        'email': 'demo@example.com',
        'dietary_preferences': ['balanced'],
        'allergies': [],
        'nutritionGoals': {
            'calories': 2000,
            'protein': 150,
            'carbs': 250,
            'fat': 65,
            'fiber': 25,
            'water': 8,
        },
        'createdAt': datetime.utcnow(),
        'updatedAt': datetime.utcnow(),
        'isActive': True,
        'source': 'demo',
    }

    user_ref.set(demo_user)
    demo_user['id'] = DEMO_USER_ID
    return demo_user


def _load_user_document(user_id: str) -> Optional[dict]:
    if not user_id:
        return None

    snapshot = _users_collection().document(user_id).get()
    if not snapshot.exists:
        return None

    user_data = snapshot.to_dict()
    user_data['id'] = snapshot.id
    return user_data


def _create_user_document(user_id: str, defaults: dict) -> dict:
    user_ref = _users_collection().document(user_id)
    payload = {
        'createdAt': datetime.utcnow(),
        'updatedAt': datetime.utcnow(),
        **defaults,
    }
    user_ref.set(payload)
    payload['id'] = user_id
    return payload


def _load_user_from_firebase_token(id_token: str) -> Optional[dict]:
    if not id_token:
        return None

    try:
        decoded = firebase_auth.verify_id_token(id_token)
    except (firebase_auth.InvalidIdTokenError, firebase_auth.ExpiredIdTokenError) as exc:
        logger.warning('Invalid Firebase ID token: %s', exc)
        return None
    except ValueError as exc:
        logger.warning('Unable to parse Firebase ID token: %s', exc)
        return None

    user_id = decoded.get('uid')
    if not user_id:
        return None

    user_data = _load_user_document(user_id)
    if not user_data:
        defaults = {
            'displayName': decoded.get('name') or decoded.get('email') or 'User',
            'email': decoded.get('email', ''),
            'photoURL': decoded.get('picture'),
            'dietary_preferences': [],
            'allergies': [],
            'nutritionGoals': {
                'calories': 2000,
                'protein': 90,
                'carbs': 250,
                'fat': 70,
                'fiber': 28,
                'water': 8,
            },
            'isActive': True,
            'source': 'firebase-auth',
        }
        try:
            user_data = _create_user_document(user_id, defaults)
        except exceptions.GoogleCloudError as exc:
            logger.error('Failed to create user document for %s: %s', user_id, exc)
            return None

    g.id_token_claims = decoded
    return user_data


def attach_current_user() -> dict:
    """Populate flask.g with the authenticated (or demo) user."""

    bearer_token = request.headers.get('Authorization')
    id_token = None
    if bearer_token and bearer_token.lower().startswith('bearer '):
        id_token = bearer_token.split(' ', 1)[1].strip()

    user = _load_user_from_firebase_token(id_token)
    if not user:
        header_token = request.headers.get('X-User-Id')
        user = _load_user_document(header_token)

    if not user:
        user = _ensure_demo_user()

    g.current_user = user
    g.current_user_id = user['id']
    return user


def get_current_user_id() -> Optional[str]:
    """Get the current user ID without requiring authentication."""
    if hasattr(g, 'current_user_id'):
        return g.current_user_id
    return None


def require_current_user() -> str:
    """Ensure a user is attached to the request context and return the id."""

    if not hasattr(g, 'current_user_id'):
        attach_current_user()
    return g.current_user_id


def require_auth(optional: bool = False) -> Callable:
    """
    Decorator to require authentication for an endpoint
    
    Args:
        optional: If True, allows unauthenticated requests (user will be None)
    
    Returns:
        Decorated function
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            user = attach_current_user()
            
            # Check if authentication is required
            if not optional and (not user or user.get('id') == DEMO_USER_ID):
                return APIResponse.unauthorized(
                    "Authentication required. Please log in."
                )
            
            return func(*args, **kwargs)
        
        return wrapper
    return decorator


def require_role(*allowed_roles: str) -> Callable:
    """
    Decorator to require specific user role(s)
    
    Args:
        *allowed_roles: One or more role names that are allowed
    
    Returns:
        Decorated function
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            user = attach_current_user()
            
            if not user or user.get('id') == DEMO_USER_ID:
                return APIResponse.unauthorized("Authentication required")
            
            user_role = user.get('role', 'user')
            
            if user_role not in allowed_roles:
                return APIResponse.forbidden(
                    f"Access denied. Required role(s): {', '.join(allowed_roles)}"
                )
            
            return func(*args, **kwargs)
        
        return wrapper
    return decorator


def generate_jwt_token(user_id: str, secret_key: str, expires_in: int = 3600) -> str:
    """
    Generate a JWT token for a user
    
    Args:
        user_id: User ID to encode in token
        secret_key: Secret key for signing
        expires_in: Token expiration in seconds (default 1 hour)
    
    Returns:
        JWT token string
    """
    try:
        payload = {
            'user_id': user_id,
            'iat': datetime.utcnow(),
            'exp': datetime.utcnow() + timedelta(seconds=expires_in)
        }
        
        token = jwt.encode(payload, secret_key, algorithm='HS256')
        return token
    
    except Exception as e:
        logger.error(f"Error generating JWT token: {e}")
        raise


def verify_jwt_token(token: str, secret_key: str) -> Optional[dict]:
    """
    Verify and decode a JWT token
    
    Args:
        token: JWT token to verify
        secret_key: Secret key for verification
    
    Returns:
        Decoded payload or None if invalid
    """
    try:
        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        return payload
    
    except jwt.ExpiredSignatureError:
        logger.warning("JWT token has expired")
        return None
    
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid JWT token: {e}")
        return None


def get_user_permissions(user: dict) -> set:
    """
    Get user permissions based on role
    
    Args:
        user: User dictionary
    
    Returns:
        Set of permission strings
    """
    role = user.get('role', 'user')
    
    permissions = {
        'admin': {
            'user:read', 'user:write', 'user:delete',
            'recipe:read', 'recipe:write', 'recipe:delete',
            'meal_plan:read', 'meal_plan:write', 'meal_plan:delete',
            'settings:read', 'settings:write',
            'analytics:read'
        },
        'premium_user': {
            'user:read', 'user:write',
            'recipe:read', 'recipe:write',
            'meal_plan:read', 'meal_plan:write',
            'ai:generate', 'ai:advanced'
        },
        'user': {
            'user:read', 'user:write',
            'recipe:read',
            'meal_plan:read', 'meal_plan:write',
            'ai:generate'
        }
    }
    
    return permissions.get(role, permissions['user'])


def check_permission(permission: str) -> Callable:
    """
    Decorator to check if user has specific permission
    
    Args:
        permission: Permission string to check (e.g., 'recipe:write')
    
    Returns:
        Decorated function
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            if not hasattr(g, 'current_user'):
                attach_current_user()
            
            user = g.current_user
            user_permissions = get_user_permissions(user)
            
            if permission not in user_permissions:
                return APIResponse.forbidden(
                    f"Permission denied: {permission} required"
                )
            
            return func(*args, **kwargs)
        
        return wrapper
    return decorator
