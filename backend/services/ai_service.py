"""
AI Service for Recipe Generation using Google Gemini
Free tier: 60 requests per minute
"""
import os
import json
import logging
from typing import Dict, Any, Optional
from google import generativeai as genai

logger = logging.getLogger(__name__)

class AIRecipeGenerator:
    """Generate recipes using Google Gemini AI"""
    
    def __init__(self, api_key: Optional[str] = None):
        """Initialize Gemini AI"""
        self.api_key = api_key or os.getenv('GEMINI_API_KEY')
        
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")
        
        genai.configure(api_key=self.api_key)
        # Try gemini-1.5-flash as fallback (may have separate quota)
        self.model = genai.GenerativeModel('gemini-1.5-flash')
        logger.info("Gemini AI initialized successfully with gemini-1.5-flash")
    
    def generate_recipe(
        self,
        context_prompt: str,
        temperature: float = 0.9
    ) -> Dict[str, Any]:
        """
        Generate a recipe using Gemini with RAG context
        
        Args:
            context_prompt: The enhanced prompt with RAG context
            temperature: Creativity level (0.0-1.0, higher = more creative)
        
        Returns:
            Generated recipe as dictionary
        """
        try:
            # Add structured output format to prompt
            full_prompt = f"""{context_prompt}

Return the recipe in this EXACT JSON format (valid JSON only, no markdown):
{{
    "title": "Creative Recipe Name",
    "description": "Brief appetizing description (1-2 sentences)",
    "ingredients": [
        {{
            "name": "ingredient name",
            "quantity": "amount",
            "unit": "measurement unit"
        }}
    ],
    "instructions": [
        "Step 1: Detailed instruction",
        "Step 2: Detailed instruction",
        "..."
    ],
    "prepTimeMinutes": 15,
    "cookTimeMinutes": 30,
    "servingSize": 4,
    "difficulty": "easy",
    "cuisine": "cuisine type",
    "dietaryPreferences": ["tag1", "tag2"],
    "nutrition": {{
        "calories": 400,
        "protein": 25,
        "carbs": 45,
        "fat": 15,
        "fiber": 6
    }}
}}

Generate ONLY valid JSON, no additional text or markdown formatting."""

            # Generate with Gemini
            logger.info("Generating recipe with Gemini AI...")
            response = self.model.generate_content(
                full_prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=temperature,
                    top_p=0.95,
                    top_k=40,
                    max_output_tokens=2048,
                )
            )
            
            # Parse response
            recipe_text = response.text.strip()
            
            # Remove markdown code blocks if present
            if recipe_text.startswith('```'):
                # Remove ```json or ``` at start
                recipe_text = recipe_text.split('\n', 1)[1] if '\n' in recipe_text else recipe_text[3:]
                # Remove ``` at end
                if recipe_text.endswith('```'):
                    recipe_text = recipe_text[:-3]
                recipe_text = recipe_text.strip()
            
            # Parse JSON
            recipe_data = json.loads(recipe_text)
            
            logger.info(f"Successfully generated recipe: {recipe_data.get('title', 'Unknown')}")
            return recipe_data
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse AI response as JSON: {e}")
            logger.error(f"Response text: {response.text[:500]}")
            raise ValueError(f"AI returned invalid JSON: {str(e)}")
            
        except Exception as e:
            logger.error(f"Error generating recipe: {e}")
            raise
    
    def generate_simple_recipe(
        self,
        ingredients: list,
        dietary_prefs: list = None,
        cooking_time: int = None
    ) -> Dict[str, Any]:
        """
        Simple recipe generation without RAG (fallback)
        
        Args:
            ingredients: List of ingredients
            dietary_prefs: Dietary preferences
            cooking_time: Maximum cooking time in minutes
        
        Returns:
            Generated recipe
        """
        prompt = f"""Create a delicious recipe using these ingredients: {', '.join(ingredients)}

Requirements:
"""
        if dietary_prefs:
            prompt += f"- Dietary preferences: {', '.join(dietary_prefs)}\n"
        if cooking_time:
            prompt += f"- Maximum cooking time: {cooking_time} minutes\n"
        
        prompt += """
Return as JSON with this structure:
{
    "title": "Recipe Name",
    "description": "Brief description",
    "ingredients": [
        {"name": "ingredient", "quantity": "1", "unit": "cup"}
    ],
    "instructions": ["step 1", "step 2"],
    "prepTimeMinutes": 10,
    "cookTimeMinutes": 20,
    "servingSize": 4,
    "difficulty": "easy",
    "nutrition": {
        "calories": 300,
        "protein": 20,
        "carbs": 35,
        "fat": 10,
        "fiber": 5
    }
}"""
        
        return self.generate_recipe(prompt, temperature=0.8)
