from flask import Blueprint, request, jsonify, current_app
from bson import ObjectId
import logging
from datetime import datetime
from backend.models.models import User

logger = logging.getLogger(__name__)
users_bp = Blueprint('users', __name__)

@users_bp.route('/', methods=['POST'])
def create_user():
    """Create a new user profile"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        required_fields = ['username', 'email']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Check if user already exists
        db = current_app.mongo.db
        existing_user = db.users.find_one({
            '$or': [
                {'username': data['username']},
                {'email': data['email']}
            ]
        })
        
        if existing_user:
            return jsonify({'error': 'User with this username or email already exists'}), 409
        
        # Create user object
        user = User(
            username=data['username'],
            email=data['email'],
            dietary_preferences=data.get('dietary_preferences', []),
            allergies=data.get('allergies', []),
            nutritional_goals=data.get('nutritional_goals', {})
        )
        
        # Insert into database
        result = db.users.insert_one(user.to_dict())
        
        # Return created user
        created_user = db.users.find_one({'_id': result.inserted_id})
        created_user['_id'] = str(created_user['_id'])
        
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
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        db = current_app.mongo.db
        user = db.users.find_one({'_id': ObjectId(user_id)})
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        user['_id'] = str(user['_id'])
        
        # Get user statistics
        stats = get_user_statistics(db, user_id)
        
        return jsonify({
            'user': user,
            'statistics': stats
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting user: {e}")
        return jsonify({'error': 'Failed to get user'}), 500

@users_bp.route('/<user_id>', methods=['PUT'])
def update_user(user_id):
    """Update user profile"""
    try:
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Update timestamp
        data['updated_at'] = datetime.utcnow()
        
        # Update user in database
        db = current_app.mongo.db
        result = db.users.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        # Return updated user
        updated_user = db.users.find_one({'_id': ObjectId(user_id)})
        updated_user['_id'] = str(updated_user['_id'])
        
        return jsonify({
            'message': 'User updated successfully',
            'user': updated_user
        }), 200
        
    except Exception as e:
        logger.error(f"Error updating user: {e}")
        return jsonify({'error': 'Failed to update user'}), 500

@users_bp.route('/<user_id>/preferences', methods=['PUT'])
def update_preferences(user_id):
    """Update user dietary preferences and nutritional goals"""
    try:
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        update_data = {}
        
        if 'dietary_preferences' in data:
            update_data['dietary_preferences'] = data['dietary_preferences']
        
        if 'allergies' in data:
            update_data['allergies'] = data['allergies']
        
        if 'nutritional_goals' in data:
            update_data['nutritional_goals'] = data['nutritional_goals']
        
        update_data['updated_at'] = datetime.utcnow()
        
        # Update user preferences
        db = current_app.mongo.db
        result = db.users.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        # Return updated preferences
        updated_user = db.users.find_one({'_id': ObjectId(user_id)})
        
        return jsonify({
            'message': 'Preferences updated successfully',
            'dietary_preferences': updated_user.get('dietary_preferences', []),
            'allergies': updated_user.get('allergies', []),
            'nutritional_goals': updated_user.get('nutritional_goals', {})
        }), 200
        
    except Exception as e:
        logger.error(f"Error updating preferences: {e}")
        return jsonify({'error': 'Failed to update preferences'}), 500

@users_bp.route('/<user_id>/favorites', methods=['GET'])
def get_favorite_recipes(user_id):
    """Get user's favorite recipes"""
    try:
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        db = current_app.mongo.db
        user = db.users.find_one({'_id': ObjectId(user_id)})
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        favorite_recipe_ids = user.get('favorite_recipes', [])
        
        if not favorite_recipe_ids:
            return jsonify({'favorite_recipes': []}), 200
        
        # Convert string IDs to ObjectId
        object_ids = [ObjectId(rid) for rid in favorite_recipe_ids if ObjectId.is_valid(rid)]
        
        # Get recipe details
        recipes = list(db.recipes.find({'_id': {'$in': object_ids}}))
        
        # Convert ObjectIds back to strings
        for recipe in recipes:
            recipe['_id'] = str(recipe['_id'])
        
        return jsonify({'favorite_recipes': recipes}), 200
        
    except Exception as e:
        logger.error(f"Error getting favorite recipes: {e}")
        return jsonify({'error': 'Failed to get favorite recipes'}), 500

@users_bp.route('/<user_id>/favorites/<recipe_id>', methods=['POST'])
def add_favorite_recipe(user_id, recipe_id):
    """Add recipe to user's favorites"""
    try:
        if not ObjectId.is_valid(user_id) or not ObjectId.is_valid(recipe_id):
            return jsonify({'error': 'Invalid user ID or recipe ID'}), 400
        
        db = current_app.mongo.db
        
        # Check if recipe exists
        recipe = db.recipes.find_one({'_id': ObjectId(recipe_id)})
        if not recipe:
            return jsonify({'error': 'Recipe not found'}), 404
        
        # Add to favorites
        result = db.users.update_one(
            {'_id': ObjectId(user_id)},
            {'$addToSet': {'favorite_recipes': recipe_id}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'message': 'Recipe added to favorites'}), 200
        
    except Exception as e:
        logger.error(f"Error adding favorite recipe: {e}")
        return jsonify({'error': 'Failed to add favorite recipe'}), 500

@users_bp.route('/<user_id>/favorites/<recipe_id>', methods=['DELETE'])
def remove_favorite_recipe(user_id, recipe_id):
    """Remove recipe from user's favorites"""
    try:
        if not ObjectId.is_valid(user_id) or not ObjectId.is_valid(recipe_id):
            return jsonify({'error': 'Invalid user ID or recipe ID'}), 400
        
        db = current_app.mongo.db
        
        # Remove from favorites
        result = db.users.update_one(
            {'_id': ObjectId(user_id)},
            {'$pull': {'favorite_recipes': recipe_id}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'message': 'Recipe removed from favorites'}), 200
        
    except Exception as e:
        logger.error(f"Error removing favorite recipe: {e}")
        return jsonify({'error': 'Failed to remove favorite recipe'}), 500

@users_bp.route('/<user_id>/recommendations', methods=['GET'])
def get_user_recommendations(user_id):
    """Get personalized recipe recommendations for user"""
    try:
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        db = current_app.mongo.db
        user = db.users.find_one({'_id': ObjectId(user_id)})
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get recommendations based on user preferences
        recommendations = generate_user_recommendations(db, user)
        
        return jsonify({
            'recommendations': recommendations,
            'user_id': user_id
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting recommendations: {e}")
        return jsonify({'error': 'Failed to get recommendations'}), 500

@users_bp.route('/<user_id>/activity', methods=['GET'])
def get_user_activity(user_id):
    """Get user's recent activity"""
    try:
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        db = current_app.mongo.db
        
        # Get recent feedback
        recent_feedback = list(db.feedback.find({'user_id': user_id})
                             .sort('created_at', -1)
                             .limit(10))
        
        # Get recent meal plans
        recent_meal_plans = list(db.meal_plans.find({'user_id': user_id})
                               .sort('created_at', -1)
                               .limit(5))
        
        # Convert ObjectIds to strings
        for feedback in recent_feedback:
            feedback['_id'] = str(feedback['_id'])
        
        for plan in recent_meal_plans:
            plan['_id'] = str(plan['_id'])
        
        return jsonify({
            'recent_feedback': recent_feedback,
            'recent_meal_plans': recent_meal_plans,
            'user_id': user_id
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting user activity: {e}")
        return jsonify({'error': 'Failed to get user activity'}), 500

def get_user_statistics(db, user_id):
    """Get user statistics"""
    try:
        stats = {}
        
        # Count of feedback given
        stats['feedback_count'] = db.feedback.count_documents({'user_id': user_id})
        
        # Count of meal plans created
        stats['meal_plans_count'] = db.meal_plans.count_documents({'user_id': user_id})
        
        # Count of favorite recipes
        user = db.users.find_one({'_id': ObjectId(user_id)})
        stats['favorite_recipes_count'] = len(user.get('favorite_recipes', [])) if user else 0
        
        # Average rating given
        pipeline = [
            {'$match': {'user_id': user_id}},
            {'$group': {'_id': None, 'avg_rating': {'$avg': '$rating'}}}
        ]
        avg_result = list(db.feedback.aggregate(pipeline))
        stats['average_rating_given'] = round(avg_result[0]['avg_rating'], 1) if avg_result else 0
        
        return stats
        
    except Exception as e:
        logger.error(f"Error getting user statistics: {e}")
        return {}

def generate_user_recommendations(db, user):
    """Generate personalized recommendations for user"""
    try:
        recommendations = {
            'based_on_preferences': [],
            'popular_in_category': [],
            'try_something_new': []
        }
        
        dietary_preferences = user.get('dietary_preferences', [])
        favorite_recipes = user.get('favorite_recipes', [])
        
        # Recommendations based on dietary preferences
        if dietary_preferences:
            pref_recipes = list(db.recipes.find({
                'dietary_tags': {'$in': dietary_preferences},
                '_id': {'$nin': [ObjectId(rid) for rid in favorite_recipes if ObjectId.is_valid(rid)]}
            }).sort('rating', -1).limit(5))
            
            for recipe in pref_recipes:
                recipe['_id'] = str(recipe['_id'])
            
            recommendations['based_on_preferences'] = pref_recipes
        
        # Popular recipes in user's categories
        if dietary_preferences:
            popular_recipes = list(db.recipes.find({
                'dietary_tags': {'$in': dietary_preferences},
                'review_count': {'$gte': 5}
            }).sort('rating', -1).limit(5))
            
            for recipe in popular_recipes:
                recipe['_id'] = str(recipe['_id'])
            
            recommendations['popular_in_category'] = popular_recipes
        
        # Try something new (different dietary tags)
        excluded_tags = dietary_preferences + ['meat'] if 'vegan' in dietary_preferences else []
        new_recipes = list(db.recipes.find({
            'dietary_tags': {'$nin': excluded_tags} if excluded_tags else {},
            '_id': {'$nin': [ObjectId(rid) for rid in favorite_recipes if ObjectId.is_valid(rid)]},
            'rating': {'$gte': 4.0}
        }).sort('rating', -1).limit(3))
        
        for recipe in new_recipes:
            recipe['_id'] = str(recipe['_id'])
        
        recommendations['try_something_new'] = new_recipes
        
        return recommendations
        
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        return {}