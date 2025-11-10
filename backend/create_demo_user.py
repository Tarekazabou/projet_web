"""
Script to create a demo user in Firestore
Run this once to set up the demo account
"""
import sys
from pathlib import Path

# Add the backend directory to the Python path
backend_dir = Path(__file__).resolve().parent
sys.path.insert(0, str(backend_dir))

from utils.firebase_connector import initialize_firebase, get_db
from datetime import datetime
import hashlib

def hash_password(password):
    """Simple password hashing"""
    return hashlib.sha256(password.encode()).hexdigest()

def create_demo_user():
    """Create the demo user account"""
    initialize_firebase()
    db = get_db()
    
    demo_email = 'demo@mealy.com'
    demo_password = 'demo123'
    
    # Check if demo user already exists
    users_ref = db.collection('User')
    from google.cloud.firestore_v1.base_query import FieldFilter
    existing = list(users_ref.where(filter=FieldFilter('email', '==', demo_email)).limit(1).get())
    
    if existing:
        print(f"✅ Demo user already exists: {demo_email}")
        user_id = existing[0].id
        print(f"   User ID: {user_id}")
        return user_id
    
    # Create demo user
    demo_user = {
        'email': demo_email,
        'username': 'Demo User',
        'displayName': 'Demo User',
        'password': hash_password(demo_password),
        'createdAt': datetime.utcnow(),
        'updatedAt': datetime.utcnow(),
        'dietary_preferences': ['vegetarian'],
        'allergies': [],
        'nutritionGoals': {
            'dailyCalories': 2000,
            'protein': 50,
            'carbs': 250,
            'fat': 70,
        }
    }
    
    user_ref = users_ref.document()
    user_ref.set(demo_user)
    
    print(f"✅ Created demo user: {demo_email}")
    print(f"   Password: {demo_password}")
    print(f"   User ID: {user_ref.id}")
    
    return user_ref.id

if __name__ == '__main__':
    try:
        create_demo_user()
        print("\n✨ Demo user is ready to use!")
    except Exception as e:
        print(f"❌ Error creating demo user: {e}")
        import traceback
        traceback.print_exc()
