"""
RAG Service for Recipe Generation
Uses the 13k-recipes.csv dataset to provide context for AI generation
"""
import pandas as pd
import numpy as np
from typing import List, Dict, Any
import json
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

class RecipeRAGService:
    """Retrieval-Augmented Generation service for recipes"""
    
    def __init__(self, csv_path: str = None):
        """Initialize RAG service with recipe dataset"""
        if csv_path is None:
            # Default path to the CSV file
            project_root = Path(__file__).parent.parent.parent
            csv_path = project_root / '13k-recipes.csv'
        
        self.csv_path = csv_path
        self.recipes_df = None
        self._load_recipes()
    
    def _load_recipes(self):
        """Load recipes from CSV file"""
        try:
            logger.info(f"Loading recipes from {self.csv_path}")
            self.recipes_df = pd.read_csv(self.csv_path)
            logger.info(f"Loaded {len(self.recipes_df)} recipes")
        except Exception as e:
            logger.error(f"Error loading recipes: {e}")
            self.recipes_df = pd.DataFrame()
    
    def retrieve_similar_recipes(
        self,
        ingredients: List[str],
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Retrieve recipes that match the given ingredients
        
        Args:
            ingredients: List of ingredients to search for
            limit: Maximum number of recipes to return
        
        Returns:
            List of matching recipes with scores
        """
        if self.recipes_df is None or self.recipes_df.empty:
            return []
        
        try:
            # Convert ingredients to lowercase for matching
            search_terms = [ing.lower() for ing in ingredients]
            
            # Score each recipe based on ingredient matches
            def score_recipe(recipe_ingredients):
                if pd.isna(recipe_ingredients):
                    return 0
                
                recipe_text = str(recipe_ingredients).lower()
                score = sum(1 for term in search_terms if term in recipe_text)
                return score
            
            # Calculate scores
            self.recipes_df['match_score'] = self.recipes_df['Ingredients'].apply(score_recipe)
            
            # Filter recipes with at least one match
            matching_recipes = self.recipes_df[self.recipes_df['match_score'] > 0]
            
            # Sort by score and get top results
            top_recipes = matching_recipes.nlargest(limit, 'match_score')
            
            # Convert to list of dictionaries
            results = []
            for _, recipe in top_recipes.iterrows():
                results.append({
                    'title': recipe['Title'],
                    'ingredients': recipe['Ingredients'],
                    'instructions': recipe['Instructions'],
                    'match_score': recipe['match_score']
                })
            
            logger.info(f"Retrieved {len(results)} matching recipes")
            return results
            
        except Exception as e:
            logger.error(f"Error retrieving recipes: {e}")
            return []
    
    def retrieve_by_keywords(
        self,
        keywords: List[str],
        limit: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Retrieve recipes based on keywords (broader search)
        
        Args:
            keywords: Keywords like 'healthy', 'quick', 'chicken', etc.
            limit: Maximum number of recipes to return
        
        Returns:
            List of matching recipes
        """
        if self.recipes_df is None or self.recipes_df.empty:
            return []
        
        try:
            search_terms = [kw.lower() for kw in keywords]
            
            def score_recipe(row):
                score = 0
                text = f"{row['Title']} {row['Ingredients']} {row['Instructions']}".lower()
                
                for term in search_terms:
                    if term in text:
                        score += 1
                
                return score
            
            self.recipes_df['keyword_score'] = self.recipes_df.apply(score_recipe, axis=1)
            
            matching = self.recipes_df[self.recipes_df['keyword_score'] > 0]
            top_recipes = matching.nlargest(limit, 'keyword_score')
            
            results = []
            for _, recipe in top_recipes.iterrows():
                results.append({
                    'title': recipe['Title'],
                    'ingredients': recipe['Ingredients'],
                    'instructions': recipe['Instructions'],
                    'keyword_score': recipe['keyword_score']
                })
            
            return results
            
        except Exception as e:
            logger.error(f"Error in keyword search: {e}")
            return []
    
    def build_context_prompt(
        self,
        similar_recipes: List[Dict[str, Any]],
        user_requirements: Dict[str, Any]
    ) -> str:
        """
        Build an enhanced prompt with retrieved recipes as context
        
        Args:
            similar_recipes: Retrieved recipes to use as examples
            user_requirements: User's requirements for the new recipe
        
        Returns:
            Formatted prompt string for AI
        """
        # Start with context from similar recipes
        context = "Here are some example recipes for inspiration:\n\n"
        
        for i, recipe in enumerate(similar_recipes[:3], 1):  # Use top 3
            context += f"Example {i}: {recipe['title']}\n"
            context += f"Ingredients: {recipe['ingredients'][:200]}...\n"  # Truncate long lists
            context += f"Instructions: {recipe['instructions'][:300]}...\n\n"  # Truncate
        
        # Add user requirements
        context += "\n---\n\nNow, create a NEW and UNIQUE recipe with these requirements:\n\n"
        
        if 'ingredients' in user_requirements:
            context += f"Required Ingredients: {', '.join(user_requirements['ingredients'])}\n"
        
        if 'dietary_preferences' in user_requirements:
            context += f"Dietary Preferences: {', '.join(user_requirements['dietary_preferences'])}\n"
        
        if 'max_cooking_time' in user_requirements:
            context += f"Maximum Cooking Time: {user_requirements['max_cooking_time']} minutes\n"
        
        if 'difficulty' in user_requirements:
            context += f"Difficulty Level: {user_requirements['difficulty']}\n"
        
        if 'servings' in user_requirements:
            context += f"Servings: {user_requirements['servings']}\n"
        
        context += "\nImportant Guidelines:\n"
        context += "- Be creative and make it different from the examples\n"
        context += "- Use the required ingredients as main components\n"
        context += "- Provide detailed step-by-step instructions\n"
        context += "- Include nutrition estimates (calories, protein, carbs, fat, fiber)\n"
        context += "- Make sure the recipe is practical and achievable\n"
        
        return context
    
    def get_random_recipes(self, limit: int = 5) -> List[Dict[str, Any]]:
        """Get random recipes for inspiration when no specific requirements"""
        if self.recipes_df is None or self.recipes_df.empty:
            return []
        
        try:
            random_recipes = self.recipes_df.sample(n=min(limit, len(self.recipes_df)))
            
            results = []
            for _, recipe in random_recipes.iterrows():
                results.append({
                    'title': recipe['Title'],
                    'ingredients': recipe['Ingredients'],
                    'instructions': recipe['Instructions']
                })
            
            return results
        except Exception as e:
            logger.error(f"Error getting random recipes: {e}")
            return []
