"""
Complete test of the Fridge → Firestore → Recipe Generation flow
"""
import requests
import json

API_BASE = "http://localhost:5000/api"

print("🧪 Testing Complete Fridge-to-Recipe Flow\n")
print("=" * 60)

# Step 1: Seed demo items to fridge
print("\n📦 STEP 1: Adding demo items to Firestore fridge...")
try:
    response = requests.post(f"{API_BASE}/fridge/seed-demo-items", headers={"Content-Type": "application/json"})
    
    if response.status_code in [200, 201]:
        data = response.json()
        print(f"✅ {data.get('message')}")
        print(f"   Items added: {len(data.get('items', []))}")
    else:
        print(f"❌ Failed: {response.status_code}")
        print(response.json())
except Exception as e:
    print(f"❌ Error: {e}")

# Step 2: Get fridge items
print("\n📋 STEP 2: Fetching fridge items from Firestore...")
try:
    response = requests.get(f"{API_BASE}/fridge/items")
    
    if response.status_code == 200:
        data = response.json()
        items = data.get('items', [])
        print(f"✅ Found {len(items)} items in fridge")
        for item in items:
            name = item.get('ingredientName') or item.get('name')
            expiry = item.get('expirationDate') or item.get('expiryDate')
            print(f"   - {name} ({item.get('quantity')} {item.get('unit')}) - expires: {expiry}")
    else:
        print(f"❌ Failed: {response.status_code}")
except Exception as e:
    print(f"❌ Error: {e}")

# Step 3: Generate recipe from fridge
print("\n🤖 STEP 3: Generating AI recipe from fridge ingredients...")
try:
    response = requests.post(
        f"{API_BASE}/recipes/generate-from-fridge",
        json={
            "dietary_preferences": ["healthy"],
            "max_cooking_time": 45,
            "difficulty": "medium",
            "servings": 4
        },
        headers={"Content-Type": "application/json"}
    )
    
    print(f"   Status: {response.status_code}")
    
    if response.status_code in [200, 201]:
        data = response.json()
        recipe = data.get('recipe', {})
        
        print("\n" + "=" * 60)
        print("✅ SUCCESS! Recipe Generated!")
        print("=" * 60)
        
        print(f"\n📝 Title: {recipe.get('title')}")
        print(f"📄 Description: {recipe.get('description', 'N/A')[:100]}...")
        print(f"\n🥘 Recipe Details:")
        print(f"   • Servings: {recipe.get('servingSize', 'N/A')}")
        print(f"   • Prep Time: {recipe.get('prepTimeMinutes', 'N/A')} min")
        print(f"   • Cook Time: {recipe.get('cookTimeMinutes', 'N/A')} min")
        print(f"   • Difficulty: {recipe.get('difficulty', 'N/A')}")
        
        print(f"\n🛒 Fridge Stats:")
        print(f"   • Ingredients Used: {data.get('fridge_ingredients_used', 0)}")
        print(f"   • Expiring Soon: {data.get('ingredients_expiring_soon', 0)}")
        print(f"   • Similar Recipes Found: {data.get('similar_recipes_found', 0)}")
        
        if recipe.get('usedIngredients'):
            print(f"\n✅ Ingredients from Your Fridge:")
            for ing in recipe['usedIngredients']:
                is_expiring = ing in recipe.get('prioritizedIngredients', [])
                marker = "⚠️ " if is_expiring else "   "
                print(f"   {marker}{ing}")
        
        if recipe.get('basedOnRecipes'):
            print(f"\n💡 Inspired by:")
            for r in recipe['basedOnRecipes']:
                print(f"   • {r}")
        
        print(f"\n💾 Recipe ID: {recipe.get('id', 'N/A')}")
        print(f"🤖 AI Generated: {recipe.get('generatedByAI', False)}")
        print(f"🧊 From Fridge: {recipe.get('fromFridge', False)}")
        
        print("\n" + "=" * 60)
        print("🎉 Complete Flow Successful!")
        print("=" * 60)
        
    elif response.status_code == 400:
        error_data = response.json()
        print(f"\n⚠️  {error_data.get('error', 'Bad request')}")
        if 'No valid ingredients' in str(error_data):
            print("\n💡 Tip: Make sure you have items in your fridge first!")
    else:
        print(f"\n❌ Failed: {response.status_code}")
        print(response.json())
        
except requests.exceptions.ConnectionError:
    print("❌ Cannot connect to backend server!")
    print("Make sure the server is running: python backend/src/app.py")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 60)
