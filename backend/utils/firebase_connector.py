import firebase_admin
from firebase_admin import credentials, firestore
import os

def initialize_firebase():
    """
    Initialize the Firebase Admin SDK.
    """
    # Check if the app is already initialized
    if not firebase_admin._apps:
        # Use a service account
        # You need to download your service account key from the Firebase console
        # and set the GOOGLE_APPLICATION_CREDENTIALS environment variable.
        try:
            cred = credentials.ApplicationDefault()
            firebase_admin.initialize_app(cred, {
                'projectId': os.environ.get('FIREBASE_PROJECT_ID', 'mealy-41bf0'),
            })
            print("Firebase initialized successfully.")
        except Exception as e:
            print(f"Error initializing Firebase: {e}")
            # Fallback for local development if GOOGLE_APPLICATION_CREDENTIALS is not set
            # This is not recommended for production.
            # Create a serviceAccountKey.json file in your backend root for this to work.
            try:
                cred_path = os.path.join(os.path.dirname(__file__), '..', 'serviceAccountKey.json')
                if os.path.exists(cred_path):
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                    print("Firebase initialized successfully with local key.")
                else:
                    print("Could not initialize Firebase. Service account key not found.")
            except Exception as e_local:
                print(f"Error initializing Firebase with local key: {e_local}")


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
