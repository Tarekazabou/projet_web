from flask import Blueprint, request, jsonify
from google.cloud.firestore_v1.base_query import FieldFilter
from utils.firebase_connector import get_db
from utils.auth import require_current_user
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)
nutrition_bp = Blueprint('nutrition', __name__)

@nutrition_bp.route('/analyze', methods=['POST'])
def analyze_nutrition():
    """
    Analyze nutritional content of a recipe.
    This is a simplified version. The original logic was in NutritionCalculator.
    """
    try:
        db = get_db()
        data = request.get_json()

        if not data or 'recipe_id' not in data:
            return jsonify({'error': 'recipe_id must be provided'}), 400

        recipe_id = data['recipe_id']
        recipe_ref = db.collection('Recipe').document(recipe_id)
        recipe = recipe_ref.get()

        if not recipe.exists:
            return jsonify({'error': 'Recipe not found'}), 404

        recipe_data = recipe.to_dict()
        
        # In a real implementation, you would fetch each ingredient's nutrition data
        # and calculate the total for the recipe.
        # For now, we'll just return a placeholder.
        
        # This assumes the recipe document has a 'nutrition' field.
        nutrition_data = recipe_data.get('nutrition', {})

        return jsonify({
            'nutrition': nutrition_data,
        }), 200
        
    except Exception as e:
        logger.error(f"Error analyzing nutrition: {e}")
        return jsonify({'error': 'Failed to analyze nutrition'}), 500

@nutrition_bp.route('/ingredients/search', methods=['GET'])
def search_ingredients():
    """Search nutritional database for ingredients"""
    try:
        db = get_db()
        query_text = request.args.get('q', '')
        limit = min(50, request.args.get('limit', 20, type=int))
        
        if not query_text:
            return jsonify({'error': 'Search query is required'}), 400
        
        query = db.collection('Ingredient').where(filter=FieldFilter('name', '>=', query_text)).where(filter=FieldFilter('name', '<=', query_text + '\uf8ff')).limit(limit)
        
        docs = query.stream()
        
        ingredients = []
        for doc in docs:
            ingredient = doc.to_dict()
            ingredient['id'] = doc.id
            ingredients.append(ingredient)
        
        return jsonify({
            'ingredients': ingredients,
            'count': len(ingredients)
        }), 200
        
    except Exception as e:
        logger.error(f"Error searching ingredients: {e}")
        return jsonify({'error': 'Failed to search ingredients'}), 500

@nutrition_bp.route('/ingredients/<ingredient_id>', methods=['GET'])
def get_ingredient_nutrition(ingredient_id):
    """Get detailed nutrition information for an ingredient"""
    try:
        db = get_db()
        ingredient_ref = db.collection('Ingredient').document(ingredient_id)
        ingredient = ingredient_ref.get()
        
        if not ingredient.exists:
            return jsonify({'error': 'Ingredient not found'}), 404
        
        ingredient_data = ingredient.to_dict()
        ingredient_data['id'] = ingredient.id
        
        return jsonify({
            'ingredient': ingredient_data,
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting ingredient nutrition: {e}")
        return jsonify({'error': 'Failed to get ingredient nutrition'}), 500

@nutrition_bp.route('/goals', methods=['GET'])
def get_nutrition_goals():
    """Get user's daily nutrition goals"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        user_ref = db.collection('User').document(user_id)
        user = user_ref.get()
        
        if not user.exists:
            return jsonify({'error': 'User not found'}), 404
        
        user_data = user.to_dict()
        
        # Return default goals if not set
        goals = user_data.get('nutritionGoals', {
            'calories': 2000,
            'protein': 50,
            'carbs': 250,
            'fat': 70,
            'fiber': 25,
            'water': 8
        })
        
        return jsonify({'goals': goals}), 200
        
    except Exception as e:
        logger.error(f"Error getting nutrition goals: {e}")
        return jsonify({'error': 'Failed to get nutrition goals'}), 500

@nutrition_bp.route('/goals', methods=['POST'])
def set_nutrition_goals():
    """Set user's daily nutrition goals"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        user_ref = db.collection('User').document(user_id)
        
        if not user_ref.get().exists:
            return jsonify({'error': 'User not found'}), 404
        
        user_ref.update({'nutritionGoals': data})
        
        return jsonify({
            'message': 'Nutrition goals updated successfully',
            'goals': data
        }), 200
        
    except Exception as e:
        logger.error(f"Error setting nutrition goals: {e}")
        return jsonify({'error': 'Failed to set nutrition goals'}), 500

@nutrition_bp.route('/daily/<date_str>', methods=['GET'])
def get_daily_nutrition(date_str):
    """Get nutrition data for a specific date"""
    try:
        user_id = require_current_user()
        db = get_db()
        user_ref = db.collection('User').document(user_id)
        
        # Query meals for the specific date
        query = db.collection('NutritionLog').where(
            filter=FieldFilter('user', '==', user_ref)
        ).where(
            filter=FieldFilter('date', '==', date_str)
        )
        
        docs = query.stream()
        
        meals = []
        total_nutrition = {
            'calories': 0,
            'protein': 0,
            'carbs': 0,
            'fat': 0,
            'fiber': 0
        }
        
        for doc in docs:
            meal = doc.to_dict()
            meal['id'] = doc.id
            # Convert user reference to id string
            if 'user' in meal and hasattr(meal['user'], 'id'):
                meal['user'] = meal['user'].id
            if 'recipe' in meal and meal['recipe'] and hasattr(meal['recipe'], 'id'):
                meal['recipe'] = meal['recipe'].id
            meals.append(meal)
            
            # Aggregate nutrition
            nutrition = meal.get('nutrition', {})
            for key in total_nutrition:
                total_nutrition[key] += nutrition.get(key, 0)
        
        # Get water intake for the date
        water_query = db.collection('WaterIntake').where(
            filter=FieldFilter('user', '==', user_ref)
        ).where(
            filter=FieldFilter('date', '==', date_str)
        ).limit(1)
        
        water_docs = list(water_query.stream())
        water_intake = water_docs[0].to_dict().get('amount', 0) if water_docs else 0
        
        # Get user goals
        user_doc = user_ref.get()
        goals = {}
        if user_doc.exists:
            user_data = user_doc.to_dict()
            goals = user_data.get('nutritionGoals', {
                'calories': 2000,
                'protein': 50,
                'carbs': 250,
                'fat': 70,
                'fiber': 25,
                'water': 8
            })
        
        return jsonify({
            'date': date_str,
            'meals': meals,
            'total_nutrition': total_nutrition,
            'water_intake': water_intake,
            'goals': goals
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting daily nutrition: {e}")
        return jsonify({'error': 'Failed to get daily nutrition'}), 500

@nutrition_bp.route('/log-meal', methods=['POST'])
def log_meal():
    """Log a meal with nutrition information"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        required_fields = ['mealName', 'date', 'nutrition']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        user_ref = db.collection('User').document(user_id)
        
        meal_data = {
            'user': user_ref,
            'mealName': data['mealName'],
            'date': data['date'],
            'mealType': data.get('mealType', 'other'),
            'nutrition': data['nutrition'],
            'createdAt': datetime.utcnow()
        }
        
        # Only add recipe reference if provided
        if 'recipe' in data and data['recipe']:
            meal_data['recipe'] = db.collection('Recipe').document(data['recipe'])
        
        _, new_log_ref = db.collection('NutritionLog').add(meal_data)
        
        # Return cleaned response
        response_meal = {
            'id': new_log_ref.id,
            'mealName': data['mealName'],
            'date': data['date'],
            'mealType': data.get('mealType', 'other'),
            'nutrition': data['nutrition'],
        }
        
        return jsonify({
            'message': 'Meal logged successfully',
            'meal': response_meal
        }), 201
        
    except Exception as e:
        logger.error(f"Error logging meal: {e}")
        return jsonify({'error': 'Failed to log meal'}), 500

@nutrition_bp.route('/meals/<meal_id>', methods=['DELETE'])
def delete_meal_log(meal_id):
    """Delete a meal log entry"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        meal_ref = db.collection('NutritionLog').document(meal_id)
        meal_doc = meal_ref.get()
        
        if not meal_doc.exists:
            return jsonify({'error': 'Meal log not found'}), 404
        
        meal_data = meal_doc.to_dict()
        if meal_data['user'].id != user_id:
            return jsonify({'error': 'Not authorized to delete this meal log'}), 403
        
        meal_ref.delete()
        
        return jsonify({'message': 'Meal log deleted successfully'}), 200
        
    except Exception as e:
        logger.error(f"Error deleting meal log: {e}")
        return jsonify({'error': 'Failed to delete meal log'}), 500

@nutrition_bp.route('/water-intake', methods=['POST'])
def log_water_intake():
    """Log water intake - sets the total glasses for the day"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        if not data or 'amount' not in data or 'date' not in data:
            return jsonify({'error': 'amount and date are required'}), 400
        
        user_ref = db.collection('User').document(user_id)
        date_str = data['date']
        amount = data['amount']
        
        # Find or create water log for the date
        query = db.collection('WaterIntake').where(
            filter=FieldFilter('user', '==', user_ref)
        ).where(
            filter=FieldFilter('date', '==', date_str)
        ).limit(1)
        docs = list(query.stream())
        
        if docs:
            # Update existing - set the exact amount
            water_ref = docs[0].reference
            water_ref.update({
                'amount': amount,
                'updatedAt': datetime.utcnow()
            })
            
            return jsonify({
                'message': 'Water intake updated',
                'water_intake': {
                    'id': water_ref.id,
                    'date': date_str,
                    'amount': amount
                }
            }), 200
        else:
            # Create new
            water_data = {
                'user': user_ref,
                'date': date_str,
                'amount': amount,
                'createdAt': datetime.utcnow()
            }
            
            _, new_ref = db.collection('WaterIntake').add(water_data)
            
            return jsonify({
                'message': 'Water intake logged',
                'water_intake': {
                    'id': new_ref.id,
                    'date': date_str,
                    'amount': amount
                }
            }), 201
        
    except Exception as e:
        logger.error(f"Error logging water intake: {e}")
        return jsonify({'error': 'Failed to log water intake'}), 500


@nutrition_bp.route('/weekly-trend', methods=['GET'])
def get_weekly_trend():
    """Get weekly nutrition trend data"""
    try:
        user_id = require_current_user()
        db = get_db()
        today = datetime.now()
        
        # Get data for the last 7 days
        trend_data = []
        for i in range(6, -1, -1):  # Start from 6 days ago to today
            date = today - timedelta(days=i)
            date_str = date.strftime('%Y-%m-%d')
            
            # Try to get nutrition data for this day
            daily_ref = db.collection('users').document(user_id).collection('nutrition').document(date_str)
            daily_data = daily_ref.get()
            
            if daily_data.exists:
                data = daily_data.to_dict()
                totals = data.get('totals', data.get('total_nutrition', {}))
                trend_data.append({
                    'date': date_str,
                    'day': date.strftime('%a'),
                    'calories': totals.get('calories', 0),
                    'protein': totals.get('protein', 0),
                    'carbs': totals.get('carbs', 0),
                    'fat': totals.get('fat', 0)
                })
            else:
                # No data for this day
                trend_data.append({
                    'date': date_str,
                    'day': date.strftime('%a'),
                    'calories': 0,
                    'protein': 0,
                    'carbs': 0,
                    'fat': 0
                })
        
        return jsonify({
            'trend': trend_data,
            'period': 'weekly'
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting weekly trend: {e}")
        return jsonify({'error': 'Failed to get weekly trend'}), 500