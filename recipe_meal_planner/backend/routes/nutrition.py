from flask import Blueprint, request, jsonify
from backend.utils.firebase_connector import get_db
import logging

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
        
        query = db.collection('Ingredient').where('name', '>=', query_text).where('name', '<=', query_text + '\uf8ff').limit(limit)
        
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

# The other endpoints (daily-goals, track, history, compare) are highly
# dependent on the original NutritionCalculator class and are omitted here
# as they would require a full re-implementation.