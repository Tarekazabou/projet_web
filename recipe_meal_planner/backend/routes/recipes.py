from flask import Blueprint, request, jsonify, current_app
from bson import ObjectId
import logging
from datetime import datetime
from backend.utils.recipe_generator import RecipeGenerator
from backend.models.models import Recipe

logger = logging.getLogger(__name__)
recipes_bp = Blueprint('recipes', __name__)

@recipes_bp.route('/generate', methods=['POST'])
def generate_recipe():
    """Generate recipes based on ingredients and dietary preferences"""
    try:
        data = request.get_json()
        
        # Validate input
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        ingredients = data.get('ingredients', [])
        dietary_preferences = data.get('dietary_preferences', [])
        max_cooking_time = data.get('max_cooking_time', 60)
        difficulty = data.get('difficulty', 'any')
        cuisine_type = data.get('cuisine_type', 'any')
        servings = data.get('servings', 2)
        
        # Initialize recipe generator
        generator = RecipeGenerator(current_app.mongo.db)
        
        # Generate recipes
        generated_recipes = generator.generate_recipes(
            ingredients=ingredients,
            dietary_preferences=dietary_preferences,
            max_cooking_time=max_cooking_time,
            difficulty=difficulty,
            cuisine_type=cuisine_type,
            servings=servings
        )
        
        if not generated_recipes:
            return jsonify({
                'message': 'No recipes found matching your criteria',
                'recipes': [],
                'suggestions': generator.get_suggestions(ingredients, dietary_preferences)
            }), 200
        
        # Convert ObjectId to string for JSON serialization
        for recipe in generated_recipes:
            if '_id' in recipe:
                recipe['_id'] = str(recipe['_id'])
        
        return jsonify({
            'message': f'Found {len(generated_recipes)} recipes',
            'recipes': generated_recipes,
            'total_count': len(generated_recipes)
        }), 200
        
    except Exception as e:
        logger.error(f"Error generating recipes: {e}")
        return jsonify({'error': 'Failed to generate recipes'}), 500

@recipes_bp.route('/search', methods=['GET'])
def search_recipes():
    """Search recipes by various criteria"""
    try:
        # Get query parameters
        query = request.args.get('q', '')
        dietary_tags = request.args.getlist('dietary_tags')
        cuisine_type = request.args.get('cuisine_type', '')
        max_cooking_time = request.args.get('max_cooking_time', type=int)
        difficulty = request.args.get('difficulty', '')
        sort_by = request.args.get('sort_by', 'rating')
        page = max(1, request.args.get('page', 1, type=int))
        per_page = min(50, request.args.get('per_page', 20, type=int))
        
        # Build search filter
        search_filter = {}
        
        if query:
            search_filter['$or'] = [
                {'title': {'$regex': query, '$options': 'i'}},
                {'instructions': {'$regex': query, '$options': 'i'}},
                {'ingredients.name': {'$regex': query, '$options': 'i'}}
            ]
        
        if dietary_tags:
            search_filter['dietary_tags'] = {'$in': dietary_tags}
        
        if cuisine_type:
            search_filter['cuisine_type'] = cuisine_type
        
        if max_cooking_time:
            search_filter['cooking_time'] = {'$lte': max_cooking_time}
        
        if difficulty:
            search_filter['difficulty'] = difficulty
        
        # Build sort criteria
        sort_criteria = []
        if sort_by == 'rating':
            sort_criteria = [('rating', -1), ('review_count', -1)]
        elif sort_by == 'cooking_time':
            sort_criteria = [('cooking_time', 1)]
        elif sort_by == 'difficulty':
            difficulty_order = {'easy': 1, 'medium': 2, 'hard': 3}
            sort_criteria = [('difficulty', 1)]
        else:
            sort_criteria = [('created_at', -1)]
        
        # Execute search with pagination
        db = current_app.mongo.db
        total_count = db.recipes.count_documents(search_filter)
        
        recipes = list(db.recipes.find(search_filter)
                      .sort(sort_criteria)
                      .skip((page - 1) * per_page)
                      .limit(per_page))
        
        # Convert ObjectId to string
        for recipe in recipes:
            recipe['_id'] = str(recipe['_id'])
        
        return jsonify({
            'recipes': recipes,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total_count': total_count,
                'total_pages': (total_count + per_page - 1) // per_page
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error searching recipes: {e}")
        return jsonify({'error': 'Failed to search recipes'}), 500

@recipes_bp.route('/<recipe_id>', methods=['GET'])
def get_recipe(recipe_id):
    """Get a specific recipe by ID"""
    try:
        if not ObjectId.is_valid(recipe_id):
            return jsonify({'error': 'Invalid recipe ID'}), 400
        
        db = current_app.mongo.db
        recipe = db.recipes.find_one({'_id': ObjectId(recipe_id)})
        
        if not recipe:
            return jsonify({'error': 'Recipe not found'}), 404
        
        recipe['_id'] = str(recipe['_id'])
        
        # Get related recipes (same dietary tags or cuisine)
        related_recipes = list(db.recipes.find({
            '$or': [
                {'dietary_tags': {'$in': recipe.get('dietary_tags', [])}},
                {'cuisine_type': recipe.get('cuisine_type', '')}
            ],
            '_id': {'$ne': ObjectId(recipe_id)}
        }).limit(5))
        
        for related in related_recipes:
            related['_id'] = str(related['_id'])
        
        return jsonify({
            'recipe': recipe,
            'related_recipes': related_recipes
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting recipe: {e}")
        return jsonify({'error': 'Failed to get recipe'}), 500

@recipes_bp.route('/', methods=['POST'])
def create_recipe():
    """Create a new recipe"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['title', 'ingredients', 'instructions', 'cooking_time', 'prep_time', 'servings']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Create recipe object
        recipe = Recipe(
            title=data['title'],
            ingredients=data['ingredients'],
            instructions=data['instructions'],
            cooking_time=data['cooking_time'],
            prep_time=data['prep_time'],
            servings=data['servings'],
            dietary_tags=data.get('dietary_tags', []),
            nutrition=data.get('nutrition', {}),
            difficulty=data.get('difficulty', 'medium'),
            cuisine_type=data.get('cuisine_type', 'international')
        )
        
        # Insert into database
        db = current_app.mongo.db
        result = db.recipes.insert_one(recipe.to_dict())
        
        # Return created recipe
        created_recipe = db.recipes.find_one({'_id': result.inserted_id})
        created_recipe['_id'] = str(created_recipe['_id'])
        
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
        if not ObjectId.is_valid(recipe_id):
            return jsonify({'error': 'Invalid recipe ID'}), 400
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Update timestamp
        data['updated_at'] = datetime.utcnow()
        
        # Update recipe in database
        db = current_app.mongo.db
        result = db.recipes.update_one(
            {'_id': ObjectId(recipe_id)},
            {'$set': data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Recipe not found'}), 404
        
        # Return updated recipe
        updated_recipe = db.recipes.find_one({'_id': ObjectId(recipe_id)})
        updated_recipe['_id'] = str(updated_recipe['_id'])
        
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
        if not ObjectId.is_valid(recipe_id):
            return jsonify({'error': 'Invalid recipe ID'}), 400
        
        db = current_app.mongo.db
        result = db.recipes.delete_one({'_id': ObjectId(recipe_id)})
        
        if result.deleted_count == 0:
            return jsonify({'error': 'Recipe not found'}), 404
        
        return jsonify({'message': 'Recipe deleted successfully'}), 200
        
    except Exception as e:
        logger.error(f"Error deleting recipe: {e}")
        return jsonify({'error': 'Failed to delete recipe'}), 500

@recipes_bp.route('/categories', methods=['GET'])
def get_categories():
    """Get available recipe categories and filters"""
    try:
        db = current_app.mongo.db
        
        # Get unique dietary tags
        dietary_tags = db.recipes.distinct('dietary_tags')
        
        # Get unique cuisine types
        cuisine_types = db.recipes.distinct('cuisine_type')
        
        # Get difficulty levels
        difficulties = ['easy', 'medium', 'hard']
        
        # Get cooking time ranges
        cooking_time_ranges = [
            {'label': 'Quick (< 15 min)', 'max': 15},
            {'label': 'Medium (15-30 min)', 'min': 15, 'max': 30},
            {'label': 'Long (30-60 min)', 'min': 30, 'max': 60},
            {'label': 'Extended (> 60 min)', 'min': 60}
        ]
        
        return jsonify({
            'dietary_tags': sorted(dietary_tags),
            'cuisine_types': sorted(cuisine_types),
            'difficulties': difficulties,
            'cooking_time_ranges': cooking_time_ranges
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting categories: {e}")
        return jsonify({'error': 'Failed to get categories'}), 500