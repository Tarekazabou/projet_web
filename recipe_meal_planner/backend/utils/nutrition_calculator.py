import logging
from typing import Dict, List, Optional
from datetime import datetime
import requests
import os

logger = logging.getLogger(__name__)

class NutritionCalculator:
    """Handles nutritional analysis and calculations"""
    
    def __init__(self, db):
        self.db = db
        self.usda_api_key = os.getenv('USDA_API_KEY')
        self.usda_base_url = 'https://api.nal.usda.gov/fdc/v1'
        
        # Common unit conversions to grams
        self.unit_conversions = {
            'cup': 240,     # 1 cup = 240g (approximate for liquids)
            'tablespoon': 15,
            'teaspoon': 5,
            'oz': 28.35,
            'lb': 453.59,
            'kg': 1000,
            'piece': 100,   # Default assumption
            'clove': 3,     # garlic clove
            'slice': 25,    # bread slice
            'fillet': 150,  # fish fillet
            'can': 400,     # standard can
        }
    
    def analyze_recipe(self, recipe_id: str) -> Dict:
        """Analyze nutritional content of a recipe"""
        try:
            recipe = self.db.recipes.find_one({'_id': recipe_id})
            if not recipe:
                return {}
            
            ingredients = recipe.get('ingredients', [])
            servings = recipe.get('servings', 1)
            
            return self.analyze_ingredients(ingredients, servings)
            
        except Exception as e:
            logger.error(f"Error analyzing recipe nutrition: {e}")
            return {}
    
    def analyze_ingredients(self, ingredients: List[Dict], servings: int = 1) -> Dict:
        """Analyze nutritional content of ingredient list"""
        try:
            total_nutrition = {
                'calories': 0,
                'protein': 0,
                'carbs': 0,
                'fat': 0,
                'fiber': 0,
                'sugar': 0,
                'sodium': 0,
                'calcium': 0,
                'iron': 0,
                'vitamin_c': 0
            }
            
            ingredient_breakdown = []
            
            for ingredient in ingredients:
                ingredient_name = ingredient.get('name', '').lower()
                amount = self._parse_amount(ingredient.get('amount', '1'))
                unit = ingredient.get('unit', 'g').lower()
                
                # Convert to grams
                grams = self._convert_to_grams(amount, unit, ingredient_name)
                
                # Get nutrition data for ingredient
                nutrition_data = self._get_ingredient_nutrition(ingredient_name)
                
                if nutrition_data:
                    # Calculate nutrition for this ingredient
                    ingredient_nutrition = self._calculate_portion_nutrition(
                        nutrition_data, grams
                    )
                    
                    # Add to totals
                    for nutrient, value in ingredient_nutrition.items():
                        if nutrient in total_nutrition:
                            total_nutrition[nutrient] += value
                    
                    ingredient_breakdown.append({
                        'name': ingredient_name,
                        'amount': amount,
                        'unit': unit,
                        'grams': grams,
                        'nutrition': ingredient_nutrition
                    })
            
            # Calculate per serving
            per_serving = {}
            for nutrient, value in total_nutrition.items():
                per_serving[nutrient] = round(value / servings, 1)
            
            return {
                'per_serving': per_serving,
                'total': total_nutrition,
                'servings': servings,
                'ingredient_breakdown': ingredient_breakdown,
                'calculated_at': self.get_current_timestamp()
            }
            
        except Exception as e:
            logger.error(f"Error analyzing ingredients: {e}")
            return {}
    
    def _get_ingredient_nutrition(self, ingredient_name: str) -> Dict:
        """Get nutrition data for an ingredient"""
        try:
            # First check local database
            ingredient = self.db.ingredients.find_one({'name': ingredient_name})
            
            if ingredient:
                return ingredient.get('nutrition_per_100g', {})
            
            # If not found locally, try USDA API
            if self.usda_api_key:
                usda_data = self._fetch_usda_nutrition(ingredient_name)
                if usda_data:
                    # Store in local database for future use
                    self._store_ingredient_nutrition(ingredient_name, usda_data)
                    return usda_data
            
            # Fallback to estimated values
            return self._get_estimated_nutrition(ingredient_name)
            
        except Exception as e:
            logger.error(f"Error getting ingredient nutrition: {e}")
            return {}
    
    def _fetch_usda_nutrition(self, ingredient_name: str) -> Dict:
        """Fetch nutrition data from USDA API"""
        try:
            if not self.usda_api_key:
                return {}
            
            # Search for ingredient
            search_url = f"{self.usda_base_url}/foods/search"
            params = {
                'query': ingredient_name,
                'api_key': self.usda_api_key,
                'dataType': ['Foundation', 'SR Legacy'],
                'pageSize': 1
            }
            
            response = requests.get(search_url, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                foods = data.get('foods', [])
                
                if foods:
                    food_item = foods[0]
                    nutrients = food_item.get('foodNutrients', [])
                    
                    # Map USDA nutrients to our format
                    nutrition_map = {
                        'Energy': 'calories',
                        'Protein': 'protein',
                        'Carbohydrate, by difference': 'carbs',
                        'Total lipid (fat)': 'fat',
                        'Fiber, total dietary': 'fiber',
                        'Sugars, total': 'sugar',
                        'Sodium, Na': 'sodium',
                        'Calcium, Ca': 'calcium',
                        'Iron, Fe': 'iron',
                        'Vitamin C, total ascorbic acid': 'vitamin_c'
                    }
                    
                    nutrition_data = {}
                    for nutrient in nutrients:
                        nutrient_name = nutrient.get('nutrientName', '')
                        if nutrient_name in nutrition_map:
                            value = nutrient.get('value', 0)
                            nutrition_data[nutrition_map[nutrient_name]] = value
                    
                    return nutrition_data
            
            return {}
            
        except Exception as e:
            logger.error(f"Error fetching USDA nutrition: {e}")
            return {}
    
    def _get_estimated_nutrition(self, ingredient_name: str) -> Dict:
        """Get estimated nutrition values for common ingredients"""
        # Simplified nutrition estimates per 100g
        estimates = {
            'quinoa': {'calories': 368, 'protein': 14.1, 'carbs': 64.2, 'fat': 6.1, 'fiber': 7.0},
            'rice': {'calories': 365, 'protein': 7.1, 'carbs': 80.0, 'fat': 0.7, 'fiber': 1.3},
            'chicken breast': {'calories': 165, 'protein': 31.0, 'carbs': 0, 'fat': 3.6, 'fiber': 0},
            'salmon': {'calories': 208, 'protein': 25.4, 'carbs': 0, 'fat': 12.4, 'fiber': 0},
            'avocado': {'calories': 160, 'protein': 2.0, 'carbs': 8.5, 'fat': 14.7, 'fiber': 6.7},
            'spinach': {'calories': 23, 'protein': 2.9, 'carbs': 3.6, 'fat': 0.4, 'fiber': 2.2},
            'broccoli': {'calories': 34, 'protein': 2.8, 'carbs': 6.6, 'fat': 0.4, 'fiber': 2.6},
            'olive oil': {'calories': 884, 'protein': 0, 'carbs': 0, 'fat': 100, 'fiber': 0},
            'eggs': {'calories': 155, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0, 'fiber': 0},
            'milk': {'calories': 42, 'protein': 3.4, 'carbs': 5.0, 'fat': 1.0, 'fiber': 0}
        }
        
        for ingredient, nutrition in estimates.items():
            if ingredient in ingredient_name:
                return nutrition
        
        # Default values for unknown ingredients
        return {'calories': 50, 'protein': 2, 'carbs': 10, 'fat': 1, 'fiber': 1}
    
    def _store_ingredient_nutrition(self, ingredient_name: str, nutrition_data: Dict):
        """Store ingredient nutrition data in local database"""
        try:
            ingredient_doc = {
                'name': ingredient_name,
                'nutrition_per_100g': nutrition_data,
                'source': 'usda',
                'created_at': datetime.utcnow()
            }
            
            self.db.ingredients.update_one(
                {'name': ingredient_name},
                {'$set': ingredient_doc},
                upsert=True
            )
            
        except Exception as e:
            logger.error(f"Error storing ingredient nutrition: {e}")
    
    def _parse_amount(self, amount_str: str) -> float:
        """Parse amount string to float"""
        try:
            # Handle fractions
            if '/' in amount_str:
                parts = amount_str.split('/')
                if len(parts) == 2:
                    return float(parts[0]) / float(parts[1])
            
            # Handle mixed numbers (e.g., "1 1/2")
            if ' ' in amount_str and '/' in amount_str:
                parts = amount_str.split(' ')
                whole = float(parts[0])
                fraction_parts = parts[1].split('/')
                fraction = float(fraction_parts[0]) / float(fraction_parts[1])
                return whole + fraction
            
            # Regular number
            return float(amount_str)
            
        except (ValueError, ZeroDivisionError):
            return 1.0  # Default to 1 if parsing fails
    
    def _convert_to_grams(self, amount: float, unit: str, ingredient_name: str) -> float:
        """Convert ingredient amount to grams"""
        try:
            if unit == 'g' or unit == 'gram' or unit == 'grams':
                return amount
            
            if unit in self.unit_conversions:
                return amount * self.unit_conversions[unit]
            
            # Special cases based on ingredient
            if 'garlic' in ingredient_name and unit == 'clove':
                return amount * 3
            elif 'onion' in ingredient_name and unit == 'piece':
                return amount * 150
            elif 'potato' in ingredient_name and unit == 'piece':
                return amount * 200
            elif 'apple' in ingredient_name and unit == 'piece':
                return amount * 180
            
            # Default assumption for unknown units
            return amount * 100
            
        except Exception as e:
            logger.error(f"Error converting to grams: {e}")
            return amount * 100
    
    def _calculate_portion_nutrition(self, nutrition_per_100g: Dict, grams: float) -> Dict:
        """Calculate nutrition for specific portion size"""
        portion_nutrition = {}
        multiplier = grams / 100.0
        
        for nutrient, value in nutrition_per_100g.items():
            portion_nutrition[nutrient] = round(value * multiplier, 1)
        
        return portion_nutrition
    
    def calculate_daily_goals(self, age: int, gender: str, weight: float, 
                            height: float, activity_level: str, goal: str = 'maintain') -> Dict:
        """Calculate daily nutritional goals using Harris-Benedict equation"""
        try:
            # Calculate BMR (Basal Metabolic Rate)
            if gender.lower() == 'male':
                bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age)
            else:
                bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age)
            
            # Activity multipliers
            activity_multipliers = {
                'sedentary': 1.2,
                'light': 1.375,
                'moderate': 1.55,
                'active': 1.725,
                'very_active': 1.9
            }
            
            multiplier = activity_multipliers.get(activity_level, 1.55)
            maintenance_calories = bmr * multiplier
            
            # Adjust for goal
            if goal == 'lose':
                target_calories = maintenance_calories - 500  # 1 lb per week
            elif goal == 'gain':
                target_calories = maintenance_calories + 500  # 1 lb per week
            else:
                target_calories = maintenance_calories
            
            # Calculate macro goals (general recommendations)
            protein_calories = target_calories * 0.25  # 25% protein
            carb_calories = target_calories * 0.45      # 45% carbs
            fat_calories = target_calories * 0.30       # 30% fat
            
            goals = {
                'calories': round(target_calories),
                'protein': round(protein_calories / 4),  # 4 calories per gram
                'carbs': round(carb_calories / 4),       # 4 calories per gram
                'fat': round(fat_calories / 9),          # 9 calories per gram
                'fiber': round(weight * 0.5),            # 0.5g per kg body weight
                'sodium': 2300,                          # mg, general recommendation
                'sugar': round(target_calories * 0.05 / 4)  # 5% of calories
            }
            
            return goals
            
        except Exception as e:
            logger.error(f"Error calculating daily goals: {e}")
            return {}
    
    def calculate_daily_intake(self, meals: Dict) -> Dict:
        """Calculate total daily nutrition from meals"""
        try:
            daily_total = {
                'calories': 0,
                'protein': 0,
                'carbs': 0,
                'fat': 0,
                'fiber': 0,
                'sugar': 0,
                'sodium': 0
            }
            
            for meal_type, recipe_ids in meals.items():
                if isinstance(recipe_ids, list):
                    for recipe_id in recipe_ids:
                        nutrition = self.analyze_recipe(recipe_id)
                        if nutrition and 'per_serving' in nutrition:
                            for nutrient, value in nutrition['per_serving'].items():
                                if nutrient in daily_total:
                                    daily_total[nutrient] += value
            
            return daily_total
            
        except Exception as e:
            logger.error(f"Error calculating daily intake: {e}")
            return {}
    
    def calculate_progress(self, actual_intake: Dict, goals: Dict) -> Dict:
        """Calculate progress towards nutritional goals"""
        try:
            progress = {}
            
            for nutrient, goal in goals.items():
                actual = actual_intake.get(nutrient, 0)
                if goal > 0:
                    percentage = min((actual / goal) * 100, 200)  # Cap at 200%
                    progress[nutrient] = {
                        'actual': actual,
                        'goal': goal,
                        'percentage': round(percentage, 1),
                        'remaining': max(0, goal - actual),
                        'status': self._get_progress_status(percentage)
                    }
            
            return progress
            
        except Exception as e:
            logger.error(f"Error calculating progress: {e}")
            return {}
    
    def _get_progress_status(self, percentage: float) -> str:
        """Get progress status based on percentage"""
        if percentage < 50:
            return 'low'
        elif percentage < 90:
            return 'moderate'
        elif percentage <= 110:
            return 'good'
        else:
            return 'high'
    
    def get_nutrition_recommendations(self, goals: Dict) -> List[str]:
        """Get nutrition recommendations based on goals"""
        recommendations = []
        
        if goals.get('protein', 0) > 150:
            recommendations.append("Consider lean protein sources like chicken, fish, and legumes")
        
        if goals.get('fiber', 0) > 25:
            recommendations.append("Include plenty of vegetables, fruits, and whole grains for fiber")
        
        if goals.get('calories', 0) > 2500:
            recommendations.append("Focus on nutrient-dense foods to meet your high calorie needs")
        
        recommendations.append("Stay hydrated with at least 8 glasses of water daily")
        recommendations.append("Consider timing your meals around your activity schedule")
        
        return recommendations
    
    def get_meal_recommendations(self, current_intake: Dict, goals: Dict) -> List[str]:
        """Get meal recommendations based on current progress"""
        recommendations = []
        
        for nutrient, goal in goals.items():
            current = current_intake.get(nutrient, 0)
            remaining = goal - current
            
            if remaining > 0:
                if nutrient == 'protein' and remaining > 20:
                    recommendations.append(f"Add protein-rich foods (need {remaining:.1f}g more protein)")
                elif nutrient == 'fiber' and remaining > 10:
                    recommendations.append(f"Include more vegetables and whole grains (need {remaining:.1f}g more fiber)")
                elif nutrient == 'calories' and remaining > 300:
                    recommendations.append(f"Consider adding a healthy snack (need {remaining:.0f} more calories)")
        
        return recommendations
    
    def calculate_nutrition_analytics(self, history: List[Dict]) -> Dict:
        """Calculate nutrition analytics from history"""
        try:
            if not history:
                return {}
            
            # Calculate averages
            totals = {}
            count = len(history)
            
            for entry in history:
                nutrition = entry.get('total_nutrition', {})
                for nutrient, value in nutrition.items():
                    if nutrient not in totals:
                        totals[nutrient] = 0
                    totals[nutrient] += value
            
            averages = {}
            for nutrient, total in totals.items():
                averages[nutrient] = round(total / count, 1)
            
            # Calculate trends (simplified)
            trends = {}
            if len(history) >= 7:
                recent_avg = {}
                older_avg = {}
                
                recent = history[:3]
                older = history[-3:]
                
                for nutrient in totals.keys():
                    recent_total = sum(entry.get('total_nutrition', {}).get(nutrient, 0) for entry in recent)
                    older_total = sum(entry.get('total_nutrition', {}).get(nutrient, 0) for entry in older)
                    
                    recent_avg[nutrient] = recent_total / len(recent)
                    older_avg[nutrient] = older_total / len(older)
                    
                    if older_avg[nutrient] > 0:
                        change = ((recent_avg[nutrient] - older_avg[nutrient]) / older_avg[nutrient]) * 100
                        trends[nutrient] = round(change, 1)
            
            return {
                'averages': averages,
                'trends': trends,
                'total_days': count
            }
            
        except Exception as e:
            logger.error(f"Error calculating nutrition analytics: {e}")
            return {}
    
    def compare_recipes(self, recipe_ids: List[str]) -> Dict:
        """Compare nutritional content of multiple recipes"""
        try:
            comparison = {}
            
            for recipe_id in recipe_ids:
                nutrition = self.analyze_recipe(recipe_id)
                if nutrition and 'per_serving' in nutrition:
                    recipe = self.db.recipes.find_one({'_id': recipe_id})
                    title = recipe.get('title', 'Unknown Recipe') if recipe else 'Unknown Recipe'
                    comparison[title] = nutrition['per_serving']
            
            return comparison
            
        except Exception as e:
            logger.error(f"Error comparing recipes: {e}")
            return {}
    
    def compare_ingredients(self, ingredient_lists: List[List[Dict]]) -> Dict:
        """Compare nutritional content of different ingredient combinations"""
        try:
            comparison = {}
            
            for i, ingredients in enumerate(ingredient_lists):
                nutrition = self.analyze_ingredients(ingredients, 1)
                if nutrition and 'per_serving' in nutrition:
                    comparison[f'Option {i+1}'] = nutrition['per_serving']
            
            return comparison
            
        except Exception as e:
            logger.error(f"Error comparing ingredients: {e}")
            return {}
    
    def get_current_timestamp(self) -> str:
        """Get current timestamp as ISO string"""
        return datetime.utcnow().isoformat()