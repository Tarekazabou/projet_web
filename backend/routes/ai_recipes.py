"""
AI-powered recipe generation routes
Accessible from all pages without authentication
"""
from flask import Blueprint, request, jsonify, g
from utils.firebase_connector import get_db
from utils.auth import get_current_user_id
from services.ai_service import AIRecipeGenerator
from utils.response_handler import success_response, error_response
import logging
from datetime import datetime
from google.cloud.firestore_v1.base_query import FieldFilter

logger = logging.getLogger(__name__)
ai_recipes_bp = Blueprint('ai_recipes', __name__)

# Initialize services
ai_generator = None

def initialize_services():
    """Initialize AI services"""
    global ai_generator
    
    if ai_generator is None:
        try:
            ai_generator = AIRecipeGenerator()
            logger.info("✅ AI generator initialized")
        except Exception as e:
            logger.error(f"❌ Failed to initialize AI generator: {e}")

def get_user_id():
    """Get user ID from request context"""
    user_id = get_current_user_id()
    if not user_id:
        # Return None if no user is authenticated
        return None
    return user_id

def _build_direct_prompt(user_query, user_requirements):
    """Build a direct AI prompt for recipe generation"""
    prompt_parts = []
    
    prompt_parts.append("You are a creative and experienced chef AI assistant.")
    prompt_parts.append("Create an original, delicious recipe based on the following requirements:")
    
    if user_query:
        prompt_parts.append(f"\nUser's request: {user_query}")
    
    prompt_parts.append("\nRequirements:")
    
    ingredients = user_requirements.get('ingredients', [])
    if ingredients:
        prompt_parts.append(f"- Main ingredients to use: {', '.join(ingredients)}")
    
    dietary_prefs = user_requirements.get('dietary_preferences', [])
    if dietary_prefs:
        prompt_parts.append(f"- Dietary preferences: {', '.join(dietary_prefs)}")
    
    cuisines = user_requirements.get('preferred_cuisines', [])
    if cuisines:
        prompt_parts.append(f"- Preferred cuisines: {', '.join(cuisines)}")
    
    max_time = user_requirements.get('max_cooking_time')
    if max_time:
        prompt_parts.append(f"- Maximum cooking time: {max_time} minutes")
    
    difficulty = user_requirements.get('difficulty')
    if difficulty:
        prompt_parts.append(f"- Difficulty level: {difficulty}")
    
    servings = user_requirements.get('servings')
    if servings:
        prompt_parts.append(f"- Number of servings: {servings}")
    
    prompt_parts.append("\nGuidelines:")
    prompt_parts.append("- Create an appetizing, well-balanced recipe")
    prompt_parts.append("- Provide clear, step-by-step instructions")
    prompt_parts.append("- Include realistic cooking and prep times")
    prompt_parts.append("- Estimate nutrition information per serving")
    prompt_parts.append("- Make it practical and achievable")
    
    return "\n".join(prompt_parts)

@ai_recipes_bp.route('/generate-with-ai', methods=['POST', 'OPTIONS'])
def generate_recipe_with_ai():
    """
    🚀 UNIVERSAL AI RECIPE GENERATOR - Works from ANY page
    
    Generate recipes using RAG + AI with flexible inputs.
    NO AUTH REQUIRED - accessible from all pages.
    
    Request body (all fields optional):
    {
        "query": "I want a healthy pasta dish",
        "ingredients": ["chicken", "tomatoes", "garlic"],
        "dietary_preferences": ["healthy", "low-carb"],
        "preferred_cuisines": ["italian", "mediterranean"],
        "max_cooking_time": 45,
        "difficulty": "medium",
        "servings": 4,
        "cooking_skill": "medium",
        "use_fridge": false,  // If true, fetch ingredients from user's fridge
        "use_preferences": false,  // If true, fetch user preferences from DB
        "save_to_db": true,
        "userId": "optional_user_id"  // Optional user ID override
    }
    
    Returns:
    {
        "success": true,
        "data": {
            "recipe": {...},
            "generation_context": {...}
        }
    }
    """
    try:
        # Handle OPTIONS preflight
        if request.method == 'OPTIONS':
            return success_response({'message': 'CORS preflight successful'})
        
        # Initialize services if needed
        initialize_services()
        
        if not ai_generator:
            return error_response('AI services not initialized. Check GEMINI_API_KEY in backend/.env', 503)
        
        # Get request data
        data = request.get_json() or {}
        
        # Get user ID (from request or use demo)
        user_id = data.get('userId') or get_user_id()
        
        # Extract parameters with defaults
        user_query = data.get('query', '')
        ingredients = data.get('ingredients', [])
        dietary_preferences = data.get('dietary_preferences', [])
        preferred_cuisines = data.get('preferred_cuisines', [])
        max_cooking_time = data.get('max_cooking_time')
        difficulty = data.get('difficulty', 'medium')
        cooking_skill = data.get('cooking_skill', 'medium')
        servings = data.get('servings', 4)
        save_to_db = data.get('save_to_db', True)
        use_fridge = data.get('use_fridge', False)
        use_preferences = data.get('use_preferences', False)
        
        db = get_db()
        
        # OPTIONAL: Fetch user preferences from database
        if use_preferences:
            try:
                user_doc = db.collection('User').document(user_id).get()
                if user_doc.exists:
                    user_data = user_doc.to_dict()
                    dietary_preferences = dietary_preferences or user_data.get('dietaryPreferences', [])
                    preferred_cuisines = preferred_cuisines or user_data.get('preferredCuisines', [])
                    cooking_skill = cooking_skill or user_data.get('cookingSkill', 'medium')
                    max_cooking_time = max_cooking_time or user_data.get('maxCookingTime', 60)
                    servings = servings or user_data.get('defaultServings', 4)
                    logger.info(f"📝 Loaded preferences for user {user_id}")
            except Exception as e:
                logger.warning(f"Could not load user preferences: {e}")
        
        # OPTIONAL: Fetch ingredients from user's fridge
        if use_fridge:
            try:
                fridge_query = db.collection('FridgeItem').where(
                    filter=FieldFilter('userId', '==', user_id)
                )
                fridge_docs = fridge_query.stream()
                
                fridge_ingredients = []
                for doc in fridge_docs:
                    item = doc.to_dict()
                    ingredient_name = item.get('ingredientName')
                    if ingredient_name:
                        fridge_ingredients.append(ingredient_name)
                
                if fridge_ingredients:
                    ingredients = ingredients or fridge_ingredients
                    logger.info(f"🍳 Using {len(fridge_ingredients)} ingredients from fridge")
            except Exception as e:
                logger.warning(f"Could not load fridge ingredients: {e}")
        
        # Validate: Need at least a query OR ingredients
        if not user_query and not ingredients:
            return error_response('Provide either a query or at least one ingredient', 400)
        
        logger.info(f"🎯 Generating recipe - Query: '{user_query}', Ingredients: {ingredients}, User: {user_id}")
        
        # Build user requirements
        user_requirements = {
            'ingredients': ingredients,
            'dietary_preferences': dietary_preferences,
            'preferred_cuisines': preferred_cuisines,
            'max_cooking_time': max_cooking_time,
            'difficulty': difficulty,
            'cooking_skill': cooking_skill,
            'servings': servings
        }

        logger.info("🤖 Using direct AI generation")
        
        # BUILD PROMPT
        context_prompt = _build_direct_prompt(user_query, user_requirements)
        
        # GENERATION - Create recipe with AI
        generated_recipe = ai_generator.generate_recipe(
            context_prompt=context_prompt,
            temperature=0.9  # High creativity
        )
        
        # Add comprehensive metadata
        generated_recipe['createdAt'] = datetime.utcnow()
        generated_recipe['generatedByAI'] = True
        generated_recipe['userId'] = user_id
        generated_recipe['generationContext'] = {
            'usedFridge': use_fridge,
            'usedPreferences': use_preferences,
            'ingredientsProvided': len(ingredients),
            'preferencesApplied': len(dietary_preferences) + len(preferred_cuisines)
        }
        if user_query:
            generated_recipe['userQuery'] = user_query
        
        # SAVE to Firestore (optional)
        if save_to_db:
            _, recipe_ref = db.collection('Recipe').add(generated_recipe)
            generated_recipe['id'] = recipe_ref.id
            logger.info(f"💾 Saved generated recipe: {recipe_ref.id}")
        
        return success_response({
            'recipe': generated_recipe,
            'generation_context': {
                'user_id': user_id,
                'used_fridge': use_fridge,
                'used_preferences': use_preferences,
                'ingredients_count': len(ingredients)
            },
            'message': 'Recipe generated successfully with AI! 🎉'
        }, 201)
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        return error_response(str(e), 400)
        
    except Exception as e:
        logger.error(f"Error generating recipe with AI: {e}")
        import traceback
        traceback.print_exc()
        return error_response(f'Failed to generate recipe: {str(e)}', 500)

@ai_recipes_bp.route('/generate-simple', methods=['POST', 'OPTIONS'])
def generate_simple_recipe():
    """
    ⚡ FAST AI RECIPE GENERATOR - No RAG, instant results
    
    Generate recipes quickly without semantic search.
    Perfect for simple, quick recipe generation.
    NO AUTH REQUIRED - accessible from all pages.
    
    Request body:
    {
        "ingredients": ["chicken", "rice", "vegetables"],  // Required
        "dietary_preferences": ["healthy"],
        "max_cooking_time": 30,
        "servings": 4,
        "difficulty": "easy",
        "save_to_db": true,
        "userId": "optional_user_id"
    }
    
    Returns: Instant recipe without semantic search
    """
    try:
        # Handle OPTIONS preflight
        if request.method == 'OPTIONS':
            return success_response({'message': 'CORS preflight successful'})
        
        initialize_services()
        
        if not ai_generator:
            return error_response('AI service not initialized', 503)
        
        data = request.get_json() or {}
        
        # Get user ID
        user_id = data.get('userId') or get_user_id()
        
        ingredients = data.get('ingredients', [])
        dietary_prefs = data.get('dietary_preferences', [])
        cooking_time = data.get('max_cooking_time')
        servings = data.get('servings', 4)
        difficulty = data.get('difficulty', 'easy')
        
        if not ingredients:
            return error_response('At least one ingredient is required', 400)
        
        logger.info(f"⚡ Fast generating recipe with {len(ingredients)} ingredients for user {user_id}")
        
        recipe = ai_generator.generate_simple_recipe(
            ingredients=ingredients,
            dietary_prefs=dietary_prefs,
            cooking_time=cooking_time
        )
        
        # Add metadata
        recipe['createdAt'] = datetime.utcnow()
        recipe['generatedByAI'] = True
        recipe['userId'] = user_id
        recipe['generationType'] = 'simple'
        recipe['servings'] = servings
        recipe['difficulty'] = difficulty
        
        # Save if requested
        if data.get('save_to_db', True):
            db = get_db()
            _, recipe_ref = db.collection('Recipe').add(recipe)
            recipe['id'] = recipe_ref.id
            logger.info(f"💾 Saved simple recipe: {recipe_ref.id}")
        
        return success_response({
            'recipe': recipe,
            'message': 'Simple recipe generated quickly! ⚡'
        }, 201)
        
    except Exception as e:
        logger.error(f"Error in simple generation: {e}")
        return error_response(f'Failed to generate simple recipe: {str(e)}', 500)

@ai_recipes_bp.route('/test-rag', methods=['POST', 'GET', 'OPTIONS'])
def test_rag():
    """
    🧪 TEST RAG SERVICE - Debug and verify RAG functionality
    
    Test the Recipe Retrieval-Augmented Generation service.
    Returns similar recipes without generating new ones.
    NO AUTH REQUIRED - accessible for testing from any page.
    
    GET request: Uses default ingredients (chicken, tomatoes, garlic)
    POST request body (optional):
    {
        "ingredients": ["chicken", "rice"],
        "query": "healthy pasta dish",
        "limit": 5
    }
    
    Returns: Similar recipes found in the 13k recipe database
    """
    try:
        # Handle OPTIONS preflight
        if request.method == 'OPTIONS':
            return success_response({'message': 'CORS preflight successful'})
        
        return success_response({
            'message': 'RAG service has been removed. System now uses direct AI generation for better performance.',
            'status': 'disabled',
            'alternative': 'Use /generate-with-ai or /generate-simple for recipe generation'
        })
        
    except Exception as e:
        logger.error(f"Error: {e}")
        return error_response(str(e), 500)

@ai_recipes_bp.route('/generate-from-text', methods=['POST', 'OPTIONS'])
def generate_from_text():
    """
    📝 GENERATE FROM TEXT - Natural language recipe generation
    
    Generate recipes from natural language descriptions.
    Perfect for the Recipe Generator page.
    NO AUTH REQUIRED - accessible from all pages.
    
    Request body:
    {
        "query": "I want a healthy Italian pasta with chicken and vegetables",  // Required
        "save_to_db": true,
        "userId": "optional_user_id"
    }
    
    Returns: AI-generated recipe based on the text description
    """
    try:
        if request.method == 'OPTIONS':
            return success_response({'message': 'CORS preflight successful'})
        
        initialize_services()
        
        if not ai_generator:
            return error_response('AI service not initialized', 503)
        
        data = request.get_json() or {}
        query = data.get('query', '').strip()
        
        if not query:
            return error_response('Query text is required', 400)
        
        user_id = data.get('userId') or get_user_id()
        save_to_db = data.get('save_to_db', True)
        
        logger.info(f"📝 Generating recipe from text: '{query}' for user {user_id}")
        
        # Use the universal endpoint with query only
        return generate_recipe_with_ai()
        
    except Exception as e:
        logger.error(f"Error generating from text: {e}")
        return error_response(f'Failed to generate recipe: {str(e)}', 500)

@ai_recipes_bp.route('/generate-from-ingredients', methods=['POST', 'OPTIONS'])
def generate_from_ingredients():
    """
    🥗 GENERATE FROM INGREDIENTS - Ingredient-focused recipe generation
    
    Generate recipes from a list of ingredients.
    Perfect for "What can I make with these?" scenarios.
    NO AUTH REQUIRED - accessible from all pages.
    
    Request body:
    {
        "ingredients": ["chicken", "rice", "broccoli"],  // Required
        "dietary_preferences": ["healthy"],
        "max_cooking_time": 30,
        "servings": 4,
        "save_to_db": true,
        "userId": "optional_user_id"
    }
    
    Returns: AI-generated recipe using the specified ingredients
    """
    try:
        if request.method == 'OPTIONS':
            return success_response({'message': 'CORS preflight successful'})
        
        data = request.get_json() or {}
        ingredients = data.get('ingredients', [])
        
        if not ingredients:
            return error_response('At least one ingredient is required', 400)
        
        # Use the universal endpoint
        return generate_recipe_with_ai()
        
    except Exception as e:
        logger.error(f"Error generating from ingredients: {e}")
        return error_response(f'Failed to generate recipe: {str(e)}', 500)

@ai_recipes_bp.route('/generate-from-fridge', methods=['POST', 'OPTIONS'])
def generate_from_fridge():
    """
    🍳 GENERATE FROM FRIDGE - Use user's fridge ingredients
    
    Generate recipes using ingredients from the user's fridge.
    Automatically fetches user preferences and fridge items.
    NO AUTH REQUIRED - uses demo user if not authenticated.
    
    Request body (all optional):
    {
        "additional_ingredients": ["pasta"],  // Extra ingredients to add
        "userId": "optional_user_id",
        "save_to_db": true
    }
    
    Returns: AI-generated recipe using fridge ingredients + preferences
    """
    try:
        if request.method == 'OPTIONS':
            return success_response({'message': 'CORS preflight successful'})
        
        data = request.get_json() or {}
        
        # Set flags to use fridge and preferences
        data['use_fridge'] = True
        data['use_preferences'] = True
        
        # Merge additional ingredients if provided
        additional = data.get('additional_ingredients', [])
        if additional:
            data['ingredients'] = additional
        
        logger.info(f"🍳 Generating recipe from fridge with {len(additional)} additional ingredients")
        
        # Use the universal endpoint with fridge mode
        return generate_recipe_with_ai()
        
    except Exception as e:
        logger.error(f"Error generating from fridge: {e}")
        return error_response(f'Failed to generate recipe: {str(e)}', 500)

@ai_recipes_bp.route('/list', methods=['GET'])
def list_recipes():
    """
    📋 LIST RECIPES - Get all AI-generated recipes
    
    Retrieve AI-generated recipes from Firestore with pagination and filtering.
    NO AUTH REQUIRED.
    
    Query parameters:
    - sort_by: Field to sort by (default: createdAt)
    - per_page: Results per page (default: 20)
    - page: Page number (default: 1)
    - user_id: Filter by user ID (optional)
    
    Returns: List of recipes with pagination info
    """
    try:
        db = get_db()
        
        # Get query parameters
        sort_by = request.args.get('sort_by', 'createdAt')
        per_page = min(int(request.args.get('per_page', 20)), 100)
        page = int(request.args.get('page', 1))
        user_id_filter = request.args.get('user_id')
        
        # Build query
        query = db.collection('Recipe')
        
        # Filter by user if specified
        if user_id_filter:
            query = query.where(filter=FieldFilter('userId', '==', user_id_filter))
        
        # Sort by specified field
        query = query.order_by(sort_by, direction='DESCENDING')
        
        # Apply pagination
        query = query.limit(per_page)
        
        # Execute query
        docs = query.stream()
        
        recipes = []
        for doc in docs:
            recipe = doc.to_dict()
            recipe['id'] = doc.id
            
            # Convert datetime to string if present
            if 'createdAt' in recipe and hasattr(recipe['createdAt'], 'isoformat'):
                recipe['createdAt'] = recipe['createdAt'].isoformat()
            
            recipes.append(recipe)
        
        logger.info(f"📋 Listed {len(recipes)} recipes (page {page}, {per_page} per page)")
        
        return success_response({
            'recipes': recipes,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'count': len(recipes)
            }
        })
        
    except Exception as e:
        logger.error(f"Error listing recipes: {e}")
        return error_response('Failed to list recipes', 500)

@ai_recipes_bp.route('/<recipe_id>', methods=['GET'])
def get_recipe_by_id(recipe_id):
    """
    🔍 GET RECIPE - Get a specific recipe by ID
    
    Retrieve a single recipe from Firestore.
    NO AUTH REQUIRED.
    
    Returns: Recipe details
    """
    try:
        db = get_db()
        doc = db.collection('Recipe').document(recipe_id).get()
        
        if not doc.exists:
            return error_response('Recipe not found', 404)
        
        recipe = doc.to_dict()
        recipe['id'] = doc.id
        
        # Convert datetime to string if present
        if 'createdAt' in recipe and hasattr(recipe['createdAt'], 'isoformat'):
            recipe['createdAt'] = recipe['createdAt'].isoformat()
        
        logger.info(f"🔍 Retrieved recipe: {recipe.get('title', 'Unknown')}")
        
        return success_response({'recipe': recipe})
        
    except Exception as e:
        logger.error(f"Error getting recipe: {e}")
        return error_response('Failed to get recipe', 500)

@ai_recipes_bp.route('/status', methods=['GET'])
def ai_service_status():
    """
    ℹ️ AI SERVICE STATUS - Check if AI services are operational
    
    Check the status of AI services (RAG and Gemini).
    Useful for debugging and health checks.
    NO AUTH REQUIRED.
    
    Returns: Status of all AI services
    """
    try:
        initialize_services()
        
        from config import config
        
        status = {
            'ai_generator': 'operational ✅' if ai_generator else 'not initialized ❌',
            'gemini_api_key': 'configured ✅' if config.GEMINI_API_KEY else 'missing ❌',
            'mode': 'direct AI generation (no dataset required)'
        }
        
        all_operational = '❌' not in str(status['ai_generator']) and '❌' not in str(status['gemini_api_key'])
        
        status['overall_status'] = 'all systems operational ✅' if all_operational else 'some services unavailable ⚠️'
        
        return success_response({
            'status': status,
            'message': status['overall_status'],
            'available_endpoints': [
                '/api/recipes/list',
                '/api/recipes/<recipe_id>',
                '/api/recipes/generate-with-ai',
                '/api/recipes/generate-simple',
                '/api/recipes/generate-from-text',
                '/api/recipes/generate-from-ingredients',
                '/api/recipes/generate-from-fridge',
                '/api/recipes/test-rag',
                '/api/recipes/status'
            ]
        })
        
    except Exception as e:
        logger.error(f"Error checking status: {e}")
        return error_response(f'Failed to check status: {str(e)}', 500)
