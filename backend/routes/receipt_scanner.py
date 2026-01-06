"""
Receipt Scanner Route
Handles receipt image processing using Ollama Vision model to extract food items
"""
from flask import Blueprint, request
from utils.firebase_connector import get_db
from utils.auth import require_current_user
from utils.response_handler import success_response, error_response
import logging
import base64
import requests
import json
from datetime import datetime, timedelta
from ollama import chat

logger = logging.getLogger(__name__)
receipt_scanner_bp = Blueprint('receipt_scanner', __name__)

# Ollama configuration
OLLAMA_BASE_URL = "http://localhost:11434"
OLLAMA_MODEL = "qwen3-vl:235b-instruct-cloud"  # Using Qwen2.5 VL model for vision tasks

def analyze_receipt_with_ollama(image_base64: str) -> dict:
    """
    Analyze a receipt image using Ollama's vision model.
    
    Args:
        image_base64: Base64 encoded image string
        
    Returns:
        Dictionary with analysis results
    """
    try:
        # Prepare the prompt for the vision model
        prompt = """You are analyzing an image. Please follow these instructions carefully:

1. First, determine if this image is a shopping receipt or not.
2. If it is NOT a receipt, respond with exactly: {"is_receipt": false, "message": "This is not a shopping receipt"}
3. If it IS a receipt, extract ONLY food items that can be used for cooking. 
   
   Food items to include:
   - Fresh produce (fruits, vegetables, potatoes, onions, tomatoes, etc.)
   - Meat and poultry (chicken, beef, pork, etc.)
   - Seafood (fish, shrimp, etc.)
   - Dairy products (milk, cheese, eggs, butter, yogurt, cream)
   - Grains and pasta (rice, pasta, bread, flour, etc.)
   - Canned goods (beans, tomatoes, corn, etc.)
   - Cooking oils and condiments
   - Herbs and spices
   - Legumes and nuts
   
   Items to EXCLUDE:
   - Non-food items (cleaning supplies, toiletries, etc.)
   - Beverages (sodas, alcohol, juice)
   - Snacks and candy
   - Ready-made meals or frozen dinners
   - Pet food
   
4. For each food item found, provide:
   - name: The item name (cleaned up, e.g., "Potatoes" not "RUSSET POT 5LB")
   - quantity: The quantity purchased (default to 1 if not clear)
   - unit: The unit (pieces, kg, g, L, ml, or lb - convert to metric if possible)
   - category: One of: Fruits, Vegetables, Dairy, Meat, Grains, Other

Respond ONLY with valid JSON in this exact format:
{
    "is_receipt": true,
    "items": [
        {"name": "Potatoes", "quantity": 2, "unit": "kg", "category": "Vegetables"},
        {"name": "Onions", "quantity": 1, "unit": "kg", "category": "Vegetables"},
        {"name": "Chicken Breast", "quantity": 500, "unit": "g", "category": "Meat"}
    ]
}

Do not include any text before or after the JSON. Only output valid JSON."""
        response=chat(model="qwen3-vl:235b-instruct-cloud", messages=[{"role": "user", "content": prompt,"images": [image_base64]}])
        response_text=response.message.content
        
        logger.info(f"Ollama response: {response_text[:500]}...")
        
        # Parse the JSON response
        # Try to extract JSON from the response
        try:
            # Remove markdown code blocks if present
            if '```json' in response_text:
                response_text = response_text.split('```json')[1].split('```')[0].strip()
            elif '```' in response_text:
                response_text = response_text.split('```')[1].split('```')[0].strip()
            
            parsed_result = json.loads(response_text)
            return parsed_result
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Ollama response as JSON: {e}")
            logger.error(f"Response was: {response_text}")
            return {
                "is_receipt": False,
                "message": "Could not parse the receipt. Please try with a clearer image."
            }
            
    except requests.exceptions.ConnectionError:
        logger.error("Could not connect to Ollama. Make sure Ollama is running.")
        raise Exception("AI service is not available. Please ensure Ollama is running.")
    except requests.exceptions.Timeout:
        logger.error("Ollama request timed out")
        raise Exception("Request timed out. Please try with a smaller image.")
    except Exception as e:
        logger.error(f"Error analyzing receipt: {e}")
        raise


@receipt_scanner_bp.route('/scan', methods=['POST'])
def scan_receipt():
    """
    Scan a receipt image and extract food items.
    
    Expected request body:
    {
        "image": "base64_encoded_image_string"
    }
    
    Returns:
    {
        "success": true,
        "data": {
            "is_receipt": true,
            "items": [...],
            "items_added": 5
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
        
        logger.info(f"📸 Scanning receipt for user: {user_id}")
        
        # Analyze the receipt with Ollama
        analysis_result = analyze_receipt_with_ollama(image_base64)
        
        if not analysis_result.get('is_receipt', False):
            return success_response({
                'is_receipt': False,
                'message': analysis_result.get('message', 'This image does not appear to be a receipt.'),
                'items': [],
                'items_added': 0
            })
        
        # Get the extracted items
        items = analysis_result.get('items', [])
        
        if not items:
            return success_response({
                'is_receipt': True,
                'message': 'No food items found on this receipt.',
                'items': [],
                'items_added': 0
            })
        
        # Add items to the fridge in Firebase
        items_added = 0
        items_updated = 0
        added_items = []
        
        # Get existing fridge items for this user to check for duplicates
        existing_items_query = db.collection('FridgeItem').where('userId', '==', user_id).stream()
        existing_items = {}
        for doc in existing_items_query:
            item_data = doc.to_dict()
            # Use lowercase name as key for case-insensitive matching
            item_name = item_data.get('ingredientName', '').lower().strip()
            if item_name:
                existing_items[item_name] = {
                    'id': doc.id,
                    'data': item_data
                }
        
        for item in items:
            try:
                # Determine expiration based on category
                category = item.get('category', 'Other')
                if category in ['Meat', 'Dairy']:
                    expiry_days = 5
                elif category in ['Fruits', 'Vegetables']:
                    expiry_days = 7
                else:
                    expiry_days = 14
                
                expiry_date = (datetime.now() + timedelta(days=expiry_days)).strftime('%Y-%m-%d')
                
                item_name = item.get('name', 'Unknown')
                item_name_lower = item_name.lower().strip()
                new_quantity = float(item.get('quantity', 1))
                new_unit = item.get('unit', 'pieces')
                
                # Check if item already exists in fridge
                if item_name_lower in existing_items:
                    # Update existing item - add quantities
                    existing = existing_items[item_name_lower]
                    existing_data = existing['data']
                    existing_quantity = float(existing_data.get('quantity', 0))
                    existing_unit = existing_data.get('unit', 'pieces')
                    
                    # If units match, simply add quantities
                    # If units don't match, we'll still add but keep separate tracking
                    if existing_unit.lower() == new_unit.lower():
                        updated_quantity = existing_quantity + new_quantity
                    else:
                        # Units don't match - add the new quantity anyway
                        # Could implement unit conversion later
                        updated_quantity = existing_quantity + new_quantity
                        new_unit = existing_unit  # Keep the original unit
                    
                    # Update the existing item in Firebase
                    db.collection('FridgeItem').document(existing['id']).update({
                        'quantity': updated_quantity,
                        'notes': f"Updated from receipt scan (was {existing_quantity} {existing_unit})"
                    })
                    
                    updated_item = existing_data.copy()
                    updated_item['id'] = existing['id']
                    updated_item['quantity'] = updated_quantity
                    updated_item['ingredientName'] = existing_data.get('ingredientName', item_name)
                    added_items.append(updated_item)
                    items_updated += 1
                    
                    logger.info(f"📦 Stacked item in fridge: {item_name} (+{new_quantity} = {updated_quantity})")
                    
                else:
                    # Create new item
                    new_item = {
                        'userId': user_id,
                        'ingredientName': item_name,
                        'quantity': new_quantity,
                        'unit': new_unit,
                        'category': category,
                        'location': 'Main fridge',
                        'notes': 'Added from receipt scan',
                        'addedAt': datetime.utcnow(),
                        'expirationDate': expiry_date
                    }
                    
                    _, new_item_ref = db.collection('FridgeItem').add(new_item)
                    
                    created_item = new_item.copy()
                    created_item['id'] = new_item_ref.id
                    added_items.append(created_item)
                    items_added += 1
                    
                    # Add to existing items dict to handle duplicates within same receipt
                    existing_items[item_name_lower] = {
                        'id': new_item_ref.id,
                        'data': new_item
                    }
                    
                    logger.info(f"✅ Added new item to fridge: {item_name}")
                
            except Exception as e:
                logger.error(f"Failed to add item {item.get('name')}: {e}")
                continue
        
        total_processed = items_added + items_updated
        logger.info(f"✅ Successfully processed {total_processed} items ({items_added} new, {items_updated} stacked) from receipt for user {user_id}")
        
        # Build appropriate message
        if items_updated > 0 and items_added > 0:
            message = f'Added {items_added} new items and updated {items_updated} existing items.'
        elif items_updated > 0:
            message = f'Updated {items_updated} existing items with new quantities.'
        else:
            message = f'Successfully added {items_added} new food items from receipt.'
        
        return success_response({
            'is_receipt': True,
            'message': message,
            'items': added_items,
            'items_added': items_added,
            'items_updated': items_updated,
            'total_processed': total_processed
        })
        
    except Exception as e:
        logger.error(f"Error scanning receipt: {e}")
        return error_response(str(e), 500)
