from flask import Blueprint, request, jsonify, current_app
from bson import ObjectId
import logging
from datetime import datetime, timedelta
from backend.models.models import MealPlan
from backend.utils.meal_planner import MealPlanGenerator

logger = logging.getLogger(__name__)
meal_plans_bp = Blueprint('meal_plans', __name__)

@meal_plans_bp.route('/generate', methods=['POST'])
def generate_meal_plan():
    """Generate a meal plan based on user preferences"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Extract parameters
        user_id = data.get('user_id')
        days = data.get('days', 7)
        dietary_preferences = data.get('dietary_preferences', [])
        nutritional_goals = data.get('nutritional_goals', {})
        excluded_ingredients = data.get('excluded_ingredients', [])
        max_cooking_time = data.get('max_cooking_time', 60)
        budget_range = data.get('budget_range', 'medium')
        
        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400
        
        # Initialize meal plan generator
        generator = MealPlanGenerator(current_app.mongo.db)
        
        # Generate meal plan
        meal_plan = generator.generate_weekly_plan(
            user_id=user_id,
            days=days,
            dietary_preferences=dietary_preferences,
            nutritional_goals=nutritional_goals,
            excluded_ingredients=excluded_ingredients,
            max_cooking_time=max_cooking_time,
            budget_range=budget_range
        )
        
        if not meal_plan:
            return jsonify({'error': 'Could not generate meal plan'}), 500
        
        return jsonify({
            'meal_plan': meal_plan,
            'nutritional_summary': generator.calculate_plan_nutrition(meal_plan),
            'estimated_cost': generator.estimate_plan_cost(meal_plan)
        }), 200
        
    except Exception as e:
        logger.error(f"Error generating meal plan: {e}")
        return jsonify({'error': 'Failed to generate meal plan'}), 500

@meal_plans_bp.route('/', methods=['POST'])
def create_meal_plan():
    """Create and save a meal plan"""
    try:
        data = request.get_json()
        
        required_fields = ['user_id', 'title', 'start_date', 'end_date', 'meals']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Parse dates
        start_date = datetime.strptime(data['start_date'], '%Y-%m-%d')
        end_date = datetime.strptime(data['end_date'], '%Y-%m-%d')
        
        # Create meal plan object
        meal_plan = MealPlan(
            user_id=data['user_id'],
            title=data['title'],
            start_date=start_date,
            end_date=end_date,
            meals=data['meals']
        )
        
        # Save to database
        db = current_app.mongo.db
        result = db.meal_plans.insert_one(meal_plan.to_dict())
        
        # Return created meal plan
        created_plan = db.meal_plans.find_one({'_id': result.inserted_id})
        created_plan['_id'] = str(created_plan['_id'])
        
        return jsonify({
            'message': 'Meal plan created successfully',
            'meal_plan': created_plan
        }), 201
        
    except ValueError as e:
        return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
    except Exception as e:
        logger.error(f"Error creating meal plan: {e}")
        return jsonify({'error': 'Failed to create meal plan'}), 500

@meal_plans_bp.route('/user/<user_id>', methods=['GET'])
def get_user_meal_plans(user_id):
    """Get all meal plans for a user"""
    try:
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        # Get query parameters
        active_only = request.args.get('active_only', 'true').lower() == 'true'
        page = max(1, request.args.get('page', 1, type=int))
        per_page = min(50, request.args.get('per_page', 10, type=int))
        
        # Build query filter
        query_filter = {'user_id': user_id}
        if active_only:
            query_filter['is_active'] = True
        
        # Get meal plans with pagination
        db = current_app.mongo.db
        total_count = db.meal_plans.count_documents(query_filter)
        
        meal_plans = list(db.meal_plans.find(query_filter)
                         .sort('created_at', -1)
                         .skip((page - 1) * per_page)
                         .limit(per_page))
        
        # Convert ObjectIds to strings
        for plan in meal_plans:
            plan['_id'] = str(plan['_id'])
        
        return jsonify({
            'meal_plans': meal_plans,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total_count': total_count,
                'total_pages': (total_count + per_page - 1) // per_page
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting user meal plans: {e}")
        return jsonify({'error': 'Failed to get meal plans'}), 500

@meal_plans_bp.route('/<plan_id>', methods=['GET'])
def get_meal_plan(plan_id):
    """Get a specific meal plan"""
    try:
        if not ObjectId.is_valid(plan_id):
            return jsonify({'error': 'Invalid meal plan ID'}), 400
        
        db = current_app.mongo.db
        meal_plan = db.meal_plans.find_one({'_id': ObjectId(plan_id)})
        
        if not meal_plan:
            return jsonify({'error': 'Meal plan not found'}), 404
        
        meal_plan['_id'] = str(meal_plan['_id'])
        
        # Get recipe details for all meals
        recipe_ids = []
        for day_meals in meal_plan.get('meals', {}).values():
            for meal_type, recipe_id in day_meals.items():
                if recipe_id and ObjectId.is_valid(recipe_id):
                    recipe_ids.append(ObjectId(recipe_id))
        
        recipes = {}
        if recipe_ids:
            recipe_list = list(db.recipes.find({'_id': {'$in': recipe_ids}}))
            for recipe in recipe_list:
                recipe['_id'] = str(recipe['_id'])
                recipes[str(recipe['_id'])] = recipe
        
        # Calculate nutritional summary
        generator = MealPlanGenerator(db)
        nutritional_summary = generator.calculate_plan_nutrition(meal_plan)
        
        return jsonify({
            'meal_plan': meal_plan,
            'recipes': recipes,
            'nutritional_summary': nutritional_summary
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting meal plan: {e}")
        return jsonify({'error': 'Failed to get meal plan'}), 500

@meal_plans_bp.route('/<plan_id>', methods=['PUT'])
def update_meal_plan(plan_id):
    """Update an existing meal plan"""
    try:
        if not ObjectId.is_valid(plan_id):
            return jsonify({'error': 'Invalid meal plan ID'}), 400
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Parse dates if provided
        if 'start_date' in data:
            data['start_date'] = datetime.strptime(data['start_date'], '%Y-%m-%d')
        if 'end_date' in data:
            data['end_date'] = datetime.strptime(data['end_date'], '%Y-%m-%d')
        
        # Update timestamp
        data['updated_at'] = datetime.utcnow()
        
        # Update meal plan
        db = current_app.mongo.db
        result = db.meal_plans.update_one(
            {'_id': ObjectId(plan_id)},
            {'$set': data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Meal plan not found'}), 404
        
        # Return updated meal plan
        updated_plan = db.meal_plans.find_one({'_id': ObjectId(plan_id)})
        updated_plan['_id'] = str(updated_plan['_id'])
        
        return jsonify({
            'message': 'Meal plan updated successfully',
            'meal_plan': updated_plan
        }), 200
        
    except ValueError as e:
        return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
    except Exception as e:
        logger.error(f"Error updating meal plan: {e}")
        return jsonify({'error': 'Failed to update meal plan'}), 500

@meal_plans_bp.route('/<plan_id>', methods=['DELETE'])
def delete_meal_plan(plan_id):
    """Delete a meal plan (soft delete)"""
    try:
        if not ObjectId.is_valid(plan_id):
            return jsonify({'error': 'Invalid meal plan ID'}), 400
        
        db = current_app.mongo.db
        result = db.meal_plans.update_one(
            {'_id': ObjectId(plan_id)},
            {'$set': {'is_active': False, 'updated_at': datetime.utcnow()}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Meal plan not found'}), 404
        
        return jsonify({'message': 'Meal plan deleted successfully'}), 200
        
    except Exception as e:
        logger.error(f"Error deleting meal plan: {e}")
        return jsonify({'error': 'Failed to delete meal plan'}), 500

@meal_plans_bp.route('/<plan_id>/grocery-list', methods=['GET'])
def get_meal_plan_grocery_list(plan_id):
    """Generate grocery list for a meal plan"""
    try:
        if not ObjectId.is_valid(plan_id):
            return jsonify({'error': 'Invalid meal plan ID'}), 400
        
        db = current_app.mongo.db
        meal_plan = db.meal_plans.find_one({'_id': ObjectId(plan_id)})
        
        if not meal_plan:
            return jsonify({'error': 'Meal plan not found'}), 404
        
        # Generate grocery list
        from backend.utils.grocery_list_generator import GroceryListGenerator
        
        generator = GroceryListGenerator(db)
        grocery_list = generator.generate_from_meal_plan(meal_plan)
        
        return jsonify({
            'grocery_list': grocery_list,
            'meal_plan_id': plan_id,
            'meal_plan_title': meal_plan.get('title', 'Meal Plan')
        }), 200
        
    except Exception as e:
        logger.error(f"Error generating grocery list: {e}")
        return jsonify({'error': 'Failed to generate grocery list'}), 500

@meal_plans_bp.route('/suggestions', methods=['POST'])
def get_meal_suggestions():
    """Get meal suggestions for specific days/meals"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        meal_type = data.get('meal_type', 'dinner')  # breakfast, lunch, dinner, snack
        dietary_preferences = data.get('dietary_preferences', [])
        max_cooking_time = data.get('max_cooking_time', 30)
        exclude_recipes = data.get('exclude_recipes', [])
        
        # Build search criteria
        search_filter = {}
        
        if dietary_preferences:
            search_filter['dietary_tags'] = {'$in': dietary_preferences}
        
        if max_cooking_time:
            search_filter['cooking_time'] = {'$lte': max_cooking_time}
        
        if exclude_recipes:
            exclude_ids = [ObjectId(rid) for rid in exclude_recipes if ObjectId.is_valid(rid)]
            search_filter['_id'] = {'$nin': exclude_ids}
        
        # Get suggestions based on meal type
        db = current_app.mongo.db
        
        if meal_type == 'breakfast':
            # Lighter, quicker meals for breakfast
            search_filter['cooking_time'] = {'$lte': 20}
            search_filter['$or'] = [
                {'title': {'$regex': 'breakfast|smoothie|oatmeal|toast', '$options': 'i'}},
                {'dietary_tags': {'$in': ['breakfast', 'quick', 'light']}}
            ]
        
        suggestions = list(db.recipes.find(search_filter)
                          .sort('rating', -1)
                          .limit(10))
        
        # Convert ObjectIds to strings
        for recipe in suggestions:
            recipe['_id'] = str(recipe['_id'])
        
        return jsonify({
            'suggestions': suggestions,
            'meal_type': meal_type,
            'criteria': {
                'dietary_preferences': dietary_preferences,
                'max_cooking_time': max_cooking_time
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting meal suggestions: {e}")
        return jsonify({'error': 'Failed to get meal suggestions'}), 500