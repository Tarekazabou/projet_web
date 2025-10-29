"""
Settings management endpoints for API keys and configuration
"""
from flask import Blueprint, request, jsonify
import os
import logging
from pathlib import Path
import google.generativeai as genai

logger = logging.getLogger(__name__)
settings_bp = Blueprint('settings', __name__)

# Path to .env file
ENV_FILE = Path(__file__).parent.parent / '.env'

def update_env_file(key: str, value: str):
    """Update or add a key-value pair in .env file"""
    env_lines = []
    key_found = False
    
    # Read existing .env if it exists
    if ENV_FILE.exists():
        with open(ENV_FILE, 'r') as f:
            env_lines = f.readlines()
    
    # Update existing key or mark for addition
    new_lines = []
    for line in env_lines:
        if line.strip().startswith(f'{key}='):
            new_lines.append(f'{key}={value}\n')
            key_found = True
        else:
            new_lines.append(line)
    
    # Add new key if not found
    if not key_found:
        if new_lines and not new_lines[-1].endswith('\n'):
            new_lines.append('\n')
        new_lines.append(f'{key}={value}\n')
    
    # Write back to file
    with open(ENV_FILE, 'w') as f:
        f.writelines(new_lines)
    
    # Update environment variable immediately
    os.environ[key] = value
    
    logger.info(f"Updated {key} in .env file")

@settings_bp.route('/gemini-api-key/test', methods=['POST'])
def test_gemini_key():
    """
    Test a Gemini API key before saving
    
    Request body:
    {
        "api_key": "your_gemini_api_key_here"
    }
    """
    try:
        logger.info("Received API key test request")
        data = request.get_json()
        logger.info(f"Request data: {data is not None}")
        
        if not data or 'api_key' not in data:
            logger.error("No API key in request")
            return jsonify({
                'success': False,
                'error': 'No API key provided'
            }), 400
        
        api_key = data['api_key'].strip()
        
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'API key cannot be empty'
            }), 400
        
        # Test the API key with Gemini
        logger.info("Testing Gemini API key...")
        
        try:
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-pro')
            
            # Simple test query
            response = model.generate_content(
                "Say 'Hello' if you can read this.",
                generation_config=genai.types.GenerationConfig(
                    temperature=0.1,
                    max_output_tokens=10,
                )
            )
            
            # Check if we got a response
            if response and response.text:
                logger.info("✅ Gemini API key is valid!")
                return jsonify({
                    'success': True,
                    'message': 'API key is valid and working!',
                    'test_response': response.text[:50]
                }), 200
            else:
                return jsonify({
                    'success': False,
                    'error': 'API key test failed - no response from Gemini'
                }), 400
                
        except Exception as api_error:
            error_message = str(api_error)
            logger.error(f"❌ Gemini API test failed: {error_message}")
            
            # Parse common errors
            if 'API_KEY_INVALID' in error_message or 'invalid' in error_message.lower():
                user_message = 'Invalid API key. Please check your key and try again.'
            elif 'quota' in error_message.lower() or 'limit' in error_message.lower():
                user_message = 'API quota exceeded. Please try again later or check your Google Cloud quota.'
            elif 'permission' in error_message.lower():
                user_message = 'API key does not have permission. Make sure Gemini API is enabled in your Google Cloud project.'
            else:
                user_message = f'API test failed: {error_message}'
            
            return jsonify({
                'success': False,
                'error': user_message,
                'details': error_message
            }), 400
    
    except Exception as e:
        logger.error(f"Error in test_gemini_key: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': f'Server error: {str(e)}'
        }), 500

@settings_bp.route('/gemini-api-key/save', methods=['POST'])
def save_gemini_key():
    """
    Save Gemini API key to .env file
    
    Request body:
    {
        "api_key": "your_gemini_api_key_here"
    }
    """
    try:
        data = request.get_json()
        if not data or 'api_key' not in data:
            return jsonify({
                'success': False,
                'error': 'No API key provided'
            }), 400
        
        api_key = data['api_key'].strip()
        
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'API key cannot be empty'
            }), 400
        
        # Save to .env file
        update_env_file('GEMINI_API_KEY', api_key)
        
        logger.info("✅ Gemini API key saved successfully")
        
        return jsonify({
            'success': True,
            'message': 'API key saved successfully! The AI recipe generation is now active.',
            'env_file_path': str(ENV_FILE)
        }), 200
    
    except Exception as e:
        logger.error(f"Error saving API key: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': f'Failed to save API key: {str(e)}'
        }), 500

@settings_bp.route('/gemini-api-key/status', methods=['GET'])
def get_gemini_status():
    """Check if Gemini API key is configured"""
    try:
        api_key = os.getenv('GEMINI_API_KEY')
        
        is_configured = bool(api_key and api_key.strip())
        
        return jsonify({
            'success': True,
            'is_configured': is_configured,
            'message': 'API key is configured' if is_configured else 'API key not configured'
        }), 200
    
    except Exception as e:
        logger.error(f"Error checking API key status: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@settings_bp.route('/gemini-api-key/remove', methods=['DELETE'])
def remove_gemini_key():
    """Remove Gemini API key from .env"""
    try:
        if not ENV_FILE.exists():
            return jsonify({
                'success': True,
                'message': 'No .env file exists'
            }), 200
        
        # Read and filter out the key
        with open(ENV_FILE, 'r') as f:
            lines = f.readlines()
        
        new_lines = [line for line in lines if not line.strip().startswith('GEMINI_API_KEY=')]
        
        with open(ENV_FILE, 'w') as f:
            f.writelines(new_lines)
        
        # Remove from environment
        if 'GEMINI_API_KEY' in os.environ:
            del os.environ['GEMINI_API_KEY']
        
        logger.info("Gemini API key removed")
        
        return jsonify({
            'success': True,
            'message': 'API key removed successfully'
        }), 200
    
    except Exception as e:
        logger.error(f"Error removing API key: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
