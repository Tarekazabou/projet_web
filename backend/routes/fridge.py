from flask import Blueprint, request, jsonify
from utils.firebase_connector import get_db
from utils.auth import require_current_user
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

        # Start with a base query for the user's items
        query = db.collection('FridgeItem').where('user', '==', db.collection('User').document(user_id))

        # Get query parameters
        search = request.args.get('search', '')
        freshness = request.args.get('freshness', 'all')

        if search:
            # Firestore doesn't support regex search. This is a basic prefix search.
            query = query.where('ingredient.name', '>=', search).where('ingredient.name', '<=', search + '\uf8ff')

        docs = query.stream()
        
        items = []
        for doc in docs:
            item = doc.to_dict()
            item['id'] = doc.id
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

        return jsonify({
            'success': True,
            'items': items,
            'total': len(items)
        })
        
    except Exception as e:
        logger.error(f"Error getting fridge items: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@fridge_bp.route('/items', methods=['POST'])  
def add_fridge_item():
    """Add a new item to the fridge"""
    try:
        user_id = require_current_user()
        db = get_db()

        data = request.get_json() or {}

        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400
        
        required_fields = ['ingredient', 'quantity', 'unit']
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({'success': False, 'error': f'Missing required field: {field}'}), 400
        
        # You might need to resolve ingredient name to an ingredient reference
        # For simplicity, assuming 'ingredient' is an ID for now.
        new_item = {
            'user': db.collection('User').document(user_id),
            'ingredient': db.collection('Ingredient').document(data['ingredient']),
            'quantity': float(data['quantity']),
            'unit': data['unit'],
            'addedAt': datetime.utcnow(),
            'expirationDate': data.get('expirationDate') # Should be in 'YYYY-MM-DD' format
        }
        
        _, new_item_ref = db.collection('FridgeItem').add(new_item)
        
        created_item = new_item_ref.get().to_dict()
        created_item['id'] = new_item_ref.id

        return jsonify({
            'success': True,
            'item': created_item,
            'message': 'Item added to fridge'
        }), 201
        
    except Exception as e:
        logger.error(f"Error adding fridge item: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@fridge_bp.route('/items/<item_id>', methods=['PUT'])
def update_fridge_item(item_id):
    """Update an existing fridge item"""
    try:
        user_id = require_current_user()
        db = get_db()

        data = request.get_json() or {}
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400
        
        item_ref = db.collection('FridgeItem').document(item_id)
        
        # Verify the item belongs to the user
        item_doc = item_ref.get()
        if not item_doc.exists or item_doc.to_dict()['user'].id != user_id:
            return jsonify({'success': False, 'error': 'Item not found'}), 404

        update_data = {}
        allowed_fields = ['quantity', 'unit', 'expirationDate']
        for field in allowed_fields:
            if field in data:
                update_data[field] = data[field]
        
        if update_data:
            item_ref.update(update_data)
        
        updated_item = item_ref.get().to_dict()
        updated_item['id'] = item_ref.id
        
        return jsonify({
            'success': True,
            'item': updated_item,
            'message': 'Item updated successfully'
        })
        
    except Exception as e:
        logger.error(f"Error updating fridge item: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@fridge_bp.route('/items/<item_id>', methods=['DELETE'])
def delete_fridge_item(item_id):
    """Delete a fridge item"""
    try:
        user_id = require_current_user()
        db = get_db()

        item_ref = db.collection('FridgeItem').document(item_id)

        # Verify the item belongs to the user
        item_doc = item_ref.get()
        if not item_doc.exists or item_doc.to_dict()['user'].id != user_id:
            return jsonify({'success': False, 'error': 'Item not found'}), 404
        
        item_ref.delete()
        
        return jsonify({
            'success': True,
            'message': 'Item removed from fridge'
        })
        
    except Exception as e:
        logger.error(f"Error deleting fridge item: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500