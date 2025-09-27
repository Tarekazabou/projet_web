from datetime import datetime
import logging
from backend.models.models import Recipe, User, Ingredient

logger = logging.getLogger(__name__)

def initialize_database(mongo):
    """Initialize MongoDB collections and indexes"""
    try:
        db = mongo.db
        
        # Create collections if they don't exist
        collections = ['recipes', 'users', 'meal_plans', 'feedback', 'ingredients']
        
        for collection_name in collections:
            if collection_name not in db.list_collection_names():
                db.create_collection(collection_name)
                logger.info(f"Created collection: {collection_name}")
        
        # Create indexes for better performance
        create_indexes(db)
        
        # Insert sample data if collections are empty
        insert_sample_data(db)
        
        logger.info("Database initialization completed successfully")
        
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        raise

def create_indexes(db):
    """Create database indexes for better query performance"""
    try:
        # Recipe indexes
        db.recipes.create_index("title")
        db.recipes.create_index("dietary_tags")
        db.recipes.create_index("cuisine_type")
        db.recipes.create_index("cooking_time")
        db.recipes.create_index("difficulty")
        db.recipes.create_index("rating")
        
        # User indexes
        db.users.create_index("username", unique=True)
        db.users.create_index("email", unique=True)
        db.users.create_index("dietary_preferences")
        
        # Meal plan indexes
        db.meal_plans.create_index("user_id")
        db.meal_plans.create_index("start_date")
        db.meal_plans.create_index("end_date")
        
        # Feedback indexes
        db.feedback.create_index("recipe_id")
        db.feedback.create_index("user_id")
        db.feedback.create_index("rating")
        db.feedback.create_index("created_at")
        
        # Ingredient indexes
        db.ingredients.create_index("name", unique=True)
        db.ingredients.create_index("dietary_tags")
        
        logger.info("Database indexes created successfully")
        
    except Exception as e:
        logger.error(f"Failed to create indexes: {e}")

def insert_sample_data(db):
    """Insert sample data if collections are empty"""
    try:
        # Sample recipes
        if db.recipes.count_documents({}) == 0:
            sample_recipes = [
                Recipe(
                    title="Quinoa Veggie Bowl",
                    ingredients=[
                        {"name": "quinoa", "amount": "1", "unit": "cup"},
                        {"name": "bell peppers", "amount": "2", "unit": "pieces"},
                        {"name": "avocado", "amount": "1", "unit": "piece"},
                        {"name": "olive oil", "amount": "2", "unit": "tablespoons"},
                        {"name": "lemon juice", "amount": "1", "unit": "tablespoon"}
                    ],
                    instructions=[
                        "Rinse quinoa and cook in 2 cups of water for 15 minutes",
                        "Dice bell peppers and sauté in olive oil for 5 minutes",
                        "Slice avocado and prepare serving bowls",
                        "Combine quinoa, peppers, and avocado",
                        "Drizzle with lemon juice and season to taste"
                    ],
                    cooking_time=20,
                    prep_time=10,
                    servings=2,
                    dietary_tags=["vegan", "gluten-free", "healthy"],
                    nutrition={
                        "calories": 350,
                        "protein": 12,
                        "carbs": 45,
                        "fat": 18,
                        "fiber": 8,
                        "sugar": 6
                    },
                    difficulty="easy",
                    cuisine_type="international"
                ),
                Recipe(
                    title="Mediterranean Chickpea Salad",
                    ingredients=[
                        {"name": "chickpeas", "amount": "1", "unit": "can"},
                        {"name": "cucumber", "amount": "1", "unit": "piece"},
                        {"name": "tomatoes", "amount": "2", "unit": "pieces"},
                        {"name": "red onion", "amount": "0.5", "unit": "piece"},
                        {"name": "feta cheese", "amount": "100", "unit": "g"},
                        {"name": "olive oil", "amount": "3", "unit": "tablespoons"},
                        {"name": "lemon juice", "amount": "2", "unit": "tablespoons"}
                    ],
                    instructions=[
                        "Drain and rinse chickpeas",
                        "Dice cucumber, tomatoes, and red onion",
                        "Combine all vegetables with chickpeas",
                        "Crumble feta cheese over the salad",
                        "Whisk olive oil and lemon juice, pour over salad",
                        "Toss gently and let marinate for 15 minutes"
                    ],
                    cooking_time=0,
                    prep_time=15,
                    servings=3,
                    dietary_tags=["vegetarian", "mediterranean", "high-protein"],
                    nutrition={
                        "calories": 280,
                        "protein": 15,
                        "carbs": 32,
                        "fat": 12,
                        "fiber": 10,
                        "sugar": 8
                    },
                    difficulty="easy",
                    cuisine_type="mediterranean"
                ),
                Recipe(
                    title="Keto Salmon with Asparagus",
                    ingredients=[
                        {"name": "salmon fillets", "amount": "2", "unit": "pieces"},
                        {"name": "asparagus", "amount": "300", "unit": "g"},
                        {"name": "butter", "amount": "3", "unit": "tablespoons"},
                        {"name": "garlic", "amount": "3", "unit": "cloves"},
                        {"name": "lemon", "amount": "1", "unit": "piece"}
                    ],
                    instructions=[
                        "Preheat oven to 400°F (200°C)",
                        "Season salmon fillets with salt and pepper",
                        "Trim asparagus ends and place on baking sheet",
                        "Melt butter with minced garlic",
                        "Brush salmon and asparagus with garlic butter",
                        "Bake for 12-15 minutes until salmon flakes easily",
                        "Serve with lemon wedges"
                    ],
                    cooking_time=15,
                    prep_time=10,
                    servings=2,
                    dietary_tags=["keto", "low-carb", "high-protein", "gluten-free"],
                    nutrition={
                        "calories": 420,
                        "protein": 35,
                        "carbs": 6,
                        "fat": 28,
                        "fiber": 3,
                        "sugar": 3
                    },
                    difficulty="medium",
                    cuisine_type="american"
                )
            ]
            
            for recipe in sample_recipes:
                db.recipes.insert_one(recipe.to_dict())
            
            logger.info(f"Inserted {len(sample_recipes)} sample recipes")
        
        # Sample ingredients
        if db.ingredients.count_documents({}) == 0:
            sample_ingredients = [
                Ingredient(
                    name="quinoa",
                    nutrition_per_100g={
                        "calories": 368,
                        "protein": 14.1,
                        "carbs": 64.2,
                        "fat": 6.1,
                        "fiber": 7.0,
                        "sugar": 4.6
                    },
                    dietary_tags=["vegan", "gluten-free", "high-protein"],
                    common_units=["cup", "g", "tablespoon"]
                ),
                Ingredient(
                    name="avocado",
                    nutrition_per_100g={
                        "calories": 160,
                        "protein": 2.0,
                        "carbs": 8.5,
                        "fat": 14.7,
                        "fiber": 6.7,
                        "sugar": 0.7
                    },
                    dietary_tags=["vegan", "keto", "healthy-fats"],
                    common_units=["piece", "cup", "slice"]
                ),
                Ingredient(
                    name="salmon",
                    nutrition_per_100g={
                        "calories": 208,
                        "protein": 25.4,
                        "carbs": 0,
                        "fat": 12.4,
                        "fiber": 0,
                        "sugar": 0
                    },
                    dietary_tags=["keto", "high-protein", "omega-3"],
                    common_units=["fillet", "g", "oz"]
                ),
                Ingredient(
                    name="chickpeas",
                    nutrition_per_100g={
                        "calories": 364,
                        "protein": 19.3,
                        "carbs": 60.6,
                        "fat": 6.0,
                        "fiber": 17.4,
                        "sugar": 10.7
                    },
                    dietary_tags=["vegan", "high-protein", "high-fiber"],
                    common_units=["can", "cup", "g"]
                )
            ]
            
            for ingredient in sample_ingredients:
                db.ingredients.insert_one(ingredient.to_dict())
            
            logger.info(f"Inserted {len(sample_ingredients)} sample ingredients")
        
    except Exception as e:
        logger.error(f"Failed to insert sample data: {e}")

def reset_database(mongo):
    """Reset database by dropping all collections (use with caution!)"""
    try:
        db = mongo.db
        collections = ['recipes', 'users', 'meal_plans', 'feedback', 'ingredients']
        
        for collection_name in collections:
            db[collection_name].drop()
            logger.info(f"Dropped collection: {collection_name}")
        
        # Reinitialize after reset
        initialize_database(mongo)
        
        logger.info("Database reset completed successfully")
        
    except Exception as e:
        logger.error(f"Database reset failed: {e}")
        raise