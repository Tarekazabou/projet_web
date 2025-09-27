import logging
from typing import List, Dict, Optional
import re
from collections import defaultdict

logger = logging.getLogger(__name__)

class RecipeGenerator:
    """AI-powered recipe generation algorithm"""
    
    def __init__(self, db):
        self.db = db
        self.ingredient_substitutions = {
            'milk': ['almond milk', 'soy milk', 'oat milk', 'coconut milk'],
            'butter': ['olive oil', 'coconut oil', 'avocado oil'],
            'flour': ['almond flour', 'coconut flour', 'oat flour'],
            'sugar': ['honey', 'maple syrup', 'stevia', 'dates'],
            'eggs': ['flax eggs', 'chia eggs', 'applesauce'],
            'cheese': ['nutritional yeast', 'cashew cheese', 'vegan cheese']
        }
        
        self.dietary_restrictions = {
            'vegan': ['meat', 'dairy', 'eggs', 'honey', 'gelatin'],
            'vegetarian': ['meat', 'fish', 'seafood'],
            'gluten-free': ['wheat', 'barley', 'rye', 'flour'],
            'dairy-free': ['milk', 'cheese', 'butter', 'cream', 'yogurt'],
            'keto': ['high-carb'],
            'low-sodium': ['high-sodium'],
            'nut-free': ['nuts', 'almonds', 'peanuts', 'walnuts']
        }
    
    def generate_recipes(self, ingredients: List[str], dietary_preferences: List[str] = None,
                        max_cooking_time: int = 60, difficulty: str = 'any',
                        cuisine_type: str = 'any', servings: int = 2) -> List[Dict]:
        """Generate recipes based on user inputs"""
        try:
            # Build search criteria
            search_filter = self._build_search_filter(
                ingredients, dietary_preferences, max_cooking_time, difficulty, cuisine_type
            )
            
            # Find matching recipes
            recipes = list(self.db.recipes.find(search_filter))
            
            if not recipes:
                # Try with more flexible criteria
                recipes = self._find_flexible_matches(ingredients, dietary_preferences)
            
            # Score and rank recipes
            scored_recipes = self._score_recipes(recipes, ingredients, dietary_preferences)
            
            # Adjust serving sizes if needed
            adjusted_recipes = []
            for recipe in scored_recipes[:10]:  # Limit to top 10
                adjusted_recipe = self._adjust_serving_size(recipe, servings)
                adjusted_recipes.append(adjusted_recipe)
            
            return adjusted_recipes
            
        except Exception as e:
            logger.error(f"Error in recipe generation: {e}")
            return []
    
    def _build_search_filter(self, ingredients: List[str], dietary_preferences: List[str],
                           max_cooking_time: int, difficulty: str, cuisine_type: str) -> Dict:
        """Build MongoDB search filter"""
        search_filter = {}
        
        # Ingredient matching
        if ingredients:
            ingredient_patterns = []
            for ingredient in ingredients:
                ingredient_patterns.append({
                    'ingredients.name': {'$regex': ingredient.lower(), '$options': 'i'}
                })
            search_filter['$or'] = ingredient_patterns
        
        # Dietary preferences
        if dietary_preferences:
            # Ensure all dietary preferences are met
            search_filter['dietary_tags'] = {'$all': dietary_preferences}
        
        # Cooking time constraint
        if max_cooking_time:
            search_filter['cooking_time'] = {'$lte': max_cooking_time}
        
        # Difficulty filter
        if difficulty and difficulty != 'any':
            search_filter['difficulty'] = difficulty
        
        # Cuisine type filter
        if cuisine_type and cuisine_type != 'any':
            search_filter['cuisine_type'] = cuisine_type
        
        return search_filter
    
    def _find_flexible_matches(self, ingredients: List[str], dietary_preferences: List[str]) -> List[Dict]:
        """Find recipes with more flexible matching"""
        try:
            # Try partial ingredient matching
            search_filter = {}
            
            if ingredients:
                # Match recipes that contain at least one ingredient
                ingredient_patterns = []
                for ingredient in ingredients:
                    ingredient_patterns.append({
                        'ingredients.name': {'$regex': ingredient.lower(), '$options': 'i'}
                    })
                search_filter['$or'] = ingredient_patterns
            
            # Apply dietary restrictions
            if dietary_preferences:
                search_filter['dietary_tags'] = {'$in': dietary_preferences}
            
            recipes = list(self.db.recipes.find(search_filter).limit(20))
            
            if not recipes and dietary_preferences:
                # Try without dietary restrictions but exclude conflicting ingredients
                excluded_ingredients = []
                for pref in dietary_preferences:
                    if pref in self.dietary_restrictions:
                        excluded_ingredients.extend(self.dietary_restrictions[pref])
                
                if excluded_ingredients:
                    search_filter = {
                        'ingredients.name': {'$nin': excluded_ingredients}
                    }
                    recipes = list(self.db.recipes.find(search_filter).limit(20))
            
            return recipes
            
        except Exception as e:
            logger.error(f"Error in flexible matching: {e}")
            return []
    
    def _score_recipes(self, recipes: List[Dict], ingredients: List[str], 
                      dietary_preferences: List[str]) -> List[Dict]:
        """Score and rank recipes based on relevance"""
        scored_recipes = []
        
        for recipe in recipes:
            score = 0
            
            # Ingredient matching score
            recipe_ingredients = [ing['name'].lower() for ing in recipe.get('ingredients', [])]
            matched_ingredients = 0
            
            for user_ingredient in ingredients:
                for recipe_ingredient in recipe_ingredients:
                    if user_ingredient.lower() in recipe_ingredient or recipe_ingredient in user_ingredient.lower():
                        matched_ingredients += 1
                        break
            
            if ingredients:
                ingredient_score = (matched_ingredients / len(ingredients)) * 50
                score += ingredient_score
            
            # Dietary preference score
            recipe_tags = recipe.get('dietary_tags', [])
            matched_preferences = len(set(dietary_preferences or []) & set(recipe_tags))
            if dietary_preferences:
                dietary_score = (matched_preferences / len(dietary_preferences)) * 30
                score += dietary_score
            
            # Rating score
            rating_score = recipe.get('rating', 0) * 4
            score += rating_score
            
            # Review count bonus
            review_bonus = min(recipe.get('review_count', 0) * 0.1, 5)
            score += review_bonus
            
            # Difficulty preference (easier recipes get slight bonus)
            difficulty_map = {'easy': 3, 'medium': 2, 'hard': 1}
            difficulty_score = difficulty_map.get(recipe.get('difficulty', 'medium'), 2)
            score += difficulty_score
            
            # Cooking time preference (quicker recipes get slight bonus)
            cooking_time = recipe.get('cooking_time', 30)
            time_score = max(0, 10 - (cooking_time / 6))  # Bonus decreases with time
            score += time_score
            
            recipe['relevance_score'] = score
            scored_recipes.append(recipe)
        
        # Sort by score (descending)
        scored_recipes.sort(key=lambda x: x['relevance_score'], reverse=True)
        
        return scored_recipes
    
    def _adjust_serving_size(self, recipe: Dict, target_servings: int) -> Dict:
        """Adjust recipe ingredients for different serving sizes"""
        current_servings = recipe.get('servings', 2)
        
        if current_servings == target_servings:
            return recipe
        
        multiplier = target_servings / current_servings
        adjusted_recipe = recipe.copy()
        adjusted_recipe['servings'] = target_servings
        
        # Adjust ingredient quantities
        adjusted_ingredients = []
        for ingredient in recipe.get('ingredients', []):
            adjusted_ingredient = ingredient.copy()
            
            # Try to parse and adjust numeric quantities
            amount_str = str(ingredient.get('amount', '1'))
            try:
                # Handle fractions and decimals
                if '/' in amount_str:
                    parts = amount_str.split('/')
                    if len(parts) == 2:
                        amount = float(parts[0]) / float(parts[1])
                    else:
                        amount = float(amount_str.replace('/', '.'))
                else:
                    amount = float(amount_str)
                
                new_amount = amount * multiplier
                
                # Format the new amount nicely
                if new_amount == int(new_amount):
                    adjusted_ingredient['amount'] = str(int(new_amount))
                else:
                    adjusted_ingredient['amount'] = f"{new_amount:.2f}"
                    
            except (ValueError, ZeroDivisionError):
                # If we can't parse the amount, keep original
                adjusted_ingredient['amount'] = amount_str
            
            adjusted_ingredients.append(adjusted_ingredient)
        
        adjusted_recipe['ingredients'] = adjusted_ingredients
        
        # Adjust nutrition information
        if 'nutrition' in recipe:
            adjusted_nutrition = {}
            for nutrient, value in recipe['nutrition'].items():
                if isinstance(value, (int, float)):
                    adjusted_nutrition[nutrient] = round(value * multiplier, 1)
                else:
                    adjusted_nutrition[nutrient] = value
            adjusted_recipe['nutrition'] = adjusted_nutrition
        
        return adjusted_recipe
    
    def get_suggestions(self, ingredients: List[str], dietary_preferences: List[str]) -> Dict:
        """Get suggestions when no recipes are found"""
        suggestions = {
            'alternative_ingredients': [],
            'recipe_ideas': [],
            'dietary_options': []
        }
        
        try:
            # Suggest ingredient alternatives
            for ingredient in ingredients:
                if ingredient.lower() in self.ingredient_substitutions:
                    suggestions['alternative_ingredients'].append({
                        'original': ingredient,
                        'alternatives': self.ingredient_substitutions[ingredient.lower()]
                    })
            
            # Suggest popular recipes with similar dietary tags
            if dietary_preferences:
                popular_recipes = list(self.db.recipes.find({
                    'dietary_tags': {'$in': dietary_preferences}
                }).sort('rating', -1).limit(5))
                
                suggestions['recipe_ideas'] = [
                    {'title': recipe['title'], 'id': str(recipe['_id'])}
                    for recipe in popular_recipes
                ]
            
            # Suggest related dietary options
            all_dietary_tags = self.db.recipes.distinct('dietary_tags')
            suggestions['dietary_options'] = [
                tag for tag in all_dietary_tags 
                if tag not in dietary_preferences
            ][:10]
            
        except Exception as e:
            logger.error(f"Error getting suggestions: {e}")
        
        return suggestions
    
    def generate_custom_recipe(self, ingredients: List[str], dietary_preferences: List[str],
                             cuisine_type: str = 'international') -> Dict:
        """Generate a completely new recipe based on ingredients"""
        try:
            # This is a simplified version - in a real implementation,
            # you might use more sophisticated AI/ML models
            
            # Basic recipe structure
            recipe = {
                'title': self._generate_recipe_title(ingredients, cuisine_type),
                'ingredients': self._format_ingredients(ingredients),
                'instructions': self._generate_instructions(ingredients, cuisine_type),
                'cooking_time': self._estimate_cooking_time(ingredients),
                'prep_time': self._estimate_prep_time(ingredients),
                'servings': 2,
                'dietary_tags': dietary_preferences,
                'cuisine_type': cuisine_type,
                'difficulty': 'medium',
                'is_generated': True
            }
            
            return recipe
            
        except Exception as e:
            logger.error(f"Error generating custom recipe: {e}")
            return {}
    
    def _generate_recipe_title(self, ingredients: List[str], cuisine_type: str) -> str:
        """Generate a recipe title based on main ingredients"""
        main_ingredients = ingredients[:3]  # Use first 3 ingredients
        
        if cuisine_type == 'mediterranean':
            return f"Mediterranean {' and '.join(main_ingredients).title()} Bowl"
        elif cuisine_type == 'asian':
            return f"Asian-Style {' '.join(main_ingredients).title()} Stir-Fry"
        elif cuisine_type == 'mexican':
            return f"{' '.join(main_ingredients).title()} Fiesta Bowl"
        else:
            return f"Fresh {' and '.join(main_ingredients).title()} Recipe"
    
    def _format_ingredients(self, ingredients: List[str]) -> List[Dict]:
        """Format ingredients into recipe format"""
        formatted = []
        for ingredient in ingredients:
            formatted.append({
                'name': ingredient.lower(),
                'amount': '1',
                'unit': 'cup'  # Default unit - could be improved with better parsing
            })
        return formatted
    
    def _generate_instructions(self, ingredients: List[str], cuisine_type: str) -> List[str]:
        """Generate basic cooking instructions"""
        instructions = [
            "Prepare all ingredients by washing and chopping as needed",
            f"Heat oil in a large pan over medium heat",
            f"Add {ingredients[0]} and cook for 3-5 minutes",
        ]
        
        if len(ingredients) > 1:
            instructions.append(f"Add {', '.join(ingredients[1:])} and continue cooking")
        
        instructions.extend([
            "Season with salt and pepper to taste",
            "Cook until all ingredients are tender",
            "Serve hot and enjoy!"
        ])
        
        return instructions
    
    def _estimate_cooking_time(self, ingredients: List[str]) -> int:
        """Estimate cooking time based on ingredients"""
        # Simple estimation - could be improved with ingredient database
        base_time = 15
        additional_time = len(ingredients) * 2
        return min(base_time + additional_time, 45)
    
    def _estimate_prep_time(self, ingredients: List[str]) -> int:
        """Estimate prep time based on number of ingredients"""
        return max(5, len(ingredients) * 2)