from flask import Blueprint, request
from google.cloud.firestore_v1.base_query import FieldFilter
from utils.firebase_connector import get_db
from utils.auth import require_current_user
from utils.response_handler import success_response, error_response
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
fridge_bp = Blueprint('fridge', __name__)

@fridge_bp.route('/items', methods=['GET'])
def get_fridge_items():
    """Get all items in user's fridge"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        logger.info(f"📋 Getting fridge items for user: {user_id}")

        # Start with a base query for the user's items using simple userId field
        query = db.collection('FridgeItem').where(filter=FieldFilter('userId', '==', user_id))

        # Get query parameters
        search = request.args.get('search', '')
        freshness = request.args.get('freshness', 'all')

        if search:
            # For search, we'll filter client-side since Firestore has limitations
            pass

        docs = query.stream()
        
        items = []
        for doc in docs:
            item = doc.to_dict()
            item['id'] = doc.id
            
            # Normalize field names for frontend compatibility
            if 'ingredientName' in item:
                item['name'] = item['ingredientName']
            if 'expirationDate' in item:
                item['expiryDate'] = item['expirationDate']
            
            # Apply search filter client-side
            if search:
                ingredient_name = item.get('ingredientName', '').lower()
                if search.lower() not in ingredient_name:
                    continue
            
            items.append(item)
            
        # Filter by freshness if specified
        if freshness != 'all':
            filtered_items = []
            today = datetime.now().date()
            
            for item in items:
                if 'expirationDate' in item:
                    try:
                        expiry_date = datetime.strptime(item['expirationDate'], '%Y-%m-%d').date()
                        days_until_expiry = (expiry_date - today).days
                        
                        if freshness == 'fresh' and days_until_expiry > 2:
                            filtered_items.append(item)
                        elif freshness == 'expiring-soon' and 0 <= days_until_expiry <= 2:
                            filtered_items.append(item)
                        elif freshness == 'expired' and days_until_expiry < 0:
                            filtered_items.append(item)
                    except (ValueError, TypeError):
                        continue # Skip items with invalid date format
            items = filtered_items

        logger.info(f"✅ Returning {len(items)} fridge items for user {user_id}")
        
        return success_response({
            'items': items,
            'total': len(items)
        })
        
    except Exception as e:
        logger.error(f"Error getting fridge items: {e}")
        return error_response(str(e), 500)

@fridge_bp.route('/items', methods=['POST'])  
def add_fridge_item():
    """Add a new item to the fridge"""
    try:
        user_id = require_current_user()
        db = get_db()

        data = request.get_json() or {}

        if not data:
            return error_response('No data provided', 400)
        
        # Support both simple name and full ingredient object
        ingredient_name = None
        if 'name' in data:
            ingredient_name = data['name']
        elif 'ingredientName' in data:
            ingredient_name = data['ingredientName']
        elif 'ingredient' in data:
            if isinstance(data['ingredient'], str):
                ingredient_name = data['ingredient']
            elif isinstance(data['ingredient'], dict) and 'name' in data['ingredient']:
                ingredient_name = data['ingredient']['name']
        
        if not ingredient_name:
            return error_response('Missing ingredient name', 400)
        
        required_fields = ['quantity', 'unit']
        for field in required_fields:
            if field not in data or not data[field]:
                return error_response(f'Missing required field: {field}', 400)
        
        # Store ingredient as simple object with name
        new_item = {
            'userId': user_id,  # Store as simple string for easier querying
            'ingredientName': ingredient_name,
            'quantity': float(data['quantity']),
            'unit': data['unit'],
            'category': data.get('category', 'other'),
            'location': data.get('location', 'Main fridge'),
            'notes': data.get('notes', ''),
            'addedAt': datetime.utcnow(),
            'expirationDate': data.get('expirationDate')  # Should be in 'YYYY-MM-DD' format
        }
        
        _, new_item_ref = db.collection('FridgeItem').add(new_item)
        
        created_item = new_item_ref.get().to_dict()
        created_item['id'] = new_item_ref.id

        return success_response({
            'item': created_item,
            'message': 'Item added to fridge'
        }, 201)
        
    except Exception as e:
        logger.error(f"Error adding fridge item: {e}")
        return error_response(str(e), 500)

@fridge_bp.route('/items/<item_id>', methods=['PUT'])
def update_fridge_item(item_id):
    """Update an existing fridge item"""
    try:
        user_id = require_current_user()
        db = get_db()

        data = request.get_json() or {}
        if not data:
            return error_response('No data provided', 400)
        
        item_ref = db.collection('FridgeItem').document(item_id)
        
        # Verify the item belongs to the user
        item_doc = item_ref.get()
        if not item_doc.exists:
            return error_response('Item not found', 404)
        
        item_data = item_doc.to_dict()
        if item_data.get('userId') != user_id:
            return error_response('Item not found', 404)

        update_data = {}
        allowed_fields = ['quantity', 'unit', 'expirationDate', 'category', 'location', 'notes']
        for field in allowed_fields:
            if field in data:
                update_data[field] = data[field]
        
        if update_data:
            update_data['updatedAt'] = datetime.utcnow()
            item_ref.update(update_data)
        
        updated_item = item_ref.get().to_dict()
        updated_item['id'] = item_ref.id
        
        return success_response({
            'item': updated_item,
            'message': 'Item updated successfully'
        })
        
    except Exception as e:
        logger.error(f"Error updating fridge item: {e}")
        return error_response(str(e), 500)

@fridge_bp.route('/items/<item_id>', methods=['DELETE'])
def delete_fridge_item(item_id):
    """Delete a fridge item"""
    try:
        user_id = require_current_user()
        db = get_db()

        item_ref = db.collection('FridgeItem').document(item_id)

        # Verify the item belongs to the user
        item_doc = item_ref.get()
        if not item_doc.exists:
            return error_response('Item not found', 404)
        
        item_data = item_doc.to_dict()
        if item_data.get('userId') != user_id:
            return error_response('Item not found', 404)
        
        item_ref.delete()
        
        return success_response({'message': 'Item removed from fridge'})
        
    except Exception as e:
        logger.error(f"Error deleting fridge item: {e}")
        return error_response(str(e), 500)

@fridge_bp.route('/consume-ingredients', methods=['POST'])
def consume_ingredients():
    """
    Remove or reduce ingredients from fridge when user cooks a recipe
    
    Request body:
    {
        "ingredients": [
            {"name": "chicken", "quantity": 500, "unit": "g"},
            {"name": "tomatoes", "quantity": 3, "unit": "pieces"}
        ]
    }
    """
    try:
        user_id = require_current_user()
        db = get_db()
        
        data = request.get_json() or {}
        ingredients_to_consume = data.get('ingredients', [])
        
        if not ingredients_to_consume:
            return error_response('No ingredients provided', 400)
        
        logger.info(f"🍳 Consuming ingredients for user {user_id}: {ingredients_to_consume}")
        
        # Get all fridge items for the user
        query = db.collection('FridgeItem').where(filter=FieldFilter('userId', '==', user_id))
        docs = list(query.stream())
        
        consumed = []
        not_found = []
        
        for ingredient in ingredients_to_consume:
            ingredient_name = ingredient.get('name', '').lower()
            
            # Find matching fridge item
            found = False
            for doc in docs:
                item = doc.to_dict()
                fridge_item_name = item.get('ingredientName', '').lower()
                
                # Check if names match (partial match)
                if ingredient_name in fridge_item_name or fridge_item_name in ingredient_name:
                    # Delete the item from fridge
                    doc.reference.delete()
                    consumed.append({
                        'name': item.get('ingredientName'),
                        'id': doc.id
                    })
                    found = True
                    logger.info(f"✅ Consumed: {item.get('ingredientName')}")
                    break
            
            if not found:
                not_found.append(ingredient_name)
        
        return success_response({
            'consumed': consumed,
            'not_found': not_found,
            'message': f'Consumed {len(consumed)} ingredients from fridge'
        })
        
    except Exception as e:
        logger.error(f"Error consuming ingredients: {e}")
        return error_response(str(e), 500)


@fridge_bp.route('/suggest-recipes', methods=['POST'])
def suggest_recipes_from_fridge():
    """
    Suggest recipes based on ingredients in user's fridge
    Uses AI service to generate recipe recommendations
    """
    try:
        user_id = require_current_user()
        db = get_db()
        
        logger.info(f"🔍 Suggesting recipes for user: {user_id}")
        
        # Get all fridge items for the user
        query = db.collection('FridgeItem').where(filter=FieldFilter('userId', '==', user_id))
        docs = query.stream()
        
        fridge_items = []
        ingredients_list = []
        
        for doc in docs:
            item = doc.to_dict()
            item['id'] = doc.id
            fridge_items.append(item)
            ingredient_name = item.get('ingredientName', '')
            if ingredient_name:
                ingredients_list.append(ingredient_name)
        
        logger.info(f"📦 Found {len(fridge_items)} fridge items for user {user_id}")
        logger.info(f"🥗 Extracted ingredients: {ingredients_list}")
        
        if not ingredients_list:
            logger.warning(f"⚠️ No ingredients found for user {user_id} in Firestore")
            return error_response('No ingredients in fridge. Add some ingredients first!', 400)
        
        # Get optional filters from request
        data = request.get_json() or {}
        dietary_preferences = data.get('dietary_preferences', [])
        max_cooking_time = data.get('max_cooking_time')
        difficulty = data.get('difficulty', 'medium')
        servings = data.get('servings', 4)
        
        # Import AI services
        from services.ai_service import AIRecipeGenerator
        
        # Initialize AI service
        try:
            ai_generator = AIRecipeGenerator()
        except Exception as e:
            logger.error(f"Failed to initialize AI service: {e}")
            return error_response('AI service not available. Check GEMINI_API_KEY configuration.', 503)
        
        # Build user query
        user_query = f"Create a delicious recipe using these ingredients: {', '.join(ingredients_list)}"
        
        # Build requirements
        user_requirements = {
            'ingredients': ingredients_list,
            'dietary_preferences': dietary_preferences,
            'max_cooking_time': max_cooking_time,
            'difficulty': difficulty,
            'servings': servings
        }
        
        # Build prompt
        prompt_parts = []
        prompt_parts.append("You are a creative chef AI assistant.")
        prompt_parts.append(f"Create an original recipe using these ingredients from the user's fridge:")
        prompt_parts.append(f"Available ingredients: {', '.join(ingredients_list)}")
        
        if dietary_preferences:
            prompt_parts.append(f"Dietary preferences: {', '.join(dietary_preferences)}")
        if max_cooking_time:
            prompt_parts.append(f"Maximum cooking time: {max_cooking_time} minutes")
        prompt_parts.append(f"Difficulty: {difficulty}")
        prompt_parts.append(f"Servings: {servings}")
        
        prompt_parts.append("\nGuidelines:")
        prompt_parts.append("- Use as many of the fridge ingredients as possible")
        prompt_parts.append("- Create a practical, delicious recipe")
        prompt_parts.append("- Provide clear instructions")
        prompt_parts.append("- Include nutrition information")
        
        context_prompt = "\n".join(prompt_parts)
        
        # Generate recipe with AI
        generated_recipe = ai_generator.generate_recipe(
            context_prompt=context_prompt,
            temperature=0.8  # Balanced creativity
        )
        
        # Add metadata
        generated_recipe['createdAt'] = datetime.utcnow()
        generated_recipe['generatedByAI'] = True
        generated_recipe['basedOnFridge'] = True
        generated_recipe['fridgeIngredients'] = ingredients_list
        
        # Save to database
        _, recipe_ref = db.collection('Recipe').add(generated_recipe)
        generated_recipe['id'] = recipe_ref.id
        
        logger.info(f"Generated recipe from fridge for user {user_id}: {recipe_ref.id}")
        
        return success_response({
            'recipe': generated_recipe,
            'ingredients_used': ingredients_list,
            'message': 'Recipe suggested successfully based on your fridge!'
        }, 201)
        
    except Exception as e:
        logger.error(f"Error suggesting recipes from fridge: {e}")
        import traceback
        traceback.print_exc()
        return error_response(f'Failed to suggest recipes: {str(e)}', 500)