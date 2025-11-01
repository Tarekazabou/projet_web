import sys
from pathlib import Path

# Add the backend directory to the Python path
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from flask import Flask, request, jsonify, render_template, send_file, g
from flask_cors import CORS
from utils.firebase_connector import initialize_firebase, get_db
from dotenv import load_dotenv
import os
from datetime import datetime
import logging

# Import route modules
from routes.nutrition import nutrition_bp
from routes.meal_plans import meal_plans_bp
from routes.grocery import grocery_bp
from routes.feedback import feedback_bp
from routes.users import users_bp
from routes.fridge import fridge_bp
from routes.ai_recipes import ai_recipes_bp
from routes.settings import settings_bp
from utils.auth import attach_current_user

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(
    __name__,
    template_folder='../../frontend',
    static_folder='../../frontend',
    static_url_path=''
)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

# CORS configuration
allowed_origins = os.getenv('CORS_ORIGINS', 'http://localhost:3000,http://localhost:5000').split(',')

CORS(app, resources={
    r"/api/*": {
        "origins": allowed_origins,
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"],
        "supports_credentials": True
    }
})

# Initialize Firebase
initialize_firebase()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Register blueprints - AI Recipes only (no CRUD)
app.register_blueprint(ai_recipes_bp, url_prefix='/api/recipes')
app.register_blueprint(nutrition_bp, url_prefix='/api/nutrition')
app.register_blueprint(meal_plans_bp, url_prefix='/api/meal-plans')
app.register_blueprint(grocery_bp, url_prefix='/api/grocery-lists')
app.register_blueprint(feedback_bp, url_prefix='/api/feedback')
app.register_blueprint(users_bp, url_prefix='/api/users')
app.register_blueprint(fridge_bp, url_prefix='/api/fridge')
app.register_blueprint(settings_bp, url_prefix='/api/settings')

@app.before_request
def load_authenticated_user():
    """Attach the current user to the request context."""
    attach_current_user()


@app.after_request
def inject_user_header(response):
    """Surface the resolved user id to the client for subsequent requests."""
    if hasattr(g, 'current_user_id'):
        response.headers['X-User-Id'] = g.current_user_id
    return response

@app.route('/')
def index():
    """Serve the main application page"""
    return render_template('index.html')

@app.route('/recipe-generator')
def recipe_generator_page():
    """Serve the recipe generator page"""
    return render_template('recipe-generator.html')

@app.route('/meal-planner')
def meal_planner_page():
    """Serve the meal planner page"""
    return render_template('meal-planner.html')

@app.route('/nutrition-tracker')
def nutrition_tracker_page():
    """Serve the nutrition tracker page"""
    return render_template('nutrition-tracker.html')

@app.route('/grocery-list')
def grocery_list_page():
    """Serve the grocery list page"""
    return render_template('grocery-list.html')

@app.route('/your-fridge')
def your_fridge_page():
    """Serve the your fridge page"""
    return render_template('your-fridge.html')

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    try:
        # Test database connection by listing collections
        db = get_db()
        collections = db.collections()
        list(collections) # Consume the iterator to actually trigger the API call
        db_status = "connected"
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        db_status = "disconnected"
    
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'database': db_status,
        'version': '1.0.0'
    })

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({'error': 'Endpoint not found', 'message': str(error)}), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error(f"Internal server error: {error}")
    return jsonify({'error': 'Internal server error', 'message': str(error)}), 500

@app.errorhandler(400)
def bad_request(error):
    """Handle 400 errors"""
    return jsonify({'error': 'Bad request', 'message': str(error)}), 400

if __name__ == '__main__':
    # Run the application
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    
    # Fix for Windows socket error on reload
    # Use 'stat' reloader instead of 'watchdog' to avoid socket issues
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug,
        use_reloader=debug,
        reloader_type='stat'  # More stable on Windows
    )