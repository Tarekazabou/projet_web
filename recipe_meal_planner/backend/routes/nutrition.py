from flask import Blueprint, request, jsonify, current_app
from bson import ObjectId
import logging
from backend.utils.nutrition_calculator import NutritionCalculator

logger = logging.getLogger(__name__)
nutrition_bp = Blueprint('nutrition', __name__)

@nutrition_bp.route('/analyze', methods=['POST'])
def analyze_nutrition():
    """Analyze nutritional content of ingredients or recipe"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        calculator = NutritionCalculator(current_app.mongo.db)
        
        # Check if analyzing a recipe or individual ingredients
        if 'recipe_id' in data:
            # Analyze existing recipe
            recipe_id = data['recipe_id']
            if not ObjectId.is_valid(recipe_id):
                return jsonify({'error': 'Invalid recipe ID'}), 400
            
            nutrition_data = calculator.analyze_recipe(recipe_id)
        
        elif 'ingredients' in data:
            # Analyze list of ingredients
            ingredients = data['ingredients']
            servings = data.get('servings', 1)
            nutrition_data = calculator.analyze_ingredients(ingredients, servings)
        
        else:
            return jsonify({'error': 'Either recipe_id or ingredients must be provided'}), 400
        
        if not nutrition_data:
            return jsonify({'error': 'Could not analyze nutrition'}), 500
        
        return jsonify({
            'nutrition': nutrition_data,
            'analysis_date': calculator.get_current_timestamp()
        }), 200
        
    except Exception as e:
        logger.error(f"Error analyzing nutrition: {e}")
        return jsonify({'error': 'Failed to analyze nutrition'}), 500

@nutrition_bp.route('/daily-goals', methods=['POST'])
def calculate_daily_goals():
    """Calculate daily nutritional goals based on user profile"""
    try:
        data = request.get_json()
        
        required_fields = ['age', 'gender', 'weight', 'height', 'activity_level']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        calculator = NutritionCalculator(current_app.mongo.db)
        
        goals = calculator.calculate_daily_goals(
            age=data['age'],
            gender=data['gender'],
            weight=data['weight'],  # in kg
            height=data['height'],  # in cm
            activity_level=data['activity_level'],  # sedentary, light, moderate, active, very_active
            goal=data.get('goal', 'maintain')  # lose, maintain, gain
        )
        
        return jsonify({
            'daily_goals': goals,
            'recommendations': calculator.get_nutrition_recommendations(goals)
        }), 200
        
    except Exception as e:
        logger.error(f"Error calculating daily goals: {e}")
        return jsonify({'error': 'Failed to calculate daily goals'}), 500

@nutrition_bp.route('/track', methods=['POST'])
def track_nutrition():
    """Track daily nutrition intake"""
    try:
        data = request.get_json()
        
        if not data or 'user_id' not in data:
            return jsonify({'error': 'User ID is required'}), 400
        
        user_id = data['user_id']
        date = data.get('date')  # YYYY-MM-DD format
        meals = data.get('meals', {})  # {breakfast: [recipe_ids], lunch: [...], ...}
        
        calculator = NutritionCalculator(current_app.mongo.db)
        
        # Calculate total nutrition for the day
        daily_nutrition = calculator.calculate_daily_intake(meals)
        
        # Get user's daily goals
        user = current_app.mongo.db.users.find_one({'_id': ObjectId(user_id)})
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        goals = user.get('nutritional_goals', {})
        
        # Calculate progress towards goals
        progress = calculator.calculate_progress(daily_nutrition, goals)
        
        # Store tracking data
        tracking_data = {
            'user_id': user_id,
            'date': date,
            'meals': meals,
            'total_nutrition': daily_nutrition,
            'goals': goals,
            'progress': progress,
            'created_at': calculator.get_current_timestamp()
        }
        
        current_app.mongo.db.nutrition_tracking.insert_one(tracking_data)
        
        return jsonify({
            'daily_nutrition': daily_nutrition,
            'goals': goals,
            'progress': progress,
            'recommendations': calculator.get_meal_recommendations(daily_nutrition, goals)
        }), 200
        
    except Exception as e:
        logger.error(f"Error tracking nutrition: {e}")
        return jsonify({'error': 'Failed to track nutrition'}), 500

@nutrition_bp.route('/history/<user_id>', methods=['GET'])
def get_nutrition_history(user_id):
    """Get nutrition history for a user"""
    try:
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        # Get query parameters
        days = request.args.get('days', 7, type=int)
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        # Build query filter
        query_filter = {'user_id': user_id}
        
        if start_date and end_date:
            query_filter['date'] = {'$gte': start_date, '$lte': end_date}
        elif days:
            # Get last N days
            from datetime import datetime, timedelta
            end = datetime.now()
            start = end - timedelta(days=days)
            query_filter['date'] = {
                '$gte': start.strftime('%Y-%m-%d'),
                '$lte': end.strftime('%Y-%m-%d')
            }
        
        # Get nutrition history
        db = current_app.mongo.db
        history = list(db.nutrition_tracking.find(query_filter).sort('date', -1))
        
        # Convert ObjectIds to strings
        for entry in history:
            entry['_id'] = str(entry['_id'])
        
        # Calculate averages and trends
        calculator = NutritionCalculator(db)
        analytics = calculator.calculate_nutrition_analytics(history)
        
        return jsonify({
            'history': history,
            'analytics': analytics,
            'period': {
                'days': days,
                'start_date': start_date,
                'end_date': end_date
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting nutrition history: {e}")
        return jsonify({'error': 'Failed to get nutrition history'}), 500

@nutrition_bp.route('/ingredients/search', methods=['GET'])
def search_ingredients():
    """Search nutritional database for ingredients"""
    try:
        query = request.args.get('q', '')
        limit = min(50, request.args.get('limit', 20, type=int))
        
        if not query:
            return jsonify({'error': 'Search query is required'}), 400
        
        # Search ingredients database
        db = current_app.mongo.db
        ingredients = list(db.ingredients.find({
            'name': {'$regex': query, '$options': 'i'}
        }).limit(limit))
        
        # Convert ObjectIds to strings
        for ingredient in ingredients:
            ingredient['_id'] = str(ingredient['_id'])
        
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
        if not ObjectId.is_valid(ingredient_id):
            return jsonify({'error': 'Invalid ingredient ID'}), 400
        
        db = current_app.mongo.db
        ingredient = db.ingredients.find_one({'_id': ObjectId(ingredient_id)})
        
        if not ingredient:
            return jsonify({'error': 'Ingredient not found'}), 404
        
        ingredient['_id'] = str(ingredient['_id'])
        
        # Get recipes that use this ingredient
        recipes_using = list(db.recipes.find({
            'ingredients.name': ingredient['name']
        }).limit(10))
        
        for recipe in recipes_using:
            recipe['_id'] = str(recipe['_id'])
        
        return jsonify({
            'ingredient': ingredient,
            'recipes_using': recipes_using
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting ingredient nutrition: {e}")
        return jsonify({'error': 'Failed to get ingredient nutrition'}), 500

@nutrition_bp.route('/compare', methods=['POST'])
def compare_nutrition():
    """Compare nutritional content of multiple recipes or ingredients"""
    try:
        data = request.get_json()
        
        if not data or 'items' not in data:
            return jsonify({'error': 'Items to compare are required'}), 400
        
        items = data['items']  # List of recipe IDs or ingredient combinations
        comparison_type = data.get('type', 'recipes')  # 'recipes' or 'ingredients'
        
        calculator = NutritionCalculator(current_app.mongo.db)
        
        if comparison_type == 'recipes':
            comparison = calculator.compare_recipes(items)
        else:
            comparison = calculator.compare_ingredients(items)
        
        return jsonify({
            'comparison': comparison,
            'type': comparison_type,
            'analysis_date': calculator.get_current_timestamp()
        }), 200
        
    except Exception as e:
        logger.error(f"Error comparing nutrition: {e}")
        return jsonify({'error': 'Failed to compare nutrition'}), 500