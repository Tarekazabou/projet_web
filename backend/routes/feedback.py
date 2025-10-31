from flask import Blueprint, request
from google.cloud.firestore_v1.base_query import FieldFilter
from utils.firebase_connector import get_db
from utils.auth import require_current_user
from utils.response_handler import success_response, error_response
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
feedback_bp = Blueprint('feedback', __name__)

@feedback_bp.route('/', methods=['POST'])
def submit_feedback():
    """Submit feedback for a recipe"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        if not data:
            return error_response('No data provided', 400)
        
        required_fields = ['recipe_id', 'rating']
        for field in required_fields:
            if field not in data:
                return error_response(f'Missing required field: {field}', 400)
        
        recipe_id = data['recipe_id']
        rating = data['rating']
        if not isinstance(rating, (int, float)) or not 1 <= rating <= 5:
            return error_response('Rating must be between 1 and 5', 400)
        
        feedback_data = {
            'user': db.collection('User').document(user_id),
            'recipe': db.collection('Recipe').document(recipe_id),
            'rating': rating,
            'comment': data.get('comment', ''),
            'createdAt': datetime.utcnow()
        }
        
        # Add new feedback
        _, new_feedback_ref = db.collection('Feedback').add(feedback_data)
        
        created_feedback = new_feedback_ref.get().to_dict()
        created_feedback['id'] = new_feedback_ref.id
        
        return success_response({
            'message': 'Feedback submitted successfully',
            'feedback': created_feedback
        }, 201)
        
    except Exception as e:
        logger.error(f"Error submitting feedback: {e}")
        return error_response('Failed to submit feedback', 500)

@feedback_bp.route('/recipe/<recipe_id>', methods=['GET'])
def get_recipe_feedback(recipe_id):
    """Get all feedback for a specific recipe"""
    try:
        db = get_db()
        
        query = db.collection('Feedback').where(filter=FieldFilter('recipe', '==', db.collection('Recipe').document(recipe_id)))
        
        docs = query.stream()
        
        feedback_list = []
        for doc in docs:
            feedback = doc.to_dict()
            feedback['id'] = doc.id
            # You would need to fetch user and recipe details separately if needed
            feedback_list.append(feedback)
        
        return success_response({'feedback': feedback_list})
        
    except Exception as e:
        logger.error(f"Error getting recipe feedback: {e}")
        return error_response('Failed to get feedback', 500)

@feedback_bp.route('/user/<user_id>', methods=['GET'])
def get_user_feedback(user_id):
    """Get all feedback submitted by a user"""
    try:
        db = get_db()
        
        query = db.collection('Feedback').where(filter=FieldFilter('user', '==', db.collection('User').document(user_id)))
        
        docs = query.stream()
        
        feedback_list = []
        for doc in docs:
            feedback = doc.to_dict()
            feedback['id'] = doc.id
            # You would need to fetch recipe details separately if needed
            feedback_list.append(feedback)
        
        return success_response({'feedback': feedback_list})
        
    except Exception as e:
        logger.error(f"Error getting user feedback: {e}")
        return error_response('Failed to get user feedback', 500)

@feedback_bp.route('/<feedback_id>', methods=['DELETE'])
def delete_feedback(feedback_id):
    """Delete feedback (only by feedback author)"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        feedback_ref = db.collection('Feedback').document(feedback_id)
        feedback = feedback_ref.get()
        
        if not feedback.exists:
            return error_response('Feedback not found', 404)
        
        feedback_data = feedback.to_dict()
        if feedback_data['user'].id != user_id:
            return error_response('Not authorized to delete this feedback', 403)
        
        # Delete feedback
        feedback_ref.delete()
        
        return success_response({'message': 'Feedback deleted successfully'})
        
    except Exception as e:
        logger.error(f"Error deleting feedback: {e}")
        return error_response('Failed to delete feedback', 500)