from flask import Blueprint, request, jsonify
from google.cloud.firestore_v1.base_query import FieldFilter
from utils.firebase_connector import get_db
from utils.response_handler import success_response, error_response
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
recipes_bp = Blueprint('recipes', __name__)

@recipes_bp.route('/search', methods=['GET'])
def search_recipes():
    """
    Search recipes by various criteria
    
    Note: Firestore has limitations:
    - Only ONE inequality/range filter per query
    - Composite indexes required for multiple filters
    - No native full-text search
    """
    try:
        db = get_db()
        
        # Get query parameters
        query_text = request.args.get('q', '')
        
        # Handle dietary_tags as both list and comma-separated string
        dietary_tags = request.args.getlist('dietary_tags')
        if not dietary_tags:
            dietary_tags_str = request.args.get('dietary_tags', '')
            if dietary_tags_str:
                dietary_tags = [tag.strip() for tag in dietary_tags_str.split(',') if tag.strip()]
        
        cuisine_type = request.args.get('cuisine_type', '')
        max_cooking_time = request.args.get('max_cooking_time', type=int)
        difficulty = request.args.get('difficulty', '')
        sort_by = request.args.get('sort_by', 'rating')
        page = max(1, request.args.get('page', 1, type=int))
        per_page = min(50, request.args.get('per_page', 20, type=int))

        # Start with base query
        query = db.collection('Recipe')
        
        # Track if we have an inequality filter
        has_inequality_filter = False
        
        # Strategy: Apply filters in order of importance
        # Priority: equality filters first, then ONE inequality filter
        
        # 1. Equality filters (can combine multiple)
        if difficulty:
            query = query.where(filter=FieldFilter('difficulty', '==', difficulty))
            logger.info(f"Applied difficulty filter: {difficulty}")
        
        if cuisine_type:
            query = query.where(filter=FieldFilter('cuisine', '==', cuisine_type))
            logger.info(f"Applied cuisine filter: {cuisine_type}")
        
        # 2. Array-contains filter (special case)
        if dietary_tags:
            # Use array-contains-any for dietary preferences
            query = query.where(filter=FieldFilter('dietaryPreferences', 'array-contains-any', dietary_tags))
            logger.info(f"Applied dietary filter: {dietary_tags}")
        
        # 3. Apply ONE inequality filter if needed
        if max_cooking_time and not has_inequality_filter:
            query = query.where(filter=FieldFilter('cookTimeMinutes', '<=', max_cooking_time))
            has_inequality_filter = True
            logger.info(f"Applied cooking time filter: <= {max_cooking_time}")
        
        # 4. Apply sorting
        # If we have an inequality filter, we must order by that field first
        if has_inequality_filter and max_cooking_time:
            query = query.order_by('cookTimeMinutes', direction='ASCENDING')
            # Can add secondary sort if needed
            if sort_by == 'rating':
                query = query.order_by('rating', direction='DESCENDING')
        elif sort_by == 'rating':
            query = query.order_by('rating', direction='DESCENDING')
        elif sort_by == 'cooking_time':
            query = query.order_by('cookTimeMinutes', direction='ASCENDING')
        else:
            # Default sorting by document name (ID)
            query = query.order_by('__name__', direction='ASCENDING')
        
        # 5. Apply pagination
        # Skip documents for pagination (not efficient for large datasets)
        offset = (page - 1) * per_page
        query = query.limit(per_page)
        
        # Execute query
        docs = query.stream()
        
        recipes = []
        for doc in docs:
            recipe = doc.to_dict()
            recipe['id'] = doc.id
            
            # Client-side filtering for text search (if needed)
            if query_text:
                title_lower = recipe.get('title', '').lower()
                desc_lower = recipe.get('description', '').lower()
                if query_text.lower() not in title_lower and query_text.lower() not in desc_lower:
                    continue
            
            recipes.append(recipe)
        
        logger.info(f"Found {len(recipes)} recipes matching criteria")
        
        return success_response({
            'recipes': recipes,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'count': len(recipes)
            },
            'applied_filters': {
                'difficulty': difficulty if difficulty else None,
                'cuisine': cuisine_type if cuisine_type else None,
                'dietary_tags': dietary_tags if dietary_tags else None,
                'max_cooking_time': max_cooking_time if max_cooking_time else None,
                'text_search': query_text if query_text else None
            }
        })
        
    except Exception as e:
        logger.error(f"Error searching recipes: {e}", exc_info=True)
        
        # Provide helpful error message for index issues
        error_message = str(e)
        if 'index' in error_message.lower() and 'console.firebase.google.com' in error_message:
            return error_response(
                'This query requires a Firestore index. Please create the index using the link in the server logs, '
                'or simplify your search by using fewer filters.',
                400
            )
        
        return error_response('Failed to search recipes', 500)

@recipes_bp.route('/<recipe_id>', methods=['GET'])
def get_recipe(recipe_id):
    """Get a specific recipe by ID"""
    try:
        db = get_db()
        recipe_ref = db.collection('Recipe').document(recipe_id)
        recipe = recipe_ref.get()
        
        if not recipe.exists:
            return error_response('Recipe not found', 404)
        
        recipe_data = recipe.to_dict()
        recipe_data['id'] = recipe.id
        
        return success_response({'recipe': recipe_data})
        
    except Exception as e:
        logger.error(f"Error getting recipe: {e}")
        return error_response('Failed to get recipe', 500)

@recipes_bp.route('/', methods=['POST'])
def create_recipe():
    """Create a new recipe"""
    try:
        data = request.get_json()
        db = get_db()
        
        # Validate required fields from schema.gql
        required_fields = ['title', 'instructions', 'servingSize', 'prepTimeMinutes', 'cookTimeMinutes']
        for field in required_fields:
            if field not in data:
                return error_response(f'Missing required field: {field}', 400)
        
        data['createdAt'] = datetime.utcnow()
        
        # Add a new doc with a generated id.
        new_recipe_ref = db.collection('Recipe').add(data)[1]
        
        created_recipe = new_recipe_ref.get().to_dict()
        created_recipe['id'] = new_recipe_ref.id

        return success_response({
            'message': 'Recipe created successfully',
            'recipe': created_recipe
        }, 201)
        
    except Exception as e:
        logger.error(f"Error creating recipe: {e}")
        return error_response('Failed to create recipe', 500)

@recipes_bp.route('/<recipe_id>', methods=['PUT'])
def update_recipe(recipe_id):
    """Update an existing recipe"""
    try:
        data = request.get_json()
        if not data:
            return error_response('No data provided', 400)
        
        db = get_db()
        recipe_ref = db.collection('Recipe').document(recipe_id)

        if not recipe_ref.get().exists:
            return error_response('Recipe not found', 404)

        data['updatedAt'] = datetime.utcnow()
        recipe_ref.update(data)
        
        updated_recipe = recipe_ref.get().to_dict()
        updated_recipe['id'] = recipe_ref.id
        
        return success_response({
            'message': 'Recipe updated successfully',
            'recipe': updated_recipe
        })
        
    except Exception as e:
        logger.error(f"Error updating recipe: {e}")
        return error_response('Failed to update recipe', 500)

@recipes_bp.route('/<recipe_id>', methods=['DELETE'])
def delete_recipe(recipe_id):
    """Delete a recipe"""
    try:
        db = get_db()
        recipe_ref = db.collection('Recipe').document(recipe_id)

        if not recipe_ref.get().exists:
            return error_response('Recipe not found', 404)

        recipe_ref.delete()
        
        return success_response({'message': 'Recipe deleted successfully'})
        
    except Exception as e:
        logger.error(f"Error deleting recipe: {e}")
        return error_response('Failed to delete recipe', 500)

@recipes_bp.route('/categories', methods=['GET'])
def get_categories():
    """Get available recipe categories and filters"""
    try:
        # This is a simplified version. In a real app, you might want to
        # maintain a separate collection for categories or use a more
        # efficient way to get distinct values.
        
        # Get difficulty levels
        difficulties = ['easy', 'medium', 'hard']
        
        # Get cooking time ranges
        cooking_time_ranges = [
            {'label': 'Quick (< 15 min)', 'max': 15},
            {'label': 'Medium (15-30 min)', 'min': 15, 'max': 30},
            {'label': 'Long (30-60 min)', 'min': 30, 'max': 60},
            {'label': 'Extended (> 60 min)', 'min': 60}
        ]
        
        # For dietary tags and cuisine types, you could query all recipes
        # and aggregate, but that's inefficient. For now, returning static lists.
        dietary_tags = ["vegan", "gluten-free", "healthy", "vegetarian", "mediterranean", "high-protein", "keto", "low-carb"]
        cuisine_types = ["international", "mediterranean", "american"]

        return success_response({
            'dietary_tags': sorted(dietary_tags),
            'cuisine_types': sorted(cuisine_types),
            'difficulties': difficulties,
            'cooking_time_ranges': cooking_time_ranges
        })
        
    except Exception as e:
        logger.error(f"Error getting categories: {e}")
        return error_response('Failed to get categories', 500)