"""
Food Scanner Route
Handles food image processing using Ollama Vision model to extract nutrition facts
"""
from flask import Blueprint, request
from utils.firebase_connector import get_db
from utils.auth import require_current_user
from utils.response_handler import success_response, error_response
import logging
import json
from datetime import datetime
from ollama import chat

logger = logging.getLogger(__name__)
food_scanner_bp = Blueprint('food_scanner', __name__)

# Ollama configuration
OLLAMA_MODEL = "qwen3-vl:235b-instruct-cloud"


def analyze_food_with_ollama(image_base64: str) -> dict:
    """
    Analyze a food image using Ollama's vision model to extract nutrition facts.
    
    Args:
        image_base64: Base64 encoded image string
        
    Returns:
        Dictionary with nutrition analysis results
    """
    try:
        prompt = """You are a nutrition expert analyzing a food image. Please follow these instructions carefully:

1. First, determine if this image contains food or a meal.
2. If it is NOT food, respond with exactly: {"is_food": false, "message": "This image does not contain recognizable food"}
3. If it IS food, identify the food items and estimate their nutritional content.

For the food analysis, provide:
- meal_name: A descriptive name for the meal/food (e.g., "Grilled Chicken Salad", "Spaghetti Bolognese")
- food_items: List of individual food items identified in the image
- portion_size: Estimated portion size (small, medium, large, or estimated weight in grams)
- nutrition: Estimated nutritional values per serving:
  - calories: Total calories (kcal)
  - protein: Protein content (g)
  - carbs: Carbohydrates (g)
  - fat: Total fat (g)
  - fiber: Dietary fiber (g)
  - sugar: Sugar content (g)
  - sodium: Sodium (mg)

Important guidelines:
- Be realistic with estimates based on typical serving sizes
- If multiple items are present, provide combined totals
- Consider cooking methods visible (fried, grilled, steamed, etc.)
- Account for visible sauces, dressings, or toppings

Respond ONLY with valid JSON in this exact format:
{
    "is_food": true,
    "meal_name": "Grilled Chicken with Rice and Vegetables",
    "food_items": ["grilled chicken breast", "white rice", "steamed broccoli", "carrots"],
    "portion_size": "medium (approximately 400g)",
    "nutrition": {
        "calories": 520,
        "protein": 42,
        "carbs": 55,
        "fat": 12,
        "fiber": 6,
        "sugar": 4,
        "sodium": 380
    },
    "meal_type_suggestion": "lunch",
    "health_notes": "High protein, balanced meal. Good source of fiber from vegetables."
}

Do not include any text before or after the JSON. Only output valid JSON."""

        response = chat(
            model=OLLAMA_MODEL,
            messages=[{
                "role": "user",
                "content": prompt,
                "images": [image_base64]
            }]
        )
        response_text = response.message.content
        
        logger.info(f"Ollama food analysis response: {response_text[:500]}...")
        
        # Parse the JSON response
        try:
            # Remove markdown code blocks if present
            if '```json' in response_text:
                response_text = response_text.split('```json')[1].split('```')[0].strip()
            elif '```' in response_text:
                response_text = response_text.split('```')[1].split('```')[0].strip()
            
            # Remove thinking tags if present (for models that use them)
            if '<think>' in response_text:
                # Find content after </think> tag
                if '</think>' in response_text:
                    response_text = response_text.split('</think>')[-1].strip()
            
            parsed_result = json.loads(response_text)
            return parsed_result
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Ollama response as JSON: {e}")
            logger.error(f"Response was: {response_text}")
            return {
                "is_food": False,
                "message": "Could not analyze the food. Please try with a clearer image."
            }
            
    except Exception as e:
        logger.error(f"Error analyzing food: {e}")
        raise


@food_scanner_bp.route('/scan', methods=['POST'])
def scan_food():
    """
    Scan a food image and extract nutrition facts.
    
    Expected request body:
    {
        "image": "base64_encoded_image_string",
        "date": "2026-01-05" (optional, defaults to today),
        "meal_type": "breakfast|lunch|dinner|snack" (optional),
        "auto_log": true (optional, if true automatically logs the meal)
    }
    
    Returns:
    {
        "success": true,
        "data": {
            "is_food": true,
            "meal_name": "...",
            "food_items": [...],
            "nutrition": {...},
            "logged": true/false,
            "meal_id": "..." (if logged)
        }
    }
    """
    try:
        user_id = require_current_user()
        db = get_db()
        
        data = request.get_json()
        
        if not data or 'image' not in data:
            return error_response('No image provided', 400)
        
        image_base64 = data['image']
        
        # Remove data URL prefix if present
        if 'base64,' in image_base64:
            image_base64 = image_base64.split('base64,')[1]
        
        logger.info(f"🍽️ Scanning food image for user: {user_id}")
        
        # Analyze the food with Ollama
        analysis_result = analyze_food_with_ollama(image_base64)
        
        if not analysis_result.get('is_food', False):
            return success_response({
                'is_food': False,
                'message': analysis_result.get('message', 'This image does not appear to contain food.'),
                'nutrition': None,
                'logged': False
            })
        
        # Prepare response data
        response_data = {
            'is_food': True,
            'meal_name': analysis_result.get('meal_name', 'Unknown Meal'),
            'food_items': analysis_result.get('food_items', []),
            'portion_size': analysis_result.get('portion_size', 'medium'),
            'nutrition': analysis_result.get('nutrition', {}),
            'meal_type_suggestion': analysis_result.get('meal_type_suggestion', 'other'),
            'health_notes': analysis_result.get('health_notes', ''),
            'logged': False,
            'meal_id': None
        }
        
        # Auto-log the meal if requested
        auto_log = data.get('auto_log', False)
        if auto_log:
            date_str = data.get('date', datetime.now().strftime('%Y-%m-%d'))
            meal_type = data.get('meal_type', analysis_result.get('meal_type_suggestion', 'other'))
            
            user_ref = db.collection('User').document(user_id)
            
            meal_data = {
                'user': user_ref,
                'mealName': response_data['meal_name'],
                'date': date_str,
                'mealType': meal_type,
                'nutrition': response_data['nutrition'],
                'foodItems': response_data['food_items'],
                'portionSize': response_data['portion_size'],
                'healthNotes': response_data['health_notes'],
                'source': 'food_scanner',
                'createdAt': datetime.utcnow()
            }
            
            _, new_log_ref = db.collection('NutritionLog').add(meal_data)
            
            response_data['logged'] = True
            response_data['meal_id'] = new_log_ref.id
            
            logger.info(f"✅ Meal logged successfully: {new_log_ref.id}")
        
        return success_response(response_data)
        
    except Exception as e:
        logger.error(f"Error scanning food: {e}")
        return error_response(str(e), 500)


@food_scanner_bp.route('/log', methods=['POST'])
def log_scanned_food():
    """
    Log a previously scanned food to the nutrition tracker.
    Use this endpoint when auto_log was false during scan.
    
    Expected request body:
    {
        "meal_name": "Grilled Chicken Salad",
        "food_items": ["chicken", "lettuce", "tomatoes"],
        "nutrition": {
            "calories": 350,
            "protein": 35,
            "carbs": 15,
            "fat": 18,
            "fiber": 4
        },
        "date": "2026-01-05",
        "meal_type": "lunch"
    }
    """
    try:
        user_id = require_current_user()
        db = get_db()
        
        data = request.get_json()
        
        if not data:
            return error_response('No data provided', 400)
        
        required_fields = ['meal_name', 'nutrition']
        for field in required_fields:
            if field not in data:
                return error_response(f'Missing required field: {field}', 400)
        
        user_ref = db.collection('User').document(user_id)
        date_str = data.get('date', datetime.now().strftime('%Y-%m-%d'))
        
        meal_data = {
            'user': user_ref,
            'mealName': data['meal_name'],
            'date': date_str,
            'mealType': data.get('meal_type', 'other'),
            'nutrition': data['nutrition'],
            'foodItems': data.get('food_items', []),
            'portionSize': data.get('portion_size', 'medium'),
            'healthNotes': data.get('health_notes', ''),
            'source': 'food_scanner',
            'createdAt': datetime.utcnow()
        }
        
        _, new_log_ref = db.collection('NutritionLog').add(meal_data)
        
        logger.info(f"✅ Scanned food logged for user {user_id}: {new_log_ref.id}")
        
        return success_response({
            'message': 'Meal logged successfully',
            'meal_id': new_log_ref.id,
            'meal_name': data['meal_name'],
            'date': date_str,
            'nutrition': data['nutrition']
        })
        
    except Exception as e:
        logger.error(f"Error logging scanned food: {e}")
        return error_response(str(e), 500)