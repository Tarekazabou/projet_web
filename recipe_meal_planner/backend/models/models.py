from datetime import datetime
from bson import ObjectId
from typing import Dict, List, Optional

class Recipe:
    """Recipe model for MongoDB storage"""
    
    def __init__(self, title: str, ingredients: List[Dict], instructions: List[str], 
                 cooking_time: int, prep_time: int, servings: int, 
                 dietary_tags: List[str] = None, nutrition: Dict = None,
                 difficulty: str = "medium", cuisine_type: str = "international"):
        self.title = title
        self.ingredients = ingredients  # [{"name": "quinoa", "amount": "1 cup", "unit": "cup"}]
        self.instructions = instructions
        self.cooking_time = cooking_time  # minutes
        self.prep_time = prep_time  # minutes
        self.servings = servings
        self.dietary_tags = dietary_tags or []  # ["vegan", "gluten-free", "keto"]
        self.nutrition = nutrition or {}  # {"calories": 350, "protein": 12, "carbs": 45, "fat": 8}
        self.difficulty = difficulty  # "easy", "medium", "hard"
        self.cuisine_type = cuisine_type
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
        self.rating = 0.0
        self.review_count = 0
    
    def to_dict(self) -> Dict:
        """Convert recipe to dictionary for MongoDB storage"""
        return {
            "title": self.title,
            "ingredients": self.ingredients,
            "instructions": self.instructions,
            "cooking_time": self.cooking_time,
            "prep_time": self.prep_time,
            "total_time": self.cooking_time + self.prep_time,
            "servings": self.servings,
            "dietary_tags": self.dietary_tags,
            "nutrition": self.nutrition,
            "difficulty": self.difficulty,
            "cuisine_type": self.cuisine_type,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "rating": self.rating,
            "review_count": self.review_count
        }
    
    @classmethod
    def from_dict(cls, data: Dict):
        """Create Recipe instance from dictionary"""
        recipe = cls(
            title=data.get("title", ""),
            ingredients=data.get("ingredients", []),
            instructions=data.get("instructions", []),
            cooking_time=data.get("cooking_time", 0),
            prep_time=data.get("prep_time", 0),
            servings=data.get("servings", 1),
            dietary_tags=data.get("dietary_tags", []),
            nutrition=data.get("nutrition", {}),
            difficulty=data.get("difficulty", "medium"),
            cuisine_type=data.get("cuisine_type", "international")
        )
        recipe.created_at = data.get("created_at", datetime.utcnow())
        recipe.updated_at = data.get("updated_at", datetime.utcnow())
        recipe.rating = data.get("rating", 0.0)
        recipe.review_count = data.get("review_count", 0)
        return recipe

class User:
    """User model for MongoDB storage"""
    
    def __init__(self, username: str, email: str, dietary_preferences: List[str] = None,
                 allergies: List[str] = None, nutritional_goals: Dict = None):
        self.username = username
        self.email = email
        self.dietary_preferences = dietary_preferences or []  # ["vegan", "low-sodium"]
        self.allergies = allergies or []  # ["nuts", "dairy"]
        self.nutritional_goals = nutritional_goals or {}  # {"calories": 2000, "protein": 150}
        self.favorite_recipes = []
        self.meal_plans = []
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
        self.is_active = True
    
    def to_dict(self) -> Dict:
        """Convert user to dictionary for MongoDB storage"""
        return {
            "username": self.username,
            "email": self.email,
            "dietary_preferences": self.dietary_preferences,
            "allergies": self.allergies,
            "nutritional_goals": self.nutritional_goals,
            "favorite_recipes": self.favorite_recipes,
            "meal_plans": self.meal_plans,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "is_active": self.is_active
        }
    
    @classmethod
    def from_dict(cls, data: Dict):
        """Create User instance from dictionary"""
        user = cls(
            username=data.get("username", ""),
            email=data.get("email", ""),
            dietary_preferences=data.get("dietary_preferences", []),
            allergies=data.get("allergies", []),
            nutritional_goals=data.get("nutritional_goals", {})
        )
        user.favorite_recipes = data.get("favorite_recipes", [])
        user.meal_plans = data.get("meal_plans", [])
        user.created_at = data.get("created_at", datetime.utcnow())
        user.updated_at = data.get("updated_at", datetime.utcnow())
        user.is_active = data.get("is_active", True)
        return user

class MealPlan:
    """Meal plan model for MongoDB storage"""
    
    def __init__(self, user_id: str, title: str, start_date: datetime, 
                 end_date: datetime, meals: Dict = None):
        self.user_id = user_id
        self.title = title
        self.start_date = start_date
        self.end_date = end_date
        self.meals = meals or {}  # {"monday": {"breakfast": recipe_id, "lunch": recipe_id, ...}}
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
        self.is_active = True
    
    def to_dict(self) -> Dict:
        """Convert meal plan to dictionary for MongoDB storage"""
        return {
            "user_id": self.user_id,
            "title": self.title,
            "start_date": self.start_date,
            "end_date": self.end_date,
            "meals": self.meals,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "is_active": self.is_active
        }
    
    @classmethod
    def from_dict(cls, data: Dict):
        """Create MealPlan instance from dictionary"""
        meal_plan = cls(
            user_id=data.get("user_id", ""),
            title=data.get("title", ""),
            start_date=data.get("start_date", datetime.utcnow()),
            end_date=data.get("end_date", datetime.utcnow()),
            meals=data.get("meals", {})
        )
        meal_plan.created_at = data.get("created_at", datetime.utcnow())
        meal_plan.updated_at = data.get("updated_at", datetime.utcnow())
        meal_plan.is_active = data.get("is_active", True)
        return meal_plan

class Feedback:
    """Feedback model for MongoDB storage"""
    
    def __init__(self, user_id: str, recipe_id: str, rating: float, 
                 comment: str = "", difficulty_rating: int = None,
                 would_make_again: bool = None):
        self.user_id = user_id
        self.recipe_id = recipe_id
        self.rating = rating  # 1-5 stars
        self.comment = comment
        self.difficulty_rating = difficulty_rating  # 1-5 (1=very easy, 5=very hard)
        self.would_make_again = would_make_again
        self.created_at = datetime.utcnow()
        self.helpful_votes = 0
    
    def to_dict(self) -> Dict:
        """Convert feedback to dictionary for MongoDB storage"""
        return {
            "user_id": self.user_id,
            "recipe_id": self.recipe_id,
            "rating": self.rating,
            "comment": self.comment,
            "difficulty_rating": self.difficulty_rating,
            "would_make_again": self.would_make_again,
            "created_at": self.created_at,
            "helpful_votes": self.helpful_votes
        }
    
    @classmethod
    def from_dict(cls, data: Dict):
        """Create Feedback instance from dictionary"""
        feedback = cls(
            user_id=data.get("user_id", ""),
            recipe_id=data.get("recipe_id", ""),
            rating=data.get("rating", 0.0),
            comment=data.get("comment", ""),
            difficulty_rating=data.get("difficulty_rating"),
            would_make_again=data.get("would_make_again")
        )
        feedback.created_at = data.get("created_at", datetime.utcnow())
        feedback.helpful_votes = data.get("helpful_votes", 0)
        return feedback

class Ingredient:
    """Ingredient model for nutritional database"""
    
    def __init__(self, name: str, nutrition_per_100g: Dict, 
                 dietary_tags: List[str] = None, common_units: List[str] = None):
        self.name = name.lower()
        self.nutrition_per_100g = nutrition_per_100g  # {"calories": 150, "protein": 4.4, ...}
        self.dietary_tags = dietary_tags or []  # ["vegan", "gluten-free"]
        self.common_units = common_units or ["g", "cup", "tablespoon"]
        self.created_at = datetime.utcnow()
    
    def to_dict(self) -> Dict:
        """Convert ingredient to dictionary for MongoDB storage"""
        return {
            "name": self.name,
            "nutrition_per_100g": self.nutrition_per_100g,
            "dietary_tags": self.dietary_tags,
            "common_units": self.common_units,
            "created_at": self.created_at
        }
    
    @classmethod
    def from_dict(cls, data: Dict):
        """Create Ingredient instance from dictionary"""
        ingredient = cls(
            name=data.get("name", ""),
            nutrition_per_100g=data.get("nutrition_per_100g", {}),
            dietary_tags=data.get("dietary_tags", []),
            common_units=data.get("common_units", ["g", "cup", "tablespoon"])
        )
        ingredient.created_at = data.get("created_at", datetime.utcnow())
        return ingredient


class FridgeItem:
    """Model for tracking items in user's fridge/pantry"""
    
    def __init__(self, name: str, category: str, quantity: float, unit: str, 
                 expiry_date: str, location: str = "Main fridge", notes: str = "",
                 added_date: str = None, user_id: str = "default_user"):
        self.name = name
        self.category = category  # produce, dairy, meat, pantry, frozen, beverages, other
        self.quantity = quantity
        self.unit = unit
        self.expiry_date = expiry_date  # ISO date string YYYY-MM-DD
        self.location = location  # Main fridge, Freezer, Pantry, Door, etc.
        self.notes = notes
        self.added_date = added_date or datetime.now().strftime('%Y-%m-%d')
        self.user_id = user_id
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
    
    def to_dict(self) -> Dict:
        """Convert fridge item to dictionary for MongoDB storage"""
        return {
            "name": self.name,
            "category": self.category,
            "quantity": self.quantity,
            "unit": self.unit,
            "expiryDate": self.expiry_date,
            "location": self.location,
            "notes": self.notes,
            "addedDate": self.added_date,
            "userId": self.user_id,
            "createdAt": self.created_at,
            "updatedAt": self.updated_at
        }
    
    @classmethod
    def from_dict(cls, data: Dict):
        """Create FridgeItem instance from dictionary"""
        item = cls(
            name=data.get("name", ""),
            category=data.get("category", "other"),
            quantity=data.get("quantity", 0.0),
            unit=data.get("unit", ""),
            expiry_date=data.get("expiryDate", ""),
            location=data.get("location", "Main fridge"),
            notes=data.get("notes", ""),
            added_date=data.get("addedDate"),
            user_id=data.get("userId", "default_user")
        )
        item.created_at = data.get("createdAt", datetime.utcnow())
        item.updated_at = data.get("updatedAt", datetime.utcnow())
        return item
    
    def is_expired(self) -> bool:
        """Check if item is expired"""
        try:
            expiry_date = datetime.strptime(self.expiry_date, '%Y-%m-%d').date()
            return expiry_date < datetime.now().date()
        except ValueError:
            return False
    
    def days_until_expiry(self) -> int:
        """Get days until expiry (negative if expired)"""
        try:
            expiry_date = datetime.strptime(self.expiry_date, '%Y-%m-%d').date()
            return (expiry_date - datetime.now().date()).days
        except ValueError:
            return 0
    
    def freshness_status(self) -> str:
        """Get freshness status: fresh, expiring-soon, expired"""
        days = self.days_until_expiry()
        if days < 0:
            return "expired"
        elif days <= 2:
            return "expiring-soon"
        else:
            return "fresh"