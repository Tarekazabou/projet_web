from flask import Blueprint, request, jsonify
from utils.firebase_connector import get_db
from utils.auth import require_current_user
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
grocery_bp = Blueprint('grocery', __name__)

@grocery_bp.route('/grocery-lists', methods=['GET'])
def get_grocery_lists():
    """Get all grocery lists for the authenticated user"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        query = db.collection('GroceryList').where('user', '==', db.collection('User').document(user_id))
        docs = query.stream()
        
        lists = []
        for doc in docs:
            grocery_list = doc.to_dict()
            grocery_list['id'] = doc.id
            lists.append(grocery_list)
        
        return jsonify({
            'grocery_lists': lists
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting grocery lists: {e}")
        return jsonify({'error': 'Failed to get grocery lists'}), 500

@grocery_bp.route('/grocery-lists', methods=['POST'])
def create_grocery_list():
    """Create a new grocery list"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        list_data = {
            'user': db.collection('User').document(user_id),
            'name': data.get('name', f"Grocery List {datetime.now().strftime('%Y-%m-%d')}"),
            'items': data.get('items', []),
            'createdAt': datetime.utcnow(),
            'updatedAt': datetime.utcnow()
        }
        
        _, new_list_ref = db.collection('GroceryList').add(list_data)
        
        created_list = new_list_ref.get().to_dict()
        created_list['id'] = new_list_ref.id
        
        return jsonify({
            'message': 'Grocery list created successfully',
            'grocery_list': created_list
        }), 201
        
    except Exception as e:
        logger.error(f"Error creating grocery list: {e}")
        return jsonify({'error': 'Failed to create grocery list'}), 500

@grocery_bp.route('/grocery-lists/<list_id>', methods=['GET'])
def get_grocery_list(list_id):
    """Get a specific grocery list"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        list_ref = db.collection('GroceryList').document(list_id)
        list_doc = list_ref.get()
        
        if not list_doc.exists:
            return jsonify({'error': 'Grocery list not found'}), 404
        
        list_data = list_doc.to_dict()
        
        # Verify ownership
        if list_data['user'].id != user_id:
            return jsonify({'error': 'Not authorized'}), 403
        
        list_data['id'] = list_doc.id
        
        return jsonify({
            'grocery_list': list_data
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting grocery list: {e}")
        return jsonify({'error': 'Failed to get grocery list'}), 500

@grocery_bp.route('/grocery-lists/<list_id>', methods=['PUT'])
def update_grocery_list(list_id):
    """Update a grocery list"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        list_ref = db.collection('GroceryList').document(list_id)
        list_doc = list_ref.get()
        
        if not list_doc.exists:
            return jsonify({'error': 'Grocery list not found'}), 404
        
        list_data = list_doc.to_dict()
        
        # Verify ownership
        if list_data['user'].id != user_id:
            return jsonify({'error': 'Not authorized'}), 403
        
        update_data = {}
        allowed_fields = ['name', 'items']
        for field in allowed_fields:
            if field in data:
                update_data[field] = data[field]
        
        update_data['updatedAt'] = datetime.utcnow()
        
        list_ref.update(update_data)
        
        updated_list = list_ref.get().to_dict()
        updated_list['id'] = list_ref.id
        
        return jsonify({
            'message': 'Grocery list updated successfully',
            'grocery_list': updated_list
        }), 200
        
    except Exception as e:
        logger.error(f"Error updating grocery list: {e}")
        return jsonify({'error': 'Failed to update grocery list'}), 500

@grocery_bp.route('/grocery-lists/<list_id>', methods=['DELETE'])
def delete_grocery_list(list_id):
    """Delete a grocery list"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        list_ref = db.collection('GroceryList').document(list_id)
        list_doc = list_ref.get()
        
        if not list_doc.exists:
            return jsonify({'error': 'Grocery list not found'}), 404
        
        list_data = list_doc.to_dict()
        
        # Verify ownership
        if list_data['user'].id != user_id:
            return jsonify({'error': 'Not authorized'}), 403
        
        list_ref.delete()
        
        return jsonify({
            'message': 'Grocery list deleted successfully'
        }), 200
        
    except Exception as e:
        logger.error(f"Error deleting grocery list: {e}")
        return jsonify({'error': 'Failed to delete grocery list'}), 500

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