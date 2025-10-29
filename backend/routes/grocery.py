from flask import Blueprint, request, jsonify
from backend.utils.firebase_connector import get_db
from backend.utils.auth import require_current_user
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
grocery_bp = Blueprint('grocery', __name__)

@grocery_bp.route('/generate', methods=['POST'])
def generate_grocery_list():
    """
    Generate grocery list from recipes.
    This is a simplified version. The original logic was in GroceryListGenerator.
    """
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()

        if not data or 'recipe_ids' not in data:
            return jsonify({'error': 'recipe_ids must be provided'}), 400

        recipe_ids = data['recipe_ids']
        grocery_list = {}

        for recipe_id in recipe_ids:
            recipe_ref = db.collection('Recipe').document(recipe_id)
            recipe = recipe_ref.get()
            if recipe.exists:
                recipe_data = recipe.to_dict()
                # This assumes RecipeIngredient is a subcollection or you'd query it separately
                # For simplicity, let's assume ingredients are stored directly in the recipe for now.
                if 'ingredients' in recipe_data:
                    for item in recipe_data['ingredients']:
                        # This is a very basic aggregation.
                        # A real implementation would handle unit conversions.
                        name = item['ingredient']['name']
                        if name in grocery_list:
                            grocery_list[name]['quantity'] += item['quantity']
                        else:
                            grocery_list[name] = {
                                'quantity': item['quantity'],
                                'unit': item['unit']
                            }
        
        # Here you would typically save the grocery list to a 'GroceryList' collection.
        
        return jsonify({
            'grocery_list': grocery_list,
            'generated_at': datetime.utcnow().isoformat(),
        }), 200
        
    except Exception as e:
        logger.error(f"Error generating grocery list: {e}")
        return jsonify({'error': 'Failed to generate grocery list'}), 500