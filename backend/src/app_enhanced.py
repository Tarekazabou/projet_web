"""
Mealy Backend Application - Enhanced Version
Main Flask application with improved architecture, security, and monitoring
"""
import sys
from pathlib import Path

# Add the backend directory to the Python path
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from flask import Flask, request, jsonify, g
from flask_cors import CORS
from datetime import datetime
import logging
import traceback

# Import configuration
from config import config

# Import utilities
from utils.firebase_connector import initialize_firebase, get_db
from utils.auth import attach_current_user
from utils.response_handler import APIResponse
from utils.logging_config import setup_logging
from utils.middleware import setup_middleware

# Import route modules
from routes.recipes import recipes_bp
from routes.nutrition import nutrition_bp
from routes.meal_plans import meal_plans_bp
from routes.grocery import grocery_bp
from routes.feedback import feedback_bp
from routes.users import users_bp
from routes.fridge import fridge_bp
from routes.ai_recipes import ai_recipes_bp
from routes.settings import settings_bp

# Setup logging first
setup_logging(config)
logger = logging.getLogger(__name__)


def create_app(config_object=None):
    """
    Application factory pattern
    
    Args:
        config_object: Configuration object (defaults to auto-detected config)
    
    Returns:
        Configured Flask application
    """
    if config_object is None:
        config_object = config
    
    # Initialize Flask app
    app = Flask(
        __name__,
        template_folder='../../frontend',
        static_folder='../../frontend',
        static_url_path=''
    )
    
    # Load configuration
    app.config['SECRET_KEY'] = config_object.SECRET_KEY
    app.config['ENV'] = config_object.ENV
    app.config['DEBUG'] = config_object.DEBUG
    app.config['TESTING'] = config_object.TESTING
    
    logger.info(f"Initializing Mealy backend (ENV={config_object.ENV})")
    
    # CORS configuration
    CORS(app, resources={
        r"/api/*": {
            "origins": config_object.CORS_ORIGINS,
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization", "X-Request-ID", "X-User-Id"],
            "supports_credentials": True,
            "max_age": 3600
        }
    })
    logger.info(f"CORS configured for origins: {config_object.CORS_ORIGINS}")
    
    # Initialize Firebase
    try:
        initialize_firebase()
        logger.info("Firebase initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        if config_object.ENV == 'production':
            raise
    
    # Setup middleware
    setup_middleware(app, config_object)
    
    # Register blueprints
    register_blueprints(app)
    
    # Register error handlers
    register_error_handlers(app)
    
    # Register request hooks
    register_request_hooks(app)
    
    # Register API routes
    register_api_routes(app)
    
    # Register frontend routes (if serving frontend)
    register_frontend_routes(app)
    
    logger.info("Application initialization complete")
    
    return app


def register_blueprints(app: Flask) -> None:
    """Register all Flask blueprints"""
    blueprints = [
        (recipes_bp, '/api/recipes'),
        (nutrition_bp, '/api/nutrition'),
        (meal_plans_bp, '/api/meal-plans'),
        (grocery_bp, '/api/grocery-lists'),
        (feedback_bp, '/api/feedback'),
        (users_bp, '/api/users'),
        (fridge_bp, '/api/fridge'),
        (ai_recipes_bp, '/api/recipes'),
        (settings_bp, '/api/settings'),
    ]
    
    for blueprint, url_prefix in blueprints:
        app.register_blueprint(blueprint, url_prefix=url_prefix)
        logger.debug(f"Registered blueprint: {blueprint.name} at {url_prefix}")


def register_error_handlers(app: Flask) -> None:
    """Register error handlers for common HTTP errors"""
    
    @app.errorhandler(400)
    def bad_request(error):
        """Handle 400 Bad Request errors"""
        return APIResponse.error(
            str(error.description) if hasattr(error, 'description') else "Bad request",
            400,
            'BAD_REQUEST'
        )
    
    @app.errorhandler(401)
    def unauthorized(error):
        """Handle 401 Unauthorized errors"""
        return APIResponse.unauthorized(
            str(error.description) if hasattr(error, 'description') else "Unauthorized"
        )
    
    @app.errorhandler(403)
    def forbidden(error):
        """Handle 403 Forbidden errors"""
        return APIResponse.forbidden(
            str(error.description) if hasattr(error, 'description') else "Forbidden"
        )
    
    @app.errorhandler(404)
    def not_found(error):
        """Handle 404 Not Found errors"""
        return APIResponse.not_found(
            "Resource" if not hasattr(error, 'description') else str(error.description)
        )
    
    @app.errorhandler(422)
    def unprocessable_entity(error):
        """Handle 422 Unprocessable Entity errors"""
        return APIResponse.validation_error(
            str(error.description) if hasattr(error, 'description') else "Validation failed"
        )
    
    @app.errorhandler(500)
    def internal_server_error(error):
        """Handle 500 Internal Server Error"""
        logger.error(f"Internal server error: {error}", exc_info=True)
        
        # In production, don't expose internal error details
        if config.ENV == 'production':
            return APIResponse.internal_error("An unexpected error occurred")
        else:
            return APIResponse.internal_error(
                f"Internal server error: {str(error)}",
                error_id=getattr(g, 'request_id', None)
            )
    
    @app.errorhandler(Exception)
    def handle_unexpected_error(error):
        """Handle any unexpected exceptions"""
        logger.error(
            f"Unexpected error: {type(error).__name__}: {str(error)}",
            exc_info=True,
            extra={
                'request_id': getattr(g, 'request_id', None),
                'traceback': traceback.format_exc()
            }
        )
        
        if config.ENV == 'production':
            return APIResponse.internal_error("An unexpected error occurred")
        else:
            return APIResponse.internal_error(
                f"{type(error).__name__}: {str(error)}",
                error_id=getattr(g, 'request_id', None)
            )


def register_request_hooks(app: Flask) -> None:
    """Register before/after request hooks"""
    
    @app.before_request
    def load_authenticated_user():
        """Attach the current user to the request context"""
        try:
            attach_current_user()
        except Exception as e:
            logger.error(f"Error loading authenticated user: {e}")
            # Continue without user context in demo mode
            if config.DEMO_MODE_ENABLED:
                g.current_user = None
                g.current_user_id = None
    
    @app.after_request
    def inject_user_header(response):
        """Add user ID to response headers for client tracking"""
        if hasattr(g, 'current_user_id') and g.current_user_id:
            response.headers['X-User-Id'] = g.current_user_id
        return response
    
    @app.after_request
    def add_cache_headers(response):
        """Add appropriate cache headers"""
        # Don't cache API responses by default
        if request.path.startswith('/api/'):
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
            response.headers['Pragma'] = 'no-cache'
            response.headers['Expires'] = '0'
        return response


def register_api_routes(app: Flask) -> None:
    """Register core API routes"""
    
    @app.route('/api/health', methods=['GET'])
    def health_check():
        """
        Health check endpoint for monitoring
        GET /api/health
        """
        try:
            # Test database connection
            db = get_db()
            collections = db.collections()
            list(collections)  # Trigger API call
            db_status = "connected"
            db_healthy = True
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            db_status = "disconnected"
            db_healthy = False
        
        # Check AI service availability
        ai_available = bool(config.GEMINI_API_KEY)
        
        # Overall health status
        is_healthy = db_healthy and ai_available
        
        health_data = {
            'status': 'healthy' if is_healthy else 'degraded',
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'version': '2.0.0',
            'environment': config.ENV,
            'services': {
                'database': {
                    'status': db_status,
                    'healthy': db_healthy
                },
                'ai': {
                    'available': ai_available,
                    'model': config.GEMINI_MODEL if ai_available else None
                }
            }
        }
        
        status_code = 200 if is_healthy else 503
        return jsonify(health_data), status_code
    
    @app.route('/api/info', methods=['GET'])
    def api_info():
        """
        API information endpoint
        GET /api/info
        """
        return APIResponse.success({
            'name': 'Mealy API',
            'version': '2.0.0',
            'description': 'AI-powered recipe and meal planning platform',
            'environment': config.ENV,
            'endpoints': {
                'recipes': '/api/recipes',
                'ai_recipes': '/api/recipes/generate-with-ai',
                'meal_plans': '/api/meal-plans',
                'nutrition': '/api/nutrition',
                'grocery_lists': '/api/grocery-lists',
                'fridge': '/api/fridge',
                'users': '/api/users',
                'health': '/api/health'
            },
            'documentation': 'https://github.com/Tarekazabou/projet_web'
        })


def register_frontend_routes(app: Flask) -> None:
    """Register frontend serving routes"""
    
    @app.route('/')
    def index():
        """Serve the main application page"""
        from flask import render_template
        return render_template('index.html')
    
    @app.route('/recipe-generator')
    def recipe_generator_page():
        """Serve the recipe generator page"""
        from flask import render_template
        return render_template('recipe-generator.html')
    
    @app.route('/meal-planner')
    def meal_planner_page():
        """Serve the meal planner page"""
        from flask import render_template
        return render_template('meal-planner.html')
    
    @app.route('/nutrition-tracker')
    def nutrition_tracker_page():
        """Serve the nutrition tracker page"""
        from flask import render_template
        return render_template('nutrition-tracker.html')
    
    @app.route('/grocery-list')
    def grocery_list_page():
        """Serve the grocery list page"""
        from flask import render_template
        return render_template('grocery-list.html')
    
    @app.route('/your-fridge')
    def your_fridge_page():
        """Serve the your fridge page"""
        from flask import render_template
        return render_template('your-fridge.html')


# Create application instance
app = create_app()


if __name__ == '__main__':
    """Run the development server"""
    logger.info(f"Starting Mealy backend server on {config.HOST}:{config.PORT}")
    logger.info(f"Environment: {config.ENV}")
    logger.info(f"Debug mode: {config.DEBUG}")
    
    # Run the application
    app.run(
        host=config.HOST,
        port=config.PORT,
        debug=config.DEBUG,
        use_reloader=config.DEBUG,
        reloader_type='stat' if sys.platform == 'win32' else 'auto'  # More stable on Windows
    )
