import firebase_admin
from firebase_admin import credentials, firestore
from firebase_admin import auth as firebase_auth  # noqa: F401 (imported for side effects)
import os
from pathlib import Path

def initialize_firebase():
    """
    Initialize the Firebase Admin SDK.
    """
    # Check if the app is already initialized
    if not firebase_admin._apps:
        # Use a service account
        try:
            # First try to use the service account key file
            env_cred_path = os.getenv('FIREBASE_CREDENTIAL_PATH')
            if env_cred_path:
                cred_file = Path(env_cred_path)
            else:
                base_dir = Path(__file__).resolve().parents[2]
                cred_file = base_dir / 'mealy-41bf0-firebase-adminsdk-fbsvc-7d493e86ea.json'

            if cred_file.exists():
                cred = credentials.Certificate(str(cred_file))
                firebase_admin.initialize_app(cred)
                print("Firebase initialized successfully with service account key.")
            else:
                # Fallback to Application Default Credentials (for production/cloud environments)
                cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(cred, {
                    'projectId': os.environ.get('FIREBASE_PROJECT_ID', 'mealy-41bf0'),
                })
                print("Firebase initialized successfully with Application Default Credentials.")
        except Exception as e:
            print(f"Error initializing Firebase: {e}")
            raise


def get_db():
    """
    Get the Firestore database client.
    """
    return firestore.client()

# Example functions based on your schema.gql

def get_user(user_id):
    db = get_db()
    user_ref = db.collection('User').document(user_id)
    user = user_ref.get()
    if user.exists:
        return user.to_dict()
    return None

def create_user(user_data):
    db = get_db()
    # You can let Firestore generate an ID or set your own
    user_ref = db.collection('User').document() 
    user_ref.set(user_data)
    return user_ref.id

def get_recipe(recipe_id):
    db = get_db()
    recipe_ref = db.collection('Recipe').document(recipe_id)
    recipe = recipe_ref.get()
    if recipe.exists:
        return recipe.to_dict()
    return None

def create_recipe(recipe_data):
    db = get_db()
    recipe_ref = db.collection('Recipe').document()
    recipe_ref.set(recipe_data)
    return recipe_ref.id

# You would continue to create functions for each of your data types:
# Ingredient, RecipeIngredient, FridgeItem, MealPlan
