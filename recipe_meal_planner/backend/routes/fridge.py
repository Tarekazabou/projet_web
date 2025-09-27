from flask import Blueprint, request, jsonify
from bson.objectid import ObjectId
from datetime import datetime, timedelta
import re

fridge_bp = Blueprint('fridge', __name__)

# ===== FRIDGE INVENTORY ENDPOINTS =====

@fridge_bp.route('/items', methods=['GET'])
def get_fridge_items():
    """Get all items in user's fridge"""
    try:
        from app import mongo
        
        # Get query parameters
        category = request.args.get('category', 'all')
        freshness = request.args.get('freshness', 'all')
        search = request.args.get('search', '')
        
        # Build query
        query = {}
        
        if category != 'all':
            query['category'] = category
            
        if search:
            query['name'] = {'$regex': search, '$options': 'i'}
        
        # Get items from database
        items = list(mongo.db.fridge_items.find(query))
        
        # Convert ObjectId to string
        for item in items:
            item['_id'] = str(item['_id'])
            
        # Filter by freshness if specified
        if freshness != 'all':
            filtered_items = []
            today = datetime.now().date()
            
            for item in items:
                expiry_date = datetime.strptime(item['expiryDate'], '%Y-%m-%d').date()
                days_until_expiry = (expiry_date - today).days
                
                if freshness == 'fresh' and days_until_expiry > 2:
                    filtered_items.append(item)
                elif freshness == 'expiring-soon' and 0 <= days_until_expiry <= 2:
                    filtered_items.append(item)
                elif freshness == 'expired' and days_until_expiry < 0:
                    filtered_items.append(item)
                    
            items = filtered_items
        
        return jsonify({
            'success': True,
            'items': items,
            'total': len(items)
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@fridge_bp.route('/items', methods=['POST'])  
def add_fridge_item():
    """Add a new item to the fridge"""
    try:
        from app import mongo
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'category', 'quantity', 'unit', 'expiryDate']
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({
                    'success': False,
                    'error': f'Missing required field: {field}'
                }), 400
        
        # Create new item
        new_item = {
            'name': data['name'].strip(),
            'category': data['category'],
            'quantity': float(data['quantity']),
            'unit': data['unit'],
            'expiryDate': data['expiryDate'],
            'location': data.get('location', 'Main fridge'),
            'notes': data.get('notes', ''),
            'addedDate': data.get('addedDate', datetime.now().strftime('%Y-%m-%d')),
            'userId': 'default_user',  # TODO: Replace with actual user ID
            'createdAt': datetime.utcnow(),
            'updatedAt': datetime.utcnow()
        }
        
        # Insert into database
        result = mongo.db.fridge_items.insert_one(new_item)
        new_item['_id'] = str(result.inserted_id)
        
        return jsonify({
            'success': True,
            'item': new_item,
            'message': f'{new_item["name"]} added to fridge'
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@fridge_bp.route('/items/<item_id>', methods=['PUT'])
def update_fridge_item(item_id):
    """Update an existing fridge item"""
    try:
        from app import mongo
        
        data = request.get_json()
        
        # Build update data
        update_data = {
            'updatedAt': datetime.utcnow()
        }
        
        # Update allowed fields
        allowed_fields = ['name', 'category', 'quantity', 'unit', 'expiryDate', 'location', 'notes']
        for field in allowed_fields:
            if field in data:
                if field == 'quantity':
                    update_data[field] = float(data[field])
                else:
                    update_data[field] = data[field]
        
        # Update item in database
        result = mongo.db.fridge_items.update_one(
            {'_id': ObjectId(item_id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({
                'success': False,
                'error': 'Item not found'
            }), 404
        
        # Get updated item
        updated_item = mongo.db.fridge_items.find_one({'_id': ObjectId(item_id)})
        updated_item['_id'] = str(updated_item['_id'])
        
        return jsonify({
            'success': True,
            'item': updated_item,
            'message': 'Item updated successfully'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@fridge_bp.route('/items/<item_id>', methods=['DELETE'])
def delete_fridge_item(item_id):
    """Delete a fridge item"""
    try:
        from app import mongo
        
        # Get item name before deletion
        item = mongo.db.fridge_items.find_one({'_id': ObjectId(item_id)})
        if not item:
            return jsonify({
                'success': False,
                'error': 'Item not found'
            }), 404
        
        # Delete item
        result = mongo.db.fridge_items.delete_one({'_id': ObjectId(item_id)})
        
        if result.deleted_count == 0:
            return jsonify({
                'success': False,
                'error': 'Failed to delete item'
            }), 500
        
        return jsonify({
            'success': True,
            'message': f'{item["name"]} removed from fridge'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@fridge_bp.route('/stats', methods=['GET'])
def get_fridge_stats():
    """Get fridge inventory statistics"""
    try:
        from app import mongo
        
        # Get all items
        items = list(mongo.db.fridge_items.find())
        
        total_items = len(items)
        fresh_items = 0
        expiring_soon = 0
        expired_items = 0
        
        today = datetime.now().date()
        
        for item in items:
            try:
                expiry_date = datetime.strptime(item['expiryDate'], '%Y-%m-%d').date()
                days_until_expiry = (expiry_date - today).days
                
                if days_until_expiry < 0:
                    expired_items += 1
                elif days_until_expiry <= 2:
                    expiring_soon += 1
                else:
                    fresh_items += 1
            except (ValueError, KeyError):
                # Handle invalid date formats
                continue
        
        # Category breakdown
        category_stats = {}
        for item in items:
            category = item.get('category', 'other')
            category_stats[category] = category_stats.get(category, 0) + 1
        
        return jsonify({
            'success': True,
            'stats': {
                'total_items': total_items,
                'fresh_items': fresh_items,
                'expiring_soon': expiring_soon,
                'expired_items': expired_items,
                'category_breakdown': category_stats
            }
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@fridge_bp.route('/suggestions', methods=['GET'])
def get_recipe_suggestions():
    """Get recipe suggestions based on fridge contents"""
    try:
        from app import mongo
        
        # Get fresh ingredients from fridge
        today = datetime.now().date()
        fresh_ingredients = []
        
        items = list(mongo.db.fridge_items.find())
        
        for item in items:
            try:
                expiry_date = datetime.strptime(item['expiryDate'], '%Y-%m-%d').date()
                if expiry_date >= today:  # Not expired
                    fresh_ingredients.append(item['name'].lower())
            except (ValueError, KeyError):
                continue
        
        if not fresh_ingredients:
            return jsonify({
                'success': True,
                'recipes': [],
                'message': 'No fresh ingredients available for suggestions'
            })
        
        # Find recipes that match available ingredients
        pipeline = [
            {
                '$match': {
                    'ingredients.name': {
                        '$regex': '|'.join(fresh_ingredients),
                        '$options': 'i'
                    }
                }
            },
            {
                '$addFields': {
                    'ingredient_matches': {
                        '$size': {
                            '$filter': {
                                'input': '$ingredients',
                                'cond': {
                                    '$regexMatch': {
                                        'input': '$$this.name',
                                        'regex': '|'.join(fresh_ingredients),
                                        'options': 'i'
                                    }
                                }
                            }
                        }
                    }
                }
            },
            {
                '$sort': {'ingredient_matches': -1, 'rating': -1}
            },
            {
                '$limit': 10
            }
        ]
        
        recipes = list(mongo.db.recipes.aggregate(pipeline))
        
        # Convert ObjectId to string and calculate match percentage
        for recipe in recipes:
            recipe['_id'] = str(recipe['_id'])
            total_ingredients = len(recipe.get('ingredients', []))
            matches = recipe.get('ingredient_matches', 0)
            recipe['match_percentage'] = round((matches / total_ingredients) * 100) if total_ingredients > 0 else 0
        
        return jsonify({
            'success': True,
            'recipes': recipes,
            'available_ingredients': fresh_ingredients
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@fridge_bp.route('/cleanup-expired', methods=['POST'])
def cleanup_expired_items():
    """Remove expired items from fridge"""
    try:
        from app import mongo
        
        today = datetime.now().date()
        expired_items = []
        
        # Find expired items
        items = list(mongo.db.fridge_items.find())
        for item in items:
            try:
                expiry_date = datetime.strptime(item['expiryDate'], '%Y-%m-%d').date()
                if expiry_date < today:
                    expired_items.append(item)
            except (ValueError, KeyError):
                continue
        
        if not expired_items:
            return jsonify({
                'success': True,
                'message': 'No expired items found',
                'removed_count': 0
            })
        
        # Remove expired items
        expired_ids = [item['_id'] for item in expired_items]
        result = mongo.db.fridge_items.delete_many({'_id': {'$in': expired_ids}})
        
        return jsonify({
            'success': True,
            'message': f'Removed {result.deleted_count} expired items',
            'removed_count': result.deleted_count,
            'removed_items': [item['name'] for item in expired_items]
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@fridge_bp.route('/categories', methods=['GET'])
def get_categories():
    """Get all fridge categories with metadata"""
    try:
        categories = {
            'produce': {
                'name': 'Produce',
                'icon': 'fas fa-apple-alt',
                'color': '#10b981',
                'typical_storage': 'Crisper drawer',
                'avg_expiry_days': 7
            },
            'dairy': {
                'name': 'Dairy',
                'icon': 'fas fa-cheese',
                'color': '#f59e0b',
                'typical_storage': 'Main fridge',
                'avg_expiry_days': 10
            },
            'meat': {
                'name': 'Meat & Seafood',
                'icon': 'fas fa-drumstick-bite',
                'color': '#ef4444',
                'typical_storage': 'Freezer',
                'avg_expiry_days': 3
            },
            'pantry': {
                'name': 'Pantry',
                'icon': 'fas fa-jar',
                'color': '#8b5cf6',
                'typical_storage': 'Pantry',
                'avg_expiry_days': 365
            },
            'frozen': {
                'name': 'Frozen',
                'icon': 'fas fa-snowflake',
                'color': '#06b6d4',
                'typical_storage': 'Freezer',
                'avg_expiry_days': 90
            },
            'beverages': {
                'name': 'Beverages',
                'icon': 'fas fa-wine-bottle',
                'color': '#3b82f6',
                'typical_storage': 'Door',
                'avg_expiry_days': 30
            },
            'other': {
                'name': 'Other',
                'icon': 'fas fa-box',
                'color': '#6b7280',
                'typical_storage': 'Main fridge',
                'avg_expiry_days': 14
            }
        }
        
        return jsonify({
            'success': True,
            'categories': categories
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@fridge_bp.route('/bulk-add', methods=['POST'])
def bulk_add_items():
    """Add multiple items to fridge at once"""
    try:
        from app import mongo
        
        data = request.get_json()
        items_data = data.get('items', [])
        
        if not items_data:
            return jsonify({
                'success': False,
                'error': 'No items provided'
            }), 400
        
        new_items = []
        errors = []
        
        for i, item_data in enumerate(items_data):
            try:
                # Validate required fields
                required_fields = ['name', 'category', 'quantity', 'unit', 'expiryDate']
                for field in required_fields:
                    if field not in item_data or not item_data[field]:
                        errors.append(f'Item {i+1}: Missing required field: {field}')
                        continue
                
                # Create new item
                new_item = {
                    'name': item_data['name'].strip(),
                    'category': item_data['category'],
                    'quantity': float(item_data['quantity']),
                    'unit': item_data['unit'],
                    'expiryDate': item_data['expiryDate'],
                    'location': item_data.get('location', 'Main fridge'),
                    'notes': item_data.get('notes', ''),
                    'addedDate': item_data.get('addedDate', datetime.now().strftime('%Y-%m-%d')),
                    'userId': 'default_user',  # TODO: Replace with actual user ID
                    'createdAt': datetime.utcnow(),
                    'updatedAt': datetime.utcnow()
                }
                
                new_items.append(new_item)
                
            except Exception as e:
                errors.append(f'Item {i+1}: {str(e)}')
        
        if not new_items:
            return jsonify({
                'success': False,
                'error': 'No valid items to add',
                'errors': errors
            }), 400
        
        # Insert valid items
        result = mongo.db.fridge_items.insert_many(new_items)
        
        # Convert ObjectId to string
        for i, item in enumerate(new_items):
            item['_id'] = str(result.inserted_ids[i])
        
        return jsonify({
            'success': True,
            'items': new_items,
            'added_count': len(new_items),
            'errors': errors,
            'message': f'Successfully added {len(new_items)} items to fridge'
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500