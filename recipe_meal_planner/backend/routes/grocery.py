from flask import Blueprint, request, jsonify, current_app, send_file
from bson import ObjectId
import logging
from datetime import datetime
from backend.utils.grocery_list_generator import GroceryListGenerator
from backend.utils.store_integrations import StoreIntegrationManager

logger = logging.getLogger(__name__)
grocery_bp = Blueprint('grocery', __name__)

@grocery_bp.route('/generate', methods=['POST'])
def generate_grocery_list():
    """Generate grocery list from recipes or meal plan"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        generator = GroceryListGenerator(current_app.mongo.db)
        
        # Check if generating from meal plan or individual recipes
        if 'meal_plan_id' in data:
            meal_plan_id = data['meal_plan_id']
            if not ObjectId.is_valid(meal_plan_id):
                return jsonify({'error': 'Invalid meal plan ID'}), 400
            
            grocery_list = generator.generate_from_meal_plan_id(meal_plan_id)
        
        elif 'recipe_ids' in data:
            recipe_ids = data['recipe_ids']
            servings_adjustments = data.get('servings_adjustments', {})
            grocery_list = generator.generate_from_recipes(recipe_ids, servings_adjustments)
        
        else:
            return jsonify({'error': 'Either meal_plan_id or recipe_ids must be provided'}), 400
        
        if not grocery_list:
            return jsonify({'error': 'Could not generate grocery list'}), 500
        
        # Save grocery list for user
        user_id = data.get('user_id')
        if user_id:
            generator.save_grocery_list(user_id, grocery_list)
        
        return jsonify({
            'grocery_list': grocery_list,
            'generated_at': datetime.utcnow().isoformat(),
            'estimated_cost': generator.estimate_total_cost(grocery_list)
        }), 200
        
    except Exception as e:
        logger.error(f"Error generating grocery list: {e}")
        return jsonify({'error': 'Failed to generate grocery list'}), 500

@grocery_bp.route('/export', methods=['POST'])
def export_grocery_list():
    """Export grocery list as PDF or text file"""
    try:
        data = request.get_json()
        
        if not data or 'grocery_list' not in data:
            return jsonify({'error': 'Grocery list data is required'}), 400
        
        grocery_list = data['grocery_list']
        export_format = data.get('format', 'pdf')  # pdf, txt, json
        title = data.get('title', 'Grocery List')
        
        generator = GroceryListGenerator(current_app.mongo.db)
        
        if export_format == 'pdf':
            file_path = generator.export_to_pdf(grocery_list, title)
        elif export_format == 'txt':
            file_path = generator.export_to_text(grocery_list, title)
        elif export_format == 'json':
            file_path = generator.export_to_json(grocery_list, title)
        else:
            return jsonify({'error': 'Unsupported export format'}), 400
        
        if not file_path:
            return jsonify({'error': 'Failed to export grocery list'}), 500
        
        return send_file(
            file_path,
            as_attachment=True,
            download_name=f'{title.replace(" ", "_")}.{export_format}'
        )
        
    except Exception as e:
        logger.error(f"Error exporting grocery list: {e}")
        return jsonify({'error': 'Failed to export grocery list'}), 500

@grocery_bp.route('/store-integration', methods=['POST'])
def integrate_with_store():
    """Integrate grocery list with online store"""
    try:
        data = request.get_json()
        
        required_fields = ['grocery_list', 'store']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        grocery_list = data['grocery_list']
        store = data['store']  # instacart, amazon_fresh, walmart
        user_id = data.get('user_id')
        
        # Initialize store integration manager
        integration_manager = StoreIntegrationManager()
        
        # Process integration
        if store == 'instacart':
            result = integration_manager.integrate_instacart(grocery_list, user_id)
        elif store == 'amazon_fresh':
            result = integration_manager.integrate_amazon_fresh(grocery_list, user_id)
        elif store == 'walmart':
            result = integration_manager.integrate_walmart(grocery_list, user_id)
        else:
            return jsonify({'error': 'Unsupported store integration'}), 400
        
        if not result['success']:
            return jsonify({'error': result.get('error', 'Integration failed')}), 500
        
        return jsonify({
            'message': f'Successfully integrated with {store}',
            'integration_url': result.get('url'),
            'cart_id': result.get('cart_id'),
            'estimated_total': result.get('estimated_total'),
            'available_items': result.get('available_items', []),
            'unavailable_items': result.get('unavailable_items', [])
        }), 200
        
    except Exception as e:
        logger.error(f"Error with store integration: {e}")
        return jsonify({'error': 'Failed to integrate with store'}), 500

@grocery_bp.route('/saved/<user_id>', methods=['GET'])
def get_saved_grocery_lists(user_id):
    """Get saved grocery lists for a user"""
    try:
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        page = max(1, request.args.get('page', 1, type=int))
        per_page = min(50, request.args.get('per_page', 10, type=int))
        
        db = current_app.mongo.db
        total_count = db.grocery_lists.count_documents({'user_id': user_id})
        
        grocery_lists = list(db.grocery_lists.find({'user_id': user_id})
                           .sort('created_at', -1)
                           .skip((page - 1) * per_page)
                           .limit(per_page))
        
        # Convert ObjectIds to strings
        for grocery_list in grocery_lists:
            grocery_list['_id'] = str(grocery_list['_id'])
        
        return jsonify({
            'grocery_lists': grocery_lists,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total_count': total_count,
                'total_pages': (total_count + per_page - 1) // per_page
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting saved grocery lists: {e}")
        return jsonify({'error': 'Failed to get grocery lists'}), 500

@grocery_bp.route('/optimize', methods=['POST'])
def optimize_grocery_list():
    """Optimize grocery list for cost and availability"""
    try:
        data = request.get_json()
        
        if not data or 'grocery_list' not in data:
            return jsonify({'error': 'Grocery list is required'}), 400
        
        grocery_list = data['grocery_list']
        location = data.get('location', 'general')
        budget_limit = data.get('budget_limit')
        store_preference = data.get('store_preference')
        
        generator = GroceryListGenerator(current_app.mongo.db)
        
        # Optimize grocery list
        optimized_list = generator.optimize_grocery_list(
            grocery_list=grocery_list,
            location=location,
            budget_limit=budget_limit,
            store_preference=store_preference
        )
        
        return jsonify({
            'optimized_list': optimized_list,
            'optimization_details': {
                'cost_savings': optimized_list.get('cost_savings', 0),
                'substitutions_made': optimized_list.get('substitutions', []),
                'stores_compared': optimized_list.get('stores_compared', [])
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error optimizing grocery list: {e}")
        return jsonify({'error': 'Failed to optimize grocery list'}), 500

@grocery_bp.route('/price-comparison', methods=['POST'])
def compare_prices():
    """Compare prices across different stores"""
    try:
        data = request.get_json()
        
        if not data or 'items' not in data:
            return jsonify({'error': 'Items list is required'}), 400
        
        items = data['items']  # List of grocery items
        stores = data.get('stores', ['instacart', 'amazon_fresh', 'walmart'])
        location = data.get('location', 'general')
        
        integration_manager = StoreIntegrationManager()
        
        # Get price comparison
        comparison_results = integration_manager.compare_prices(
            items=items,
            stores=stores,
            location=location
        )
        
        return jsonify({
            'price_comparison': comparison_results,
            'best_deals': integration_manager.find_best_deals(comparison_results),
            'total_savings': integration_manager.calculate_savings(comparison_results)
        }), 200
        
    except Exception as e:
        logger.error(f"Error comparing prices: {e}")
        return jsonify({'error': 'Failed to compare prices'}), 500

@grocery_bp.route('/pantry-check', methods=['POST'])
def check_pantry():
    """Check what items user already has in pantry"""
    try:
        data = request.get_json()
        
        if not data or 'grocery_list' not in data:
            return jsonify({'error': 'Grocery list is required'}), 400
        
        grocery_list = data['grocery_list']
        user_id = data.get('user_id')
        pantry_items = data.get('pantry_items', [])
        
        generator = GroceryListGenerator(current_app.mongo.db)
        
        # Check against pantry
        updated_list = generator.check_against_pantry(
            grocery_list=grocery_list,
            pantry_items=pantry_items,
            user_id=user_id
        )
        
        return jsonify({
            'updated_grocery_list': updated_list,
            'items_in_pantry': updated_list.get('already_have', []),
            'items_to_buy': updated_list.get('need_to_buy', []),
            'cost_savings': updated_list.get('pantry_savings', 0)
        }), 200
        
    except Exception as e:
        logger.error(f"Error checking pantry: {e}")
        return jsonify({'error': 'Failed to check pantry'}), 500

@grocery_bp.route('/stores', methods=['GET'])
def get_available_stores():
    """Get list of available store integrations"""
    try:
        location = request.args.get('location', 'general')
        
        integration_manager = StoreIntegrationManager()
        available_stores = integration_manager.get_available_stores(location)
        
        return jsonify({
            'stores': available_stores,
            'location': location
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting available stores: {e}")
        return jsonify({'error': 'Failed to get available stores'}), 500