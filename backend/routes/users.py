from flask import Blueprint, request, jsonify
from utils.firebase_connector import get_db
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
users_bp = Blueprint('users', __name__)

@users_bp.route('/', methods=['POST'])
def create_user():
    """Create a new user profile"""
    try:
        data = request.get_json()
        db = get_db()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        required_fields = ['displayName', 'email']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Check if user already exists
        users_ref = db.collection('User')
        existing_user = users_ref.where('email', '==', data['email']).limit(1).get()
        
        if len(existing_user) > 0:
            return jsonify({'error': 'User with this email already exists'}), 409
        
        data['createdAt'] = datetime.utcnow()
        
        # Add a new doc with a generated id.
        new_user_ref = users_ref.add(data)[1]
        
        created_user = new_user_ref.get().to_dict()
        created_user['id'] = new_user_ref.id
        
        return jsonify({
            'message': 'User created successfully',
            'user': created_user
        }), 201
        
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        return jsonify({'error': 'Failed to create user'}), 500

@users_bp.route('/<user_id>', methods=['GET'])
def get_user(user_id):
    """Get user profile"""
    try:
        db = get_db()
        user_ref = db.collection('User').document(user_id)
        user = user_ref.get()
        
        if not user.exists:
            return jsonify({'error': 'User not found'}), 404
        
        user_data = user.to_dict()
        user_data['id'] = user.id
        
        return jsonify({
            'user': user_data,
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting user: {e}")
        return jsonify({'error': 'Failed to get user'}), 500

@users_bp.route('/<user_id>', methods=['PUT'])
def update_user(user_id):
    """Update user profile"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        db = get_db()
        user_ref = db.collection('User').document(user_id)

        if not user_ref.get().exists:
            return jsonify({'error': 'User not found'}), 404

        data['updatedAt'] = datetime.utcnow()
        user_ref.update(data)
        
        updated_user = user_ref.get().to_dict()
        updated_user['id'] = user_ref.id
        
        return jsonify({
            'message': 'User updated successfully',
            'user': updated_user
        }), 200
        
    except Exception as e:
        logger.error(f"Error updating user: {e}")
        return jsonify({'error': 'Failed to update user'}), 500