"""
AI-powered recipe generation route with RAG
"""
from flask import Blueprint, request, jsonify
from utils.firebase_connector import get_db
from utils.auth import require_current_user
from services.rag_service import RecipeRAGService
from services.ai_service import AIRecipeGenerator
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
ai_recipes_bp = Blueprint('ai_recipes', __name__)

# Initialize services
rag_service = None
ai_generator = None

def initialize_services():
    """Initialize RAG and AI services"""
    global rag_service, ai_generator
    
    if rag_service is None:
        try:
            rag_service = RecipeRAGService()
            logger.info("RAG service initialized")
        except Exception as e:
            logger.error(f"Failed to initialize RAG service: {e}")
    
    if ai_generator is None:
        try:
            ai_generator = AIRecipeGenerator()
            logger.info("AI generator initialized")
        except Exception as e:
            logger.error(f"Failed to initialize AI generator: {e}")

@ai_recipes_bp.route('/generate-with-ai', methods=['POST'])
def generate_recipe_with_ai():
    """
    Generate a new recipe using RAG + AI
    
    Request body:
    {
        "ingredients": ["chicken", "tomatoes", "garlic"],
        "dietary_preferences": ["healthy", "low-carb"],
        "max_cooking_time": 45,
        "difficulty": "medium",
        "servings": 4,
        "save_to_db": true
    }
    """
    try:
        # Initialize services if needed
        initialize_services()
        
        if not rag_service or not ai_generator:
            return jsonify({
                'error': 'AI services not initialized. Check GEMINI_API_KEY.'
            }), 503
        
        # Get request data
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        ingredients = data.get('ingredients', [])
        dietary_preferences = data.get('dietary_preferences', [])
        max_cooking_time = data.get('max_cooking_time')
        difficulty = data.get('difficulty', 'medium')
        servings = data.get('servings', 4)
        save_to_db = data.get('save_to_db', True)
        
        if not ingredients:
            return jsonify({'error': 'At least one ingredient is required'}), 400
        
        logger.info(f"Generating recipe with ingredients: {ingredients}")
        
        # STEP 1: RETRIEVAL - Find similar recipes from 13k dataset
        similar_recipes = rag_service.retrieve_similar_recipes(
            ingredients=ingredients,
            limit=5
        )
        
        if not similar_recipes:
            # Fallback: try keyword search
            logger.info("No ingredient matches, trying keyword search")
            similar_recipes = rag_service.retrieve_by_keywords(
                keywords=ingredients + dietary_preferences,
                limit=3
            )
        
        # STEP 2: AUGMENTATION - Build context prompt
        user_requirements = {
            'ingredients': ingredients,
            'dietary_preferences': dietary_preferences,
            'max_cooking_time': max_cooking_time,
            'difficulty': difficulty,
            'servings': servings
        }
        
        context_prompt = rag_service.build_context_prompt(
            similar_recipes=similar_recipes,
            user_requirements=user_requirements
        )
        
        # STEP 3: GENERATION - Create recipe with AI
        generated_recipe = ai_generator.generate_recipe(
            context_prompt=context_prompt,
            temperature=0.9  # High creativity
        )
        
        # Add metadata
        generated_recipe['createdAt'] = datetime.utcnow()
        generated_recipe['generatedByAI'] = True
        generated_recipe['basedOnRecipes'] = [r['title'] for r in similar_recipes[:3]]
        
        # STEP 4: SAVE to Firestore (optional)
        if save_to_db:
            db = get_db()
            _, recipe_ref = db.collection('Recipe').add(generated_recipe)
            generated_recipe['id'] = recipe_ref.id
            logger.info(f"Saved generated recipe: {recipe_ref.id}")
        
        return jsonify({
            'success': True,
            'recipe': generated_recipe,
            'similar_recipes_found': len(similar_recipes),
            'message': 'Recipe generated successfully with AI!'
        }), 201
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        return jsonify({'error': str(e)}), 400
        
    except Exception as e:
        logger.error(f"Error generating recipe with AI: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Failed to generate recipe: {str(e)}'}), 500

@ai_recipes_bp.route('/generate-simple', methods=['POST'])
def generate_simple_recipe():
    """
    Generate recipe without RAG (simpler, faster)
    """
    try:
        initialize_services()
        
        if not ai_generator:
            return jsonify({'error': 'AI service not initialized'}), 503
        
        data = request.get_json()
        ingredients = data.get('ingredients', [])
        dietary_prefs = data.get('dietary_preferences', [])
        cooking_time = data.get('max_cooking_time')
        
        if not ingredients:
            return jsonify({'error': 'Ingredients required'}), 400
        
        recipe = ai_generator.generate_simple_recipe(
            ingredients=ingredients,
            dietary_prefs=dietary_prefs,
            cooking_time=cooking_time
        )
        
        # Save if requested
        if data.get('save_to_db', True):
            db = get_db()
            recipe['createdAt'] = datetime.utcnow()
            recipe['generatedByAI'] = True
            _, recipe_ref = db.collection('Recipe').add(recipe)
            recipe['id'] = recipe_ref.id
        
        return jsonify({
            'success': True,
            'recipe': recipe
        }), 201
        
    except Exception as e:
        logger.error(f"Error in simple generation: {e}")
        return jsonify({'error': str(e)}), 500

@ai_recipes_bp.route('/test-rag', methods=['POST'])
def test_rag():
    """Test endpoint to check RAG retrieval"""
    try:
        initialize_services()
        
        if not rag_service:
            return jsonify({'error': 'RAG service not initialized'}), 503
        
        data = request.get_json()
        ingredients = data.get('ingredients', ['chicken'])
        
        similar = rag_service.retrieve_similar_recipes(ingredients, limit=3)
        
        return jsonify({
            'success': True,
            'ingredients_searched': ingredients,
            'similar_recipes_found': len(similar),
            'recipes': similar
        }), 200
        
    except Exception as e:
        logger.error(f"Error testing RAG: {e}")
        return jsonify({'error': str(e)}), 500
