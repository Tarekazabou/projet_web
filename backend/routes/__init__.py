"""
Routes Package
API endpoint blueprints for the Mealy backend
"""
from .ai_recipes import ai_recipes_bp
from .dashboard import dashboard_bp
from .feedback import feedback_bp
from .fridge import fridge_bp
from .grocery import grocery_bp
from .meal_plans import meal_plans_bp
from .nutrition import nutrition_bp
from .settings import settings_bp
from .users import users_bp

__all__ = [
    'ai_recipes_bp',
    'dashboard_bp', 
    'feedback_bp',
    'fridge_bp',
    'grocery_bp',
    'meal_plans_bp',
    'nutrition_bp',
    'settings_bp',
    'users_bp',
]
