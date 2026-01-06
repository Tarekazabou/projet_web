from flask import Blueprint, request
from google.cloud.firestore_v1.base_query import FieldFilter
from utils.firebase_connector import get_db
from utils.auth import require_current_user
from utils.response_handler import success_response, error_response
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
grocery_bp = Blueprint('grocery', __name__)


def _serialize_grocery_list(list_data, list_id):
    """Serialize grocery list data for JSON response"""
    result = {
        'id': list_id,
        'name': list_data.get('name', ''),
        'items': list_data.get('items', []),
        'createdAt': list_data.get('createdAt').isoformat() if list_data.get('createdAt') else None,
        'updatedAt': list_data.get('updatedAt').isoformat() if list_data.get('updatedAt') else None,
        'linkedMealPlan': list_data.get('linkedMealPlan'),
        'startDate': list_data.get('startDate'),
        'endDate': list_data.get('endDate'),
    }
    return result


def _get_active_grocery_list(db, user_id):
    """Helper to get the most recent grocery list for a user (avoids composite index)"""
    query = db.collection('GroceryList').where(
        filter=FieldFilter('userId', '==', user_id)
    )
    
    docs = list(query.stream())
    
    if not docs:
        return None, None
    
    # Sort in Python to avoid composite index requirement
    docs_sorted = sorted(
        docs, 
        key=lambda d: d.to_dict().get('createdAt', datetime.min),
        reverse=True
    )
    
    return docs_sorted[0], docs_sorted[0].to_dict()


@grocery_bp.route('/items', methods=['GET'])
def get_grocery_items():
    """Get all grocery items for the authenticated user (active list)"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        doc, list_data = _get_active_grocery_list(db, user_id)
        
        if doc and list_data:
            items = list_data.get('items', [])
            return success_response({
                'items': items,
                'listId': doc.id,
                'listName': list_data.get('name', 'My Grocery List')
            })
        
        return success_response({'items': [], 'listId': None, 'listName': None})
        
    except Exception as e:
        logger.error(f"Error getting grocery items: {e}", exc_info=True)
        return error_response('Failed to get grocery items', 500)


@grocery_bp.route('/items', methods=['POST'])
def add_grocery_item():
    """Add an item to the active grocery list"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        if not data or 'name' not in data:
            return error_response('Item name is required', 400)
        
        new_item = {
            'name': data['name'],
            'quantity': data.get('quantity', '1'),
            'unit': data.get('unit', 'pcs'),
            'category': data.get('category', 'Other'),
            'purchased': False,
            'addedAt': datetime.utcnow().isoformat()
        }
        
        doc, list_data = _get_active_grocery_list(db, user_id)
        
        if doc and list_data:
            items = list_data.get('items', [])
            items.append(new_item)
            doc.reference.update({
                'items': items,
                'updatedAt': datetime.utcnow()
            })
            list_id = doc.id
        else:
            # Create new list
            new_list_data = {
                'userId': user_id,
                'name': f"Grocery List {datetime.now().strftime('%Y-%m-%d')}",
                'items': [new_item],
                'createdAt': datetime.utcnow(),
                'updatedAt': datetime.utcnow()
            }
            _, new_ref = db.collection('GroceryList').add(new_list_data)
            list_id = new_ref.id
        
        return success_response({
            'message': 'Item added successfully',
            'item': new_item,
            'listId': list_id
        }, 201)
        
    except Exception as e:
        logger.error(f"Error adding grocery item: {e}", exc_info=True)
        return error_response('Failed to add grocery item', 500)


@grocery_bp.route('/items/<int:item_index>', methods=['DELETE'])
def delete_grocery_item(item_index):
    """Delete a grocery item by index"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        doc, list_data = _get_active_grocery_list(db, user_id)
        
        if not doc:
            return error_response('No grocery list found', 404)
        
        items = list_data.get('items', [])
        
        if item_index < 0 or item_index >= len(items):
            return error_response('Item not found', 404)
        
        removed_item = items.pop(item_index)
        
        doc.reference.update({
            'items': items,
            'updatedAt': datetime.utcnow()
        })
        
        return success_response({
            'message': 'Item deleted successfully',
            'removed': removed_item
        })
        
    except Exception as e:
        logger.error(f"Error deleting grocery item: {e}", exc_info=True)
        return error_response('Failed to delete grocery item', 500)


@grocery_bp.route('/toggle-purchased/<int:item_index>', methods=['POST'])
def toggle_item_purchased(item_index):
    """Toggle the purchased status of an item"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        doc, list_data = _get_active_grocery_list(db, user_id)
        
        if not doc:
            return error_response('No grocery list found', 404)
        
        items = list_data.get('items', [])
        
        if item_index < 0 or item_index >= len(items):
            return error_response('Item not found', 404)
        
        items[item_index]['purchased'] = not items[item_index].get('purchased', False)
        
        doc.reference.update({
            'items': items,
            'updatedAt': datetime.utcnow()
        })
        
        return success_response({
            'message': 'Item toggled successfully',
            'item': items[item_index]
        })
        
    except Exception as e:
        logger.error(f"Error toggling item: {e}", exc_info=True)
        return error_response('Failed to toggle item', 500)


@grocery_bp.route('/from-meal-plan', methods=['POST'])
def create_from_meal_plan():
    """Create a grocery list from meal plan for a date range"""
    try:
        user_id = require_current_user()
        db = get_db()
        data = request.get_json()
        
        start_date = data.get('start_date')
        end_date = data.get('end_date')
        
        if not start_date or not end_date:
            return error_response('start_date and end_date are required', 400)
        
        # Get meal plans - query by userId only to avoid composite index
        query = db.collection('MealPlan').where(
            filter=FieldFilter('userId', '==', user_id)
        )
        
        docs = query.stream()
        
        # Aggregate ingredients - filter by date in Python
        items_dict = {}
        for doc in docs:
            plan = doc.to_dict()
            plan_date = plan.get('planDate', '')
            
            # Filter by date range in Python to avoid composite index
            if not (start_date <= plan_date <= end_date):
                continue
                
            servings = plan.get('servings', 1)
            
            ingredients = plan.get('ingredients', [])
            recipe_ref = plan.get('recipe')
            if recipe_ref and hasattr(recipe_ref, 'get'):
                recipe_doc = recipe_ref.get()
                if recipe_doc.exists:
                    ingredients = recipe_doc.to_dict().get('ingredients', [])
            
            for ing in ingredients:
                name = ing.get('name', '')
                if not name:
                    continue
                
                quantity = float(ing.get('quantity', 1)) * servings
                unit = ing.get('unit', 'pcs')
                category = ing.get('category', 'Other')
                
                key = f"{name.lower()}_{unit}"
                if key in items_dict:
                    items_dict[key]['quantity'] = str(float(items_dict[key]['quantity']) + quantity)
                else:
                    items_dict[key] = {
                        'name': name,
                        'quantity': str(quantity),
                        'unit': unit,
                        'category': category,
                        'purchased': False,
                        'addedAt': datetime.utcnow().isoformat()
                    }
        
        items_list = list(items_dict.values())
        
        # Check fridge inventory
        fridge_query = db.collection('Fridge').where(filter=FieldFilter('userId', '==', user_id))
        fridge_docs = fridge_query.stream()
        
        fridge_items = {}
        for fdoc in fridge_docs:
            fitem = fdoc.to_dict()
            fridge_items[fitem.get('name', '').lower()] = float(fitem.get('quantity', 0))
        
        # Subtract fridge quantities
        final_items = []
        for item in items_list:
            name_lower = item['name'].lower()
            if name_lower in fridge_items:
                needed = float(item['quantity']) - fridge_items[name_lower]
                if needed > 0:
                    item['quantity'] = str(needed)
                    item['inFridge'] = fridge_items[name_lower]
                    final_items.append(item)
            else:
                final_items.append(item)
        
        # Create new grocery list
        list_data = {
            'userId': user_id,
            'name': f"Meal Plan {start_date} to {end_date}",
            'items': final_items,
            'linkedMealPlan': True,
            'startDate': start_date,
            'endDate': end_date,
            'createdAt': datetime.utcnow(),
            'updatedAt': datetime.utcnow()
        }
        
        _, new_ref = db.collection('GroceryList').add(list_data)
        
        return success_response({
            'message': 'Grocery list created from meal plan',
            'listId': new_ref.id,
            'items': final_items,
            'totalItems': len(final_items)
        }, 201)
        
    except Exception as e:
        logger.error(f"Error creating grocery list from meal plan: {e}")
        return error_response('Failed to create grocery list', 500)


# Keep the old endpoints for backward compatibility
@grocery_bp.route('/grocery-lists', methods=['GET'])
def get_grocery_lists():
    """Get all grocery lists for the authenticated user"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        query = db.collection('GroceryList').where(
            filter=FieldFilter('userId', '==', user_id)
        ).order_by('createdAt', direction='DESCENDING')
        docs = query.stream()
        
        lists = []
        for doc in docs:
            list_data = doc.to_dict()
            serialized = _serialize_grocery_list(list_data, doc.id)
            lists.append(serialized)
        
        return success_response({'grocery_lists': lists})
        
    except Exception as e:
        logger.error(f"Error getting grocery lists: {e}")
        return error_response('Failed to get grocery lists', 500)


@grocery_bp.route('/grocery-lists/<list_id>', methods=['DELETE'])
def delete_grocery_list(list_id):
    """Delete a grocery list"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        list_ref = db.collection('GroceryList').document(list_id)
        list_doc = list_ref.get()
        
        if not list_doc.exists:
            return error_response('Grocery list not found', 404)
        
        list_data = list_doc.to_dict()
        
        if list_data.get('userId') != user_id:
            return error_response('Not authorized', 403)
        
        list_ref.delete()
        
        return success_response({'message': 'Grocery list deleted successfully'})
        
    except Exception as e:
        logger.error(f"Error deleting grocery list: {e}")
        return error_response('Failed to delete grocery list', 500)


@grocery_bp.route('/stats', methods=['GET'])
def get_grocery_stats():
    """Get grocery list statistics"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        query = db.collection('GroceryList').where(
            filter=FieldFilter('userId', '==', user_id)
        ).order_by('createdAt', direction='DESCENDING').limit(1)
        
        docs = list(query.stream())
        
        if not docs:
            return success_response({
                'totalItems': 0,
                'purchasedItems': 0,
                'progress': 0,
                'categories': {}
            })
        
        list_data = docs[0].to_dict()
        items = list_data.get('items', [])
        
        total = len(items)
        purchased = sum(1 for item in items if item.get('purchased', False))
        
        # Group by category
        categories = {}
        for item in items:
            cat = item.get('category', 'Other')
            if cat not in categories:
                categories[cat] = {'total': 0, 'purchased': 0}
            categories[cat]['total'] += 1
            if item.get('purchased', False):
                categories[cat]['purchased'] += 1
        
        return success_response({
            'totalItems': total,
            'purchasedItems': purchased,
            'progress': int((purchased / total * 100)) if total > 0 else 0,
            'categories': categories
        })
        
    except Exception as e:
        logger.error(f"Error getting grocery stats: {e}")
        return error_response('Failed to get grocery stats', 500)