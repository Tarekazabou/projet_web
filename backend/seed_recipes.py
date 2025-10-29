"""
Seed script to populate the database with sample recipes
Run this to have recipes available for testing
"""
import sys
from pathlib import Path

# Add the backend directory to the Python path
backend_dir = Path(__file__).resolve().parent
sys.path.insert(0, str(backend_dir))

from utils.firebase_connector import initialize_firebase, get_db
from datetime import datetime

def seed_recipes():
    """Add sample recipes to the database"""
    initialize_firebase()
    db = get_db()
    
    sample_recipes = [
        {
            'title': 'Grilled Chicken Salad',
            'description': 'A healthy and delicious grilled chicken salad with fresh vegetables',
            'instructions': '1. Season chicken breast with salt, pepper, and olive oil\n2. Grill chicken for 6-7 minutes per side\n3. Let chicken rest, then slice\n4. Mix lettuce, tomatoes, cucumbers, and dressing\n5. Top with grilled chicken slices',
            'servingSize': 2,
            'prepTimeMinutes': 15,
            'cookTimeMinutes': 15,
            'difficulty': 'easy',
            'cuisine': 'american',
            'dietaryPreferences': ['healthy', 'high-protein', 'gluten-free'],
            'rating': 4.5,
            'nutrition': {
                'calories': 350,
                'protein': 40,
                'carbs': 15,
                'fat': 12,
                'fiber': 5
            },
            'ingredients': ['chicken breast', 'lettuce', 'tomatoes', 'cucumbers', 'olive oil'],
            'createdAt': datetime.utcnow()
        },
        {
            'title': 'Vegetarian Buddha Bowl',
            'description': 'Colorful and nutritious bowl with quinoa, roasted vegetables, and tahini dressing',
            'instructions': '1. Cook quinoa according to package instructions\n2. Roast sweet potato, broccoli, and chickpeas with olive oil\n3. Prepare tahini dressing with lemon juice\n4. Assemble bowl with quinoa, roasted veggies, and avocado\n5. Drizzle with tahini dressing',
            'servingSize': 2,
            'prepTimeMinutes': 20,
            'cookTimeMinutes': 30,
            'difficulty': 'medium',
            'cuisine': 'mediterranean',
            'dietaryPreferences': ['vegan', 'vegetarian', 'healthy', 'gluten-free'],
            'rating': 4.8,
            'nutrition': {
                'calories': 450,
                'protein': 15,
                'carbs': 60,
                'fat': 18,
                'fiber': 12
            },
            'ingredients': ['quinoa', 'sweet potato', 'broccoli', 'chickpeas', 'avocado', 'tahini'],
            'createdAt': datetime.utcnow()
        },
        {
            'title': 'Quick Pasta Primavera',
            'description': 'Light and fresh pasta with seasonal vegetables',
            'instructions': '1. Cook pasta according to package directions\n2. Sauté garlic in olive oil\n3. Add zucchini, bell peppers, and cherry tomatoes\n4. Toss with cooked pasta and parmesan\n5. Season with basil, salt, and pepper',
            'servingSize': 4,
            'prepTimeMinutes': 10,
            'cookTimeMinutes': 15,
            'difficulty': 'easy',
            'cuisine': 'mediterranean',
            'dietaryPreferences': ['vegetarian', 'healthy'],
            'rating': 4.3,
            'nutrition': {
                'calories': 380,
                'protein': 12,
                'carbs': 55,
                'fat': 12,
                'fiber': 6
            },
            'ingredients': ['pasta', 'zucchini', 'bell peppers', 'cherry tomatoes', 'garlic', 'parmesan'],
            'createdAt': datetime.utcnow()
        },
        {
            'title': 'Keto Beef Stir Fry',
            'description': 'Low-carb beef stir fry with vegetables and savory sauce',
            'instructions': '1. Slice beef thinly against the grain\n2. Heat wok or large pan with oil\n3. Stir-fry beef until browned, remove\n4. Stir-fry broccoli, peppers, and mushrooms\n5. Add beef back with soy sauce and sesame oil',
            'servingSize': 3,
            'prepTimeMinutes': 15,
            'cookTimeMinutes': 12,
            'difficulty': 'easy',
            'cuisine': 'international',
            'dietaryPreferences': ['keto', 'low-carb', 'high-protein', 'gluten-free'],
            'rating': 4.6,
            'nutrition': {
                'calories': 320,
                'protein': 35,
                'carbs': 10,
                'fat': 16,
                'fiber': 3
            },
            'ingredients': ['beef', 'broccoli', 'bell peppers', 'mushrooms', 'soy sauce', 'sesame oil'],
            'createdAt': datetime.utcnow()
        },
        {
            'title': 'Mediterranean Baked Fish',
            'description': 'Tender baked fish with Mediterranean herbs and lemon',
            'instructions': '1. Preheat oven to 400°F (200°C)\n2. Season fish with salt, pepper, and herbs\n3. Place fish in baking dish with lemon slices\n4. Add cherry tomatoes and olives\n5. Bake for 15-18 minutes until fish flakes easily',
            'servingSize': 2,
            'prepTimeMinutes': 10,
            'cookTimeMinutes': 18,
            'difficulty': 'easy',
            'cuisine': 'mediterranean',
            'dietaryPreferences': ['healthy', 'mediterranean', 'high-protein', 'gluten-free'],
            'rating': 4.7,
            'nutrition': {
                'calories': 280,
                'protein': 38,
                'carbs': 8,
                'fat': 10,
                'fiber': 2
            },
            'ingredients': ['white fish', 'lemon', 'cherry tomatoes', 'olives', 'herbs', 'olive oil'],
            'createdAt': datetime.utcnow()
        },
        {
            'title': 'Vegan Lentil Curry',
            'description': 'Hearty and flavorful lentil curry with coconut milk',
            'instructions': '1. Sauté onion, garlic, and ginger\n2. Add curry powder and cook until fragrant\n3. Add lentils, coconut milk, and vegetable broth\n4. Simmer for 25-30 minutes until lentils are tender\n5. Serve with rice or naan',
            'servingSize': 4,
            'prepTimeMinutes': 10,
            'cookTimeMinutes': 35,
            'difficulty': 'easy',
            'cuisine': 'international',
            'dietaryPreferences': ['vegan', 'vegetarian', 'healthy', 'gluten-free'],
            'rating': 4.9,
            'nutrition': {
                'calories': 320,
                'protein': 16,
                'carbs': 45,
                'fat': 8,
                'fiber': 14
            },
            'ingredients': ['lentils', 'coconut milk', 'onion', 'garlic', 'ginger', 'curry powder'],
            'createdAt': datetime.utcnow()
        },
        {
            'title': 'Classic Scrambled Eggs',
            'description': 'Fluffy scrambled eggs perfect for breakfast',
            'instructions': '1. Crack eggs into a bowl and whisk well\n2. Heat butter in a non-stick pan\n3. Pour eggs and let sit for 20 seconds\n4. Gently stir with spatula, creating large soft curds\n5. Remove from heat while still slightly runny',
            'servingSize': 2,
            'prepTimeMinutes': 5,
            'cookTimeMinutes': 5,
            'difficulty': 'easy',
            'cuisine': 'american',
            'dietaryPreferences': ['high-protein', 'gluten-free', 'keto', 'low-carb'],
            'rating': 4.2,
            'nutrition': {
                'calories': 180,
                'protein': 14,
                'carbs': 2,
                'fat': 13,
                'fiber': 0
            },
            'ingredients': ['eggs', 'butter', 'salt', 'pepper'],
            'createdAt': datetime.utcnow()
        },
        {
            'title': 'Healthy Overnight Oats',
            'description': 'Easy no-cook breakfast with oats, fruits, and nuts',
            'instructions': '1. Mix oats with milk or plant-based alternative\n2. Add chia seeds and sweetener\n3. Cover and refrigerate overnight\n4. In the morning, top with berries and nuts\n5. Enjoy cold or heat if preferred',
            'servingSize': 1,
            'prepTimeMinutes': 5,
            'cookTimeMinutes': 0,
            'difficulty': 'easy',
            'cuisine': 'american',
            'dietaryPreferences': ['vegetarian', 'healthy', 'vegan'],
            'rating': 4.4,
            'nutrition': {
                'calories': 320,
                'protein': 12,
                'carbs': 48,
                'fat': 10,
                'fiber': 10
            },
            'ingredients': ['oats', 'milk', 'chia seeds', 'berries', 'nuts', 'honey'],
            'createdAt': datetime.utcnow()
        }
    ]
    
    print("Seeding recipes...")
    recipe_refs = []
    
    for recipe_data in sample_recipes:
        try:
            _, recipe_ref = db.collection('Recipe').add(recipe_data)
            recipe_refs.append(recipe_ref.id)
            print(f"✓ Added: {recipe_data['title']} (ID: {recipe_ref.id})")
        except Exception as e:
            print(f"✗ Error adding {recipe_data['title']}: {e}")
    
    print(f"\n✅ Successfully seeded {len(recipe_refs)} recipes!")
    print("\nYou can now test recipe search with queries like:")
    print("  - Chicken")
    print("  - Vegan")
    print("  - Quick recipes (< 15 min)")
    print("  - Mediterranean")
    
    return recipe_refs

if __name__ == '__main__':
    try:
        seed_recipes()
    except Exception as e:
        print(f"Error seeding database: {e}")
        import traceback
        traceback.print_exc()
