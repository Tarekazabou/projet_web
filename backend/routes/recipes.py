from flask import Blueprint, request, jsonify
from utils.firebase_connector import get_db
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
recipes_bp = Blueprint('recipes', __name__)

@recipes_bp.route('/search', methods=['GET'])
def search_recipes():
    """Search recipes by various criteria"""
    try:
        db = get_db()
        
        # Get query parameters
        query_text = request.args.get('q', '')
        dietary_tags = request.args.getlist('dietary_tags')
        cuisine_type = request.args.get('cuisine_type', '')
        max_cooking_time = request.args.get('max_cooking_time', type=int)
        difficulty = request.args.get('difficulty', '')
        sort_by = request.args.get('sort_by', 'rating')
        page = max(1, request.args.get('page', 1, type=int))
        per_page = min(50, request.args.get('per_page', 20, type=int))

        # Start with a base query
        query = db.collection('Recipe')

        # Apply filters
        if query_text:
            # Firestore doesn't support full-text search natively.
            # This is a simplified example. For real full-text search,
            # you would use a third-party service like Algolia or Elasticsearch.
            # Here we just filter by title.
            query = query.where('title', '>=', query_text).where('title', '<=', query_text + '\uf8ff')

        if dietary_tags:
            query = query.where('dietaryPreferences', 'array_contains_any', dietary_tags)
        
        if cuisine_type:
            query = query.where('cuisine', '==', cuisine_type)

        if max_cooking_time:
            query = query.where('cookTimeMinutes', '<=', max_cooking_time)

        if difficulty:
            query = query.where('difficulty', '==', difficulty)

        # Sorting
        if sort_by == 'rating':
            # Assuming 'rating' field exists
            query = query.order_by('rating', direction='DESCENDING')
        elif sort_by == 'cooking_time':
            query = query.order_by('cookTimeMinutes', direction='ASCENDING')
        
        # Pagination
        # For Firestore, you'd typically use cursors (start_after) for pagination.
        # A simple offset-based pagination is less efficient but easier for a quick migration.
        offset = (page - 1) * per_page
        docs = query.limit(per_page).offset(offset).stream()

        recipes = []
        for doc in docs:
            recipe = doc.to_dict()
            recipe['id'] = doc.id
            recipes.append(recipe)

        # For total count, you'd need a separate query, which can be costly.
        # For simplicity, we'll just return the count of the current page.
        
        return jsonify({
            'recipes': recipes,
            'pagination': {
                'page': page,
                'per_page': per_page,
                # 'total_count': total_count, # This would require another query
                # 'total_pages': (total_count + per_page - 1) // per_page
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error searching recipes: {e}")
        return jsonify({'error': 'Failed to search recipes'}), 500

@recipes_bp.route('/<recipe_id>', methods=['GET'])
def get_recipe(recipe_id):
    """Get a specific recipe by ID"""
    try:
        db = get_db()
        recipe_ref = db.collection('Recipe').document(recipe_id)
        recipe = recipe_ref.get()
        
        if not recipe.exists:
            return jsonify({'error': 'Recipe not found'}), 404
        
        recipe_data = recipe.to_dict()
        recipe_data['id'] = recipe.id
        
        return jsonify({
            'recipe': recipe_data,
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting recipe: {e}")
        return jsonify({'error': 'Failed to get recipe'}), 500

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
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        data['createdAt'] = datetime.utcnow()
        
        # Add a new doc with a generated id.
        new_recipe_ref = db.collection('Recipe').add(data)[1]
        
        created_recipe = new_recipe_ref.get().to_dict()
        created_recipe['id'] = new_recipe_ref.id

        return jsonify({
            'message': 'Recipe created successfully',
            'recipe': created_recipe
        }), 201
        
    except Exception as e:
        logger.error(f"Error creating recipe: {e}")
        return jsonify({'error': 'Failed to create recipe'}), 500

@recipes_bp.route('/<recipe_id>', methods=['PUT'])
def update_recipe(recipe_id):
    """Update an existing recipe"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        db = get_db()
        recipe_ref = db.collection('Recipe').document(recipe_id)

        if not recipe_ref.get().exists:
            return jsonify({'error': 'Recipe not found'}), 404

        data['updatedAt'] = datetime.utcnow()
        recipe_ref.update(data)
        
        updated_recipe = recipe_ref.get().to_dict()
        updated_recipe['id'] = recipe_ref.id
        
        return jsonify({
            'message': 'Recipe updated successfully',
            'recipe': updated_recipe
        }), 200
        
    except Exception as e:
        logger.error(f"Error updating recipe: {e}")
        return jsonify({'error': 'Failed to update recipe'}), 500

@recipes_bp.route('/<recipe_id>', methods=['DELETE'])
def delete_recipe(recipe_id):
    """Delete a recipe"""
    try:
        db = get_db()
        recipe_ref = db.collection('Recipe').document(recipe_id)

        if not recipe_ref.get().exists:
            return jsonify({'error': 'Recipe not found'}), 404

        recipe_ref.delete()
        
        return jsonify({'message': 'Recipe deleted successfully'}), 200
        
    except Exception as e:
        logger.error(f"Error deleting recipe: {e}")
        return jsonify({'error': 'Failed to delete recipe'}), 500

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

        return jsonify({
            'dietary_tags': sorted(dietary_tags),
            'cuisine_types': sorted(cuisine_types),
            'difficulties': difficulties,
            'cooking_time_ranges': cooking_time_ranges
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting categories: {e}")
        return jsonify({'error': 'Failed to get categories'}), 500