from flask import Blueprint, request, jsonify
from google.cloud.firestore_v1.base_query import FieldFilter
from utils.firebase_connector import get_db
from utils.auth import require_current_user
from utils.response_handler import success_response, error_response
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)
meal_plans_bp = Blueprint('meal_plans', __name__)


def _serialize_meal_plan(plan_data, plan_id, db):
    """Serialize meal plan data for JSON response"""
    result = {
        'id': plan_id,
        'planDate': plan_data.get('planDate'),
        'mealType': plan_data.get('mealType'),
        'servings': plan_data.get('servings', 1),
        'notes': plan_data.get('notes', ''),
        'createdAt': plan_data.get('createdAt').isoformat() if plan_data.get('createdAt') else None,
    }
    
    # Handle recipe - could be a reference or inline data
    recipe_ref = plan_data.get('recipe')
    if recipe_ref:
        if hasattr(recipe_ref, 'get'):
            # It's a DocumentReference
            recipe_doc = recipe_ref.get()
            if recipe_doc.exists:
                recipe_data = recipe_doc.to_dict()
                result['recipe'] = {
                    'id': recipe_doc.id,
                    'name': recipe_data.get('name', ''),
                    'calories': recipe_data.get('calories', 0),
                    'prepTime': recipe_data.get('prepTime', 0),
                    'imageUrl': recipe_data.get('imageUrl', ''),
                    'ingredients': recipe_data.get('ingredients', []),
                }
        else:
            # It's inline recipe data
            result['recipe'] = recipe_ref
    else:
        # Check for inline meal data (name, calories directly in plan)
        result['recipe'] = {
            'name': plan_data.get('mealName', ''),
            'calories': plan_data.get('calories', 0),
        }
    
    return result


@meal_plans_bp.route('/', methods=['POST'])
def create_meal_plan():
    """Create and save a meal plan"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        if not data:
            return error_response('No data provided', 400)
        
        required_fields = ['planDate', 'mealType']
        for field in required_fields:
            if field not in data:
                return error_response(f'Missing required field: {field}', 400)
        
        # Create meal plan object
        meal_plan_data = {
            'userId': user_id,
            'planDate': data['planDate'],
            'mealType': data['mealType'],
            'servings': data.get('servings', 1),
            'notes': data.get('notes', ''),
            'createdAt': datetime.utcnow(),
        }
        
        # Handle recipe - can be a recipe ID or inline meal data
        if 'recipeId' in data:
            meal_plan_data['recipe'] = db.collection('Recipe').document(data['recipeId'])
        else:
            # Store inline meal data
            meal_plan_data['mealName'] = data.get('mealName', '')
            meal_plan_data['calories'] = data.get('calories', 0)
            meal_plan_data['ingredients'] = data.get('ingredients', [])
        
        _, new_plan_ref = db.collection('MealPlan').add(meal_plan_data)
        
        created_plan = new_plan_ref.get().to_dict()
        serialized = _serialize_meal_plan(created_plan, new_plan_ref.id, db)
        
        return success_response({
            'message': 'Meal plan created successfully',
            'meal_plan': serialized
        }, 201)
        
    except Exception as e:
        logger.error(f"Error creating meal plan: {e}")
        return error_response('Failed to create meal plan', 500)

@meal_plans_bp.route('/', methods=['GET'])
def get_meal_plans():
    """Get meal plans for the authenticated user with optional date filtering"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        # Get query parameters
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        query = db.collection('MealPlan').where(filter=FieldFilter('userId', '==', user_id))
        
        # Apply date filters if provided
        if start_date:
            query = query.where(filter=FieldFilter('planDate', '>=', start_date))
        if end_date:
            query = query.where(filter=FieldFilter('planDate', '<=', end_date))
        
        docs = query.stream()
        
        meal_plans = []
        for doc in docs:
            plan = doc.to_dict()
            serialized = _serialize_meal_plan(plan, doc.id, db)
            meal_plans.append(serialized)
        
        # Sort by date and meal type
        meal_type_order = {'breakfast': 0, 'lunch': 1, 'dinner': 2, 'snack': 3}
        meal_plans.sort(key=lambda x: (x['planDate'], meal_type_order.get(x['mealType'], 4)))
        
        return success_response({'meal_plans': meal_plans})
        
    except Exception as e:
        logger.error(f"Error getting meal plans: {e}")
        return error_response('Failed to get meal plans', 500)


@meal_plans_bp.route('/week', methods=['GET'])
def get_week_meal_plans():
    """Get meal plans for a week starting from the given date"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        # Get start date (default to today)
        start_date_str = request.args.get('start_date')
        if start_date_str:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
        else:
            start_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        
        end_date = start_date + timedelta(days=6)
        start_str = start_date.strftime('%Y-%m-%d')
        end_str = end_date.strftime('%Y-%m-%d')
        
        # Query only by userId to avoid composite index requirement
        # Then filter dates in Python
        query = db.collection('MealPlan').where(
            filter=FieldFilter('userId', '==', user_id)
        )
        
        docs = query.stream()
        
        # Organize by date
        week_plans = {}
        for i in range(7):
            date_str = (start_date + timedelta(days=i)).strftime('%Y-%m-%d')
            week_plans[date_str] = {
                'breakfast': [],
                'lunch': [],
                'dinner': [],
                'snack': []
            }
        
        for doc in docs:
            plan = doc.to_dict()
            plan_date = plan.get('planDate', '')
            
            # Filter by date range in Python to avoid composite index
            if plan_date and start_str <= plan_date <= end_str:
                serialized = _serialize_meal_plan(plan, doc.id, db)
                date = serialized['planDate']
                meal_type = serialized['mealType']
                if date in week_plans and meal_type in week_plans[date]:
                    week_plans[date][meal_type].append(serialized)
        
        return success_response({
            'week_plans': week_plans,
            'start_date': start_str,
            'end_date': end_str
        })
        
    except Exception as e:
        logger.error(f"Error getting week meal plans: {e}", exc_info=True)
        return error_response('Failed to get week meal plans', 500)


@meal_plans_bp.route('/generate-grocery', methods=['POST'])
def generate_grocery_from_plans():
    """Generate a grocery list from meal plans for a date range"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        start_date = data.get('start_date')
        end_date = data.get('end_date')
        
        if not start_date or not end_date:
            return error_response('start_date and end_date are required', 400)
        
        # Query only by userId to avoid composite index requirement
        query = db.collection('MealPlan').where(
            filter=FieldFilter('userId', '==', user_id)
        )
        
        docs = query.stream()
        
        # Aggregate ingredients - filter by date in Python
        grocery_items = {}
        for doc in docs:
            plan = doc.to_dict()
            plan_date = plan.get('planDate', '')
            
            # Filter by date range in Python
            if not (start_date <= plan_date <= end_date):
                continue
                
            servings = plan.get('servings', 1)
            
            # Get ingredients from recipe or inline
            ingredients = []
            recipe_ref = plan.get('recipe')
            if recipe_ref and hasattr(recipe_ref, 'get'):
                recipe_doc = recipe_ref.get()
                if recipe_doc.exists:
                    ingredients = recipe_doc.to_dict().get('ingredients', [])
            else:
                ingredients = plan.get('ingredients', [])
            
            for ing in ingredients:
                name = ing.get('name', ing.get('ingredient', {}).get('name', ''))
                if not name:
                    continue
                    
                quantity = ing.get('quantity', 1) * servings
                unit = ing.get('unit', 'pcs')
                category = ing.get('category', 'Other')
                
                key = f"{name.lower()}_{unit}"
                if key in grocery_items:
                    grocery_items[key]['quantity'] += quantity
                else:
                    grocery_items[key] = {
                        'name': name,
                        'quantity': quantity,
                        'unit': unit,
                        'category': category,
                        'purchased': False
                    }
        
        # Check fridge for items we already have
        fridge_query = db.collection('Fridge').where(
            filter=FieldFilter('userId', '==', user_id)
        )
        fridge_docs = fridge_query.stream()
        
        fridge_items = {}
        for doc in fridge_docs:
            item = doc.to_dict()
            name = item.get('name', '').lower()
            fridge_items[name] = item.get('quantity', 0)
        
        # Subtract fridge items
        final_grocery = []
        for key, item in grocery_items.items():
            name_lower = item['name'].lower()
            if name_lower in fridge_items:
                item['quantity'] -= fridge_items[name_lower]
                item['inFridge'] = fridge_items[name_lower]
            
            if item['quantity'] > 0:
                final_grocery.append(item)
        
        # Group by category
        grouped = {}
        for item in final_grocery:
            cat = item['category']
            if cat not in grouped:
                grouped[cat] = []
            grouped[cat].append(item)
        
        return success_response({
            'grocery_items': final_grocery,
            'grouped_by_category': grouped,
            'total_items': len(final_grocery)
        })
        
    except Exception as e:
        logger.error(f"Error generating grocery list: {e}")
        return error_response('Failed to generate grocery list', 500)


@meal_plans_bp.route('/<plan_id>', methods=['DELETE'])
def delete_meal_plan(plan_id):
    """Delete a meal plan"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        plan_ref = db.collection('MealPlan').document(plan_id)
        plan_doc = plan_ref.get()
        
        if not plan_doc.exists:
            return error_response('Meal plan not found', 404)
        
        plan_data = plan_doc.to_dict()
        if plan_data.get('userId') != user_id:
            return error_response('Not authorized', 403)

        plan_ref.delete()
        
        return success_response({'message': 'Meal plan deleted successfully'})
        
    except Exception as e:
        logger.error(f"Error deleting meal plan: {e}")
        return error_response('Failed to delete meal plan', 500)


@meal_plans_bp.route('/ai-suggest', methods=['POST'])
def ai_suggest_meals():
    """Get AI suggestions for meal planning based on preferences and fridge"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json() or {}
        
        # Get user's nutrition goals
        user_ref = db.collection('User').document(user_id)
        user_doc = user_ref.get()
        user_data = user_doc.to_dict() if user_doc.exists else {}
        
        nutrition_goals = user_data.get('nutritionGoals', {
            'calories': 2000,
            'protein': 50,
            'carbs': 250,
            'fat': 65
        })
        
        # Get fridge items
        fridge_query = db.collection('FridgeItem').where(filter=FieldFilter('userId', '==', user_id)).limit(30)
        fridge_docs = fridge_query.stream()
        fridge_items = [doc.to_dict().get('ingredientName', '') for doc in fridge_docs if doc.to_dict().get('ingredientName')]
        
        # Get dietary preferences
        preferences = data.get('preferences', user_data.get('dietaryPreferences', []))
        meal_type = data.get('mealType', 'dinner')
        
        # Use AI to generate suggestions
        from services.ai_service import AIRecipeGenerator
        
        try:
            ai_generator = AIRecipeGenerator()
        except Exception as e:
            logger.error(f"Failed to initialize AI service: {e}")
            # Fallback to simple suggestions if AI unavailable
            suggestions = _generate_meal_suggestions(
                fridge_items=fridge_items,
                preferences=preferences,
                meal_type=meal_type,
                nutrition_goals=nutrition_goals
            )
            return success_response({
                'suggestions': suggestions,
                'based_on_fridge': fridge_items[:5],
                'preferences': preferences,
                'ai_powered': False
            })
        
        # Build AI prompt for multiple suggestions
        prompt_parts = []
        prompt_parts.append("You are a creative chef AI assistant.")
        prompt_parts.append(f"Generate 3 {meal_type} meal suggestions.")
        
        if fridge_items:
            prompt_parts.append(f"Available ingredients in fridge: {', '.join(fridge_items[:15])}")
            prompt_parts.append("Prioritize using these ingredients when possible.")
        
        if preferences:
            prompt_parts.append(f"Dietary preferences: {', '.join(preferences)}")
        
        prompt_parts.append(f"Target nutrition: ~{nutrition_goals.get('calories', 2000)//3} calories per meal")
        
        prompt_parts.append("\nReturn ONLY valid JSON array with 3 meal suggestions:")
        prompt_parts.append("""[
  {
    "name": "Meal Name",
    "description": "Brief description",
    "calories": 400,
    "prepTime": 20,
    "ingredients": ["ingredient1", "ingredient2"],
    "difficulty": "easy"
  }
]""")
        
        context_prompt = "\n".join(prompt_parts)
        
        try:
            import json
            response = ai_generator.model.generate_content(
                context_prompt,
                generation_config={
                    'temperature': 0.8,
                    'max_output_tokens': 1024,
                }
            )
            
            # Parse response
            response_text = response.text.strip()
            if response_text.startswith('```'):
                response_text = response_text.split('\n', 1)[1] if '\n' in response_text else response_text[3:]
                if response_text.endswith('```'):
                    response_text = response_text[:-3]
                response_text = response_text.strip()
            
            suggestions = json.loads(response_text)
            
            # Add fridge match info
            fridge_lower = [item.lower() for item in fridge_items]
            for suggestion in suggestions:
                ingredients = suggestion.get('ingredients', [])
                matches = sum(1 for ing in ingredients if any(ing.lower() in f for f in fridge_lower))
                suggestion['fridgeMatch'] = matches
                suggestion['matchPercentage'] = int((matches / len(ingredients)) * 100) if ingredients else 0
            
            logger.info(f"Generated {len(suggestions)} AI meal suggestions for {meal_type}")
            
        except Exception as e:
            logger.error(f"AI generation failed: {e}, using fallback")
            suggestions = _generate_meal_suggestions(
                fridge_items=fridge_items,
                preferences=preferences,
                meal_type=meal_type,
                nutrition_goals=nutrition_goals
            )
            return success_response({
                'suggestions': suggestions,
                'based_on_fridge': fridge_items[:5],
                'preferences': preferences,
                'ai_powered': False
            })
        
        return success_response({
            'suggestions': suggestions,
            'based_on_fridge': fridge_items[:5],
            'preferences': preferences,
            'ai_powered': True
        })
        
    except Exception as e:
        logger.error(f"Error getting AI suggestions: {e}")
        return error_response('Failed to get meal suggestions', 500)


def _generate_meal_suggestions(fridge_items, preferences, meal_type, nutrition_goals):
    """Generate meal suggestions based on available ingredients"""
    # This is a simple implementation - in production, you'd use an AI service
    base_suggestions = {
        'breakfast': [
            {'name': 'Oatmeal with Fruits', 'calories': 350, 'prepTime': 15, 'ingredients': ['oats', 'milk', 'banana', 'honey']},
            {'name': 'Scrambled Eggs', 'calories': 280, 'prepTime': 10, 'ingredients': ['eggs', 'butter', 'salt', 'pepper']},
            {'name': 'Greek Yogurt Parfait', 'calories': 300, 'prepTime': 5, 'ingredients': ['yogurt', 'granola', 'berries']},
        ],
        'lunch': [
            {'name': 'Chicken Salad', 'calories': 450, 'prepTime': 20, 'ingredients': ['chicken', 'lettuce', 'tomato', 'cucumber']},
            {'name': 'Vegetable Wrap', 'calories': 380, 'prepTime': 15, 'ingredients': ['tortilla', 'vegetables', 'hummus']},
            {'name': 'Pasta Primavera', 'calories': 520, 'prepTime': 25, 'ingredients': ['pasta', 'vegetables', 'olive oil', 'parmesan']},
        ],
        'dinner': [
            {'name': 'Grilled Salmon', 'calories': 480, 'prepTime': 30, 'ingredients': ['salmon', 'lemon', 'herbs', 'vegetables']},
            {'name': 'Stir Fry Vegetables', 'calories': 350, 'prepTime': 20, 'ingredients': ['tofu', 'vegetables', 'soy sauce', 'rice']},
            {'name': 'Chicken Curry', 'calories': 550, 'prepTime': 35, 'ingredients': ['chicken', 'curry', 'coconut milk', 'rice']},
        ],
        'snack': [
            {'name': 'Apple with Peanut Butter', 'calories': 200, 'prepTime': 2, 'ingredients': ['apple', 'peanut butter']},
            {'name': 'Trail Mix', 'calories': 180, 'prepTime': 0, 'ingredients': ['nuts', 'dried fruits']},
            {'name': 'Cheese and Crackers', 'calories': 220, 'prepTime': 2, 'ingredients': ['cheese', 'crackers']},
        ]
    }
    
    suggestions = base_suggestions.get(meal_type, base_suggestions['dinner'])
    
    # Score suggestions based on fridge items
    fridge_lower = [item.lower() for item in fridge_items]
    for suggestion in suggestions:
        matches = sum(1 for ing in suggestion['ingredients'] if any(ing.lower() in f for f in fridge_lower))
        suggestion['fridgeMatch'] = matches
        suggestion['matchPercentage'] = int((matches / len(suggestion['ingredients'])) * 100) if suggestion['ingredients'] else 0
    
    # Sort by match percentage
    suggestions.sort(key=lambda x: x['matchPercentage'], reverse=True)
    
    return suggestions