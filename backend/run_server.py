"""
Alternative server runner using waitress (more stable on Windows)
Run this instead of app.py directly to avoid socket errors on reload
"""
import sys
from pathlib import Path
import os

# Add the backend directory to the Python path
backend_dir = Path(__file__).resolve().parent
sys.path.insert(0, str(backend_dir))

from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import the Flask app
from src.app import app

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    
    # Check if we should use waitress (recommended for Windows)
    use_waitress = os.getenv('USE_WAITRESS', 'true').lower() == 'true'
    
    if use_waitress:
        try:
            from waitress import serve
            print(f"Starting Waitress server on http://0.0.0.0:{port}")
            print("This server is more stable on Windows and doesn't have socket reload issues.")
            print("Press Ctrl+C to stop the server.")
            serve(app, host='0.0.0.0', port=port, threads=4)
        except ImportError:
            print("Waitress not installed. Install it with: pip install waitress")
            print("Falling back to Flask development server...")
            app.run(host='0.0.0.0', port=port, debug=True, use_reloader=True, reloader_type='stat')
    else:
        # Use Flask's built-in server (development only)
        debug = os.getenv('FLASK_ENV') == 'development'
        app.run(
            host='0.0.0.0',
            port=port,
            debug=debug,
            use_reloader=debug,
            reloader_type='stat'
        )
