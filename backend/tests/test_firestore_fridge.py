"""
Quick test to check what's in Firestore FridgeItem collection
Run from project root: python test_firestore_fridge.py
"""
import sys
from pathlib import Path

# Add backend to path
backend_dir = Path(__file__).resolve().parent / 'backend'
sys.path.insert(0, str(backend_dir))

print("🧪 Testing Firestore Fridge Items...")
print("=" * 60)

try:
    # Initialize Firebase
    from utils.firebase_connector import initialize_firebase, get_db
    initialize_firebase()
    db = get_db()
    
    print("✅ Firebase initialized successfully")
    print()
    
    # Get all items in FridgeItem collection
    print("📦 Fetching all items from FridgeItem collection...")
    fridge_items = db.collection('FridgeItem').stream()
    
    items_list = []
    for doc in fridge_items:
        item = doc.to_dict()
        item['id'] = doc.id
        items_list.append(item)
    
    print(f"✅ Found {len(items_list)} total items in FridgeItem collection")
    print()
    
    if len(items_list) == 0:
        print("⚠️ No items found in Firestore!")
        print("   Run this to add demo items:")
        print("   POST http://localhost:5000/api/fridge/seed-demo-items")
    else:
        # Group by userId
        users = {}
        for item in items_list:
            user_id = item.get('userId', 'unknown')
            if user_id not in users:
                users[user_id] = []
            users[user_id].append(item)
        
        print(f"👥 Items grouped by {len(users)} user(s):")
        print()
        
        for user_id, user_items in users.items():
            print(f"  User: {user_id}")
            print(f"  Items: {len(user_items)}")
            for item in user_items:
                ingredient_name = item.get('ingredientName', 'NO NAME')
                quantity = item.get('quantity', '?')
                unit = item.get('unit', '?')
                print(f"    - {ingredient_name} ({quantity} {unit})")
            print()
    
    print("=" * 60)
    print("🎉 Test complete!")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
