from flask import Blueprint, request, jsonify
from google.cloud.firestore_v1.base_query import FieldFilter
from utils.firebase_connector import get_db
import logging
from datetime import datetime
import hashlib

logger = logging.getLogger(__name__)
users_bp = Blueprint('users', __name__)

def hash_password(password):
    """Simple password hashing (in production, use proper hashing like bcrypt)"""
    return hashlib.sha256(password.encode()).hexdigest()

@users_bp.route('/register', methods=['POST'])
def register():
    """Register a new user"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')
        username = data.get('username', '').strip()
        
        if not email or not password or not username:
            return jsonify({'success': False, 'message': 'Email, password, and username are required'}), 400
        
        db = get_db()
        users_ref = db.collection('User')
        
        # Check if user already exists
        existing_user = users_ref.where(filter=FieldFilter('email', '==', email)).limit(1).get()
        if len(list(existing_user)) > 0:
            return jsonify({'success': False, 'message': 'User with this email already exists'}), 409
        
        # Create new user
        user_data = {
            'email': email,
            'username': username,
            'displayName': username,
            'password': hashlib.sha256(password.encode()).hexdigest(),  # Hash the password
            'createdAt': datetime.utcnow(),
            'updatedAt': datetime.utcnow(),
            'dietary_preferences': [],
            'allergies': [],
        }
        
        user_ref = users_ref.document()
        user_ref.set(user_data)
        
        return jsonify({
            'success': True,
            'message': 'User registered successfully',
            'data': {
                'user_id': user_ref.id,
                'email': email,
                'username': username,
            }
        }), 201
        
    except Exception as e:
        logger.error(f"Error registering user: {e}")
        return jsonify({'success': False, 'message': 'Failed to register user'}), 500

@users_bp.route('/login', methods=['POST'])
def login():
    """Login user"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')
        
        if not email or not password:
            return jsonify({'success': False, 'message': 'Email and password are required'}), 400
        
        db = get_db()
        users_ref = db.collection('User')
        
        # Find user by email
        users = users_ref.where(filter=FieldFilter('email', '==', email)).limit(1).get()
        users_list = list(users)
        
        if len(users_list) == 0:
            return jsonify({'success': False, 'message': 'Invalid email or password'}), 401
        
        user_doc = users_list[0]
        user_data = user_doc.to_dict()
        
        # Check password
        if user_data.get('password') != hash_password(password):
            return jsonify({'success': False, 'message': 'Invalid email or password'}), 401
        
        # Return user data (without password)
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'data': {
                'user_id': user_doc.id,
                'id': user_doc.id,
                'email': user_data.get('email'),
                'username': user_data.get('username', user_data.get('displayName', 'User')),
                'name': user_data.get('displayName', user_data.get('username', 'User')),
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error logging in user: {e}")
        return jsonify({'success': False, 'message': 'Failed to login'}), 500