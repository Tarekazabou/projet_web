from flask import Blueprint, request, jsonify
from utils.firebase_connector import get_db
from utils.auth import require_current_user
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
meal_plans_bp = Blueprint('meal_plans', __name__)

@meal_plans_bp.route('/', methods=['POST'])
def create_meal_plan():
    """Create and save a meal plan"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        required_fields = ['recipe', 'planDate', 'mealType']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Create meal plan object
        meal_plan_data = {
            'user': db.collection('User').document(user_id),
            'recipe': db.collection('Recipe').document(data['recipe']),
            'planDate': data['planDate'], # Should be in 'YYYY-MM-DD' format
            'mealType': data['mealType']
        }
        
        _, new_plan_ref = db.collection('MealPlan').add(meal_plan_data)
        
        created_plan = new_plan_ref.get().to_dict()
        created_plan['id'] = new_plan_ref.id
        
        return jsonify({
            'message': 'Meal plan created successfully',
            'meal_plan': created_plan
        }), 201
        
    except Exception as e:
        logger.error(f"Error creating meal plan: {e}")
        return jsonify({'error': 'Failed to create meal plan'}), 500

@meal_plans_bp.route('/', methods=['GET'])
def get_meal_plans():
    """Get meal plans for the authenticated user with optional date filtering"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        # Get query parameters
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        query = db.collection('MealPlan').where('user', '==', db.collection('User').document(user_id))
        
        # Apply date filters if provided
        if start_date:
            query = query.where('planDate', '>=', start_date)
        if end_date:
            query = query.where('planDate', '<=', end_date)
        
        docs = query.stream()
        
        meal_plans = []
        for doc in docs:
            plan = doc.to_dict()
            plan['id'] = doc.id
            meal_plans.append(plan)
        
        return jsonify({
            'meal_plans': meal_plans,
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting meal plans: {e}")
        return jsonify({'error': 'Failed to get meal plans'}), 500

@meal_plans_bp.route('/user/<user_id>', methods=['GET'])
def get_user_meal_plans(user_id):
    """Get all meal plans for a user"""
    try:
        db = get_db()
        
        query = db.collection('MealPlan').where('user', '==', db.collection('User').document(user_id))
        
        docs = query.stream()
        
        meal_plans = []
        for doc in docs:
            plan = doc.to_dict()
            plan['id'] = doc.id
            meal_plans.append(plan)
        
        return jsonify({
            'meal_plans': meal_plans,
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting user meal plans: {e}")
        return jsonify({'error': 'Failed to get meal plans'}), 500

@meal_plans_bp.route('/<plan_id>', methods=['GET'])
def get_meal_plan(plan_id):
    """Get a specific meal plan"""
    try:
        db = get_db()
        plan_ref = db.collection('MealPlan').document(plan_id)
        meal_plan = plan_ref.get()
        
        if not meal_plan.exists:
            return jsonify({'error': 'Meal plan not found'}), 404
        
        plan_data = meal_plan.to_dict()
        plan_data['id'] = meal_plan.id
        
        return jsonify({
            'meal_plan': plan_data,
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting meal plan: {e}")
        return jsonify({'error': 'Failed to get meal plan'}), 500

@meal_plans_bp.route('/<plan_id>', methods=['PUT'])
def update_meal_plan(plan_id):
    """Update an existing meal plan"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        plan_ref = db.collection('MealPlan').document(plan_id)

        # Verify the plan belongs to the user
        plan_doc = plan_ref.get()
        if not plan_doc.exists or plan_doc.to_dict()['user'].id != user_id:
            return jsonify({'error': 'Meal plan not found'}), 404

        update_data = {}
        allowed_fields = ['recipe', 'planDate', 'mealType']
        for field in allowed_fields:
            if field in data:
                if field == 'recipe':
                    update_data[field] = db.collection('Recipe').document(data[field])
                else:
                    update_data[field] = data[field]

        if update_data:
            plan_ref.update(update_data)
        
        updated_plan = plan_ref.get().to_dict()
        updated_plan['id'] = plan_ref.id
        
        return jsonify({
            'message': 'Meal plan updated successfully',
            'meal_plan': updated_plan
        }), 200
        
    except Exception as e:
        logger.error(f"Error updating meal plan: {e}")
        return jsonify({'error': 'Failed to update meal plan'}), 500

@meal_plans_bp.route('/<plan_id>', methods=['DELETE'])
def delete_meal_plan(plan_id):
    """Delete a meal plan"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        plan_ref = db.collection('MealPlan').document(plan_id)

        # Verify the plan belongs to the user
        plan_doc = plan_ref.get()
        if not plan_doc.exists or plan_doc.to_dict()['user'].id != user_id:
            return jsonify({'error': 'Meal plan not found'}), 404

        plan_ref.delete()
        
        return jsonify({'message': 'Meal plan deleted successfully'}), 200
        
    except Exception as e:
        logger.error(f"Error deleting meal plan: {e}")
        return jsonify({'error': 'Failed to delete meal plan'}), 500