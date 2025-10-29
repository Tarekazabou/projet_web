# RAG + AI Recipe Generation Implementation Plan

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     USER INTERFACE                          │
│  (Ingredients, Dietary Prefs, Cooking Time, Difficulty)    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              BACKEND API ENDPOINT                           │
│         POST /api/recipes/generate-with-ai                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              RAG RETRIEVAL PHASE                            │
│  1. Query Firestore for similar recipes                    │
│  2. Vector similarity search (optional)                     │
│  3. Get top 3-5 most relevant recipes                       │
│  4. Extract: ingredients, instructions, nutrition           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│           CONTEXT AUGMENTATION                              │
│  Build AI prompt with:                                      │
│  • User requirements                                        │
│  • Retrieved recipe examples                                │
│  • Dietary constraints                                      │
│  • Structured output format                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              AI GENERATION                                  │
│  Send to: OpenAI / Gemini / Claude                         │
│  • Generate unique recipe                                   │
│  • Include nutrition estimates                              │
│  • Follow user constraints                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│         POST-PROCESSING & VALIDATION                        │
│  • Parse JSON response                                      │
│  • Validate nutrition data                                  │
│  • Check ingredient availability                            │
│  • Save to Firestore                                        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              RETURN TO USER                                 │
│  New AI-generated recipe with all details                  │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Options

### Option 1: OpenAI GPT-4 (Recommended)
**Pros:**
- ✅ Best quality outputs
- ✅ Great at following structured formats
- ✅ Good nutrition estimates
- ✅ Reliable API

**Cons:**
- ❌ Costs money ($0.01 per 1K tokens)
- ❌ Requires API key

**Cost Estimate:** ~$0.02-0.05 per recipe generation

### Option 2: Google Gemini
**Pros:**
- ✅ FREE tier (60 requests/minute)
- ✅ Good quality
- ✅ Easy Firebase integration
- ✅ Multimodal (can analyze food images)

**Cons:**
- ⚠️ Slightly less consistent than GPT-4
- ⚠️ Newer, less proven

**Cost:** FREE for development!

### Option 3: Anthropic Claude
**Pros:**
- ✅ Excellent at structured output
- ✅ Very safe, follows constraints well
- ✅ Good for dietary restrictions

**Cons:**
- ❌ Costs money
- ⚠️ Slightly slower than GPT-4

### Option 4: Local LLM (Ollama)
**Pros:**
- ✅ Completely free
- ✅ No API keys needed
- ✅ Privacy (runs on your machine)

**Cons:**
- ❌ Requires local setup
- ❌ Slower
- ❌ Lower quality outputs

## Recommended: Google Gemini (FREE)

Since you're already using Firebase, Gemini integrates perfectly and is FREE!

## Code Structure

```
backend/
├── routes/
│   ├── recipes.py                    # Existing search
│   └── ai_recipes.py                 # NEW: AI generation
├── services/
│   ├── rag_service.py                # NEW: RAG retrieval logic
│   ├── ai_service.py                 # NEW: AI API integration
│   └── recipe_validator.py           # NEW: Validate AI outputs
└── prompts/
    └── recipe_generation.py          # NEW: Prompt templates
```

## Implementation Steps

### Phase 1: Basic AI Generation (No RAG)
1. Add Gemini API integration
2. Create simple prompt template
3. Generate basic recipes
4. Parse and save to Firestore

**Time:** 1-2 hours
**Complexity:** Low

### Phase 2: Add RAG Retrieval
1. Implement similarity search in Firestore
2. Retrieve relevant recipes as context
3. Enhance prompts with examples
4. Improve output quality

**Time:** 2-3 hours
**Complexity:** Medium

### Phase 3: Advanced Features
1. Add vector embeddings for better search
2. Implement caching for common requests
3. Add nutrition validation
4. User feedback loop for improvement

**Time:** 4-6 hours
**Complexity:** High

## Sample Code Preview

### Basic AI Recipe Generation (Gemini)

```python
import google.generativeai as genai

class AIRecipeGenerator:
    def __init__(self):
        genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
        self.model = genai.GenerativeModel('gemini-pro')
    
    def generate_recipe(self, ingredients, dietary_prefs, cooking_time):
        prompt = f"""
        Create a unique recipe using these ingredients: {ingredients}
        
        Requirements:
        - Dietary preferences: {dietary_prefs}
        - Maximum cooking time: {cooking_time} minutes
        - Include detailed instructions
        - Provide nutrition estimates
        
        Return as JSON with this structure:
        {{
            "title": "Recipe Name",
            "description": "Brief description",
            "ingredients": [
                {{"name": "ingredient", "quantity": 2, "unit": "cups"}}
            ],
            "instructions": ["step 1", "step 2"],
            "cookTimeMinutes": 30,
            "nutrition": {{
                "calories": 400,
                "protein": 25,
                "carbs": 45,
                "fat": 15
            }}
        }}
        """
        
        response = self.model.generate_content(prompt)
        return json.loads(response.text)
```

### With RAG Context

```python
def generate_recipe_with_rag(self, user_requirements):
    # 1. RETRIEVAL: Get similar recipes
    similar_recipes = self.retrieve_similar_recipes(
        user_requirements['ingredients'],
        user_requirements['dietary_prefs']
    )
    
    # 2. AUGMENTATION: Build context
    context = self.build_context(similar_recipes)
    
    # 3. GENERATION: Create prompt with context
    prompt = f"""
    Here are some example recipes for inspiration:
    {context}
    
    Now create a NEW unique recipe using:
    Ingredients: {user_requirements['ingredients']}
    Dietary preferences: {user_requirements['dietary_prefs']}
    Cooking time: {user_requirements['cooking_time']} minutes
    
    Make it creative and different from the examples!
    [structured output format...]
    """
    
    response = self.model.generate_content(prompt)
    return self.parse_and_validate(response.text)
```

## Dependencies to Add

```txt
# For OpenAI
openai==1.12.0

# For Google Gemini (recommended)
google-generativeai==0.3.2

# For Claude
anthropic==0.18.0

# For embeddings (optional, advanced)
sentence-transformers==2.3.1
```

## Environment Variables

```env
# Choose one:
GEMINI_API_KEY=your_key_here        # FREE tier available
OPENAI_API_KEY=your_key_here        # Paid
ANTHROPIC_API_KEY=your_key_here     # Paid
```

## Next Steps

Would you like me to:

1. ✨ **Implement Google Gemini integration** (FREE, recommended)
2. 🔧 **Implement OpenAI GPT-4** (paid, best quality)
3. 📚 **Build the full RAG system** with retrieval
4. 🚀 **Start with simple AI generation** (no RAG yet)

Let me know which option you prefer!
