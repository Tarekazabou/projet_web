from flask import Flask, request, jsonify, render_template, send_file
from flask_cors import CORS
from flask_pymongo import PyMongo
from dotenv import load_dotenv
import os
from datetime import datetime
import logging

# Import route modules
from backend.routes.recipes import recipes_bp
from backend.routes.nutrition import nutrition_bp
from backend.routes.meal_plans import meal_plans_bp
from backend.routes.grocery import grocery_bp
from backend.routes.feedback import feedback_bp
from backend.routes.users import users_bp
from backend.routes.fridge import fridge_bp

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__, template_folder='frontend', static_folder='frontend')
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

# CORS configuration
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:3000", "http://localhost:5000"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

# MongoDB configuration
app.config["MONGO_URI"] = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/recipe_meal_planner')
mongo = PyMongo(app)

# Make mongo accessible to blueprints
app.mongo = mongo

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Register blueprints
app.register_blueprint(recipes_bp, url_prefix='/api/recipes')
app.register_blueprint(nutrition_bp, url_prefix='/api/nutrition')
app.register_blueprint(meal_plans_bp, url_prefix='/api/meal-plans')
app.register_blueprint(grocery_bp, url_prefix='/api/grocery')
app.register_blueprint(feedback_bp, url_prefix='/api/feedback')
app.register_blueprint(users_bp, url_prefix='/api/users')
app.register_blueprint(fridge_bp, url_prefix='/api/fridge')

@app.route('/')
def index():
    """Serve the main application page"""
    return render_template('index.html')

@app.route('/recipe-generator')
def recipe_generator():
    """Serve the recipe generator page"""
    return render_template('recipe_generator.html')

@app.route('/meal-planner')
def meal_planner():
    """Serve the meal planner page"""
    return render_template('meal_planner.html')

@app.route('/nutrition-tracker')
def nutrition_tracker():
    """Serve the nutrition tracker page"""
    return render_template('nutrition_tracker.html')

@app.route('/grocery-list')
def grocery_list():
    """Serve the grocery list page"""
    return render_template('grocery_list.html')

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        mongo.db.command('ismaster')
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
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    logger.error(f"Internal server error: {error}")
    return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(400)
def bad_request(error):
    """Handle 400 errors"""
    return jsonify({'error': 'Bad request'}), 400

if __name__ == '__main__':
    # Initialize database collections on startup
    from backend.utils.db_init import initialize_database
    
    try:
        initialize_database(mongo)
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
    
    # Run the application
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug
    )