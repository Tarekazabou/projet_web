"""
Dashboard Routes - Provides endpoints for dashboard statistics and data
"""
from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta
from utils.firebase_connector import get_db
from utils.response_handler import success_response, error_response
from utils.auth import require_current_user

dashboard_bp = Blueprint('dashboard', __name__)


@dashboard_bp.route('/stats', methods=['GET'])
def get_dashboard_stats():
    """Get dashboard statistics for the current user"""
    try:
        # Get authenticated user ID
        user_id = require_current_user()
        db = get_db()
        
        # Count total recipes
        recipes_ref = db.collection('users').document(user_id).collection('recipes')
        recipes = list(recipes_ref.stream())
        total_recipes = len(recipes)
        
        # Count saved/favorite recipes
        saved_recipes = sum(1 for r in recipes if r.to_dict().get('isFavorite', False))
        
        # Count fridge items
        fridge_ref = db.collection('users').document(user_id).collection('fridge')
        fridge_items = list(fridge_ref.stream())
        total_fridge_items = len(fridge_items)
        
        # Count expiring items (within 3 days)
        today = datetime.now()
        expiring_count = 0
        for item in fridge_items:
            item_data = item.to_dict()
            exp_date = item_data.get('expirationDate')
            if exp_date:
                if isinstance(exp_date, str):
                    try:
                        exp_date = datetime.fromisoformat(exp_date.replace('Z', '+00:00'))
                    except:
                        continue
                if hasattr(exp_date, 'date'):
                    days_until = (exp_date.date() - today.date()).days
                    if 0 <= days_until <= 3:
                        expiring_count += 1
        
        # Count meals planned (for this week)
        meal_plans_ref = db.collection('users').document(user_id).collection('meal_plans')
        week_start = today - timedelta(days=today.weekday())
        week_end = week_start + timedelta(days=7)
        
        meals_planned = 0
        for plan in meal_plans_ref.stream():
            plan_data = plan.to_dict()
            plan_date = plan_data.get('date')
            if plan_date:
                if isinstance(plan_date, str):
                    try:
                        plan_date = datetime.fromisoformat(plan_date.replace('Z', '+00:00'))
                    except:
                        continue
                if week_start <= plan_date <= week_end:
                    meals_planned += len(plan_data.get('meals', []))
        
        return success_response({
            'totalRecipes': total_recipes,
            'savedRecipes': saved_recipes,
            'fridgeItems': total_fridge_items,
            'expiringItems': expiring_count,
            'mealsPlanned': meals_planned
        })
        
    except Exception as e:
        return error_response(f'Failed to get dashboard stats: {str(e)}', 500)


@dashboard_bp.route('/quick-actions', methods=['GET'])
def get_quick_actions():
    """Get quick action buttons configuration"""
    try:
        actions = [
            {
                'id': 'fridge',
                'label': 'Mon Frigo',
                'icon': 'fridge',
                'route': '/fridge',
                'isEnabled': True
            },
            {
                'id': 'recipes',
                'label': 'Recettes',
                'icon': 'recipe',
                'route': '/recipes',
                'isEnabled': True
            },
            {
                'id': 'meal_plan',
                'label': 'Planning',
                'icon': 'calendar',
                'route': '/meal-plan',
                'isEnabled': True
            },
            {
                'id': 'grocery',
                'label': 'Courses',
                'icon': 'grocery',
                'route': '/grocery',
                'isEnabled': True
            }
        ]
        
        return success_response({'actions': actions})
        
    except Exception as e:
        return error_response(f'Failed to get quick actions: {str(e)}', 500)


@dashboard_bp.route('/nutrition-tips', methods=['GET'])
def get_nutrition_tips():
    """Get nutrition tips for the dashboard"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        # Get today's nutrition data
        today = datetime.now().strftime('%Y-%m-%d')
        daily_ref = db.collection('users').document(user_id).collection('nutrition').document(today)
        daily_data = daily_ref.get()
        
        tips = []
        
        if daily_data.exists:
            data = daily_data.to_dict()
            totals = data.get('totals', {})
            goals = data.get('goals', {'calories': 2000, 'protein': 100, 'carbs': 250, 'fat': 65, 'water': 8})
            
            # Calculate percentages
            cal_pct = (totals.get('calories', 0) / goals.get('calories', 2000)) * 100
            protein_pct = (totals.get('protein', 0) / goals.get('protein', 100)) * 100
            water = data.get('waterIntake', 0)
            water_goal = goals.get('water', 8)
            
            # Generate dynamic tips
            if cal_pct < 50:
                tips.append({
                    'id': '1',
                    'title': 'Énergie',
                    'description': f"Vous n'avez consommé que {int(cal_pct)}% de vos calories. Pensez à manger régulièrement!",
                    'icon': 'energy',
                    'category': 'warning'
                })
            elif cal_pct > 100:
                tips.append({
                    'id': '1',
                    'title': 'Attention',
                    'description': f"Vous avez dépassé votre objectif calorique de {int(cal_pct - 100)}%",
                    'icon': 'warning',
                    'category': 'warning'
                })
            
            if protein_pct < 80:
                tips.append({
                    'id': '2',
                    'title': 'Protéines',
                    'description': 'Ajoutez plus de protéines à vos repas pour atteindre votre objectif',
                    'icon': 'protein',
                    'category': 'info'
                })
            
            if water < water_goal * 0.5:
                tips.append({
                    'id': '3',
                    'title': 'Hydratation',
                    'description': f"Buvez plus d'eau! {water}/{water_goal} verres aujourd'hui",
                    'icon': 'water',
                    'category': 'warning'
                })
        
        # Add default tips if none generated
        if not tips:
            tips = [
                {
                    'id': '1',
                    'title': 'Hydratation',
                    'description': "Buvez au moins 8 verres d'eau par jour",
                    'icon': 'water',
                    'category': 'general'
                },
                {
                    'id': '2',
                    'title': 'Protéines',
                    'description': 'Incluez des protéines à chaque repas',
                    'icon': 'protein',
                    'category': 'general'
                },
                {
                    'id': '3',
                    'title': 'Légumes',
                    'description': 'Mangez au moins 5 portions de fruits et légumes',
                    'icon': 'vegetables',
                    'category': 'general'
                }
            ]
        
        return success_response({'tips': tips})
        
    except Exception as e:
        return error_response(f'Failed to get nutrition tips: {str(e)}', 500)


@dashboard_bp.route('/recent-activity', methods=['GET'])
def get_recent_activity():
    """Get recent user activity"""
    try:
        user_id = require_current_user()
        db = get_db()
        
        activities = []
        
        # Get recent recipes (last 5)
        recipes_ref = db.collection('users').document(user_id).collection('recipes')
        recipes = recipes_ref.order_by('createdAt', direction='DESCENDING').limit(5).stream()
        
        for recipe in recipes:
            data = recipe.to_dict()
            activities.append({
                'type': 'recipe',
                'title': f"Recette créée: {data.get('name', 'Sans nom')}",
                'timestamp': data.get('createdAt'),
                'icon': 'recipe'
            })
        
        # Get recent fridge additions (last 5)
        fridge_ref = db.collection('users').document(user_id).collection('fridge')
        fridge_items = fridge_ref.order_by('addedAt', direction='DESCENDING').limit(5).stream()
        
        for item in fridge_items:
            data = item.to_dict()
            activities.append({
                'type': 'fridge',
                'title': f"Ingrédient ajouté: {data.get('name', 'Sans nom')}",
                'timestamp': data.get('addedAt'),
                'icon': 'fridge'
            })
        
        # Sort by timestamp
        activities.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        
        return success_response({'activity': activities[:10]})
        
    except Exception as e:
        return error_response(f'Failed to get recent activity: {str(e)}', 500)
