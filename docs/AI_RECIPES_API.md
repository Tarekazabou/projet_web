# AI Recipe Generation API

## Overview

The AI Recipe Generation API provides powerful, flexible endpoints for generating recipes using AI and RAG (Retrieval-Augmented Generation). All endpoints are **accessible from any page without authentication** - unauthenticated users default to `demo_user_01`.

## 🎯 Key Features

- **No Authentication Required**: All endpoints work without login (uses demo user)
- **Flexible Input**: Accept text queries, ingredients, or both
- **RAG-Enhanced**: Leverages 13,000+ recipe database for better results
- **User Preferences**: Can optionally use stored user preferences
- **Fridge Integration**: Can automatically fetch ingredients from user's fridge
- **Fast & Slow Modes**: Choose between semantic search or instant generation

---

## 📡 Base URL

```
http://localhost:5000/api/recipes
```

---

## 🚀 Endpoints

### 1. Universal AI Generator (Recommended)

**`POST /generate-with-ai`**

The most flexible and powerful endpoint. Supports all generation scenarios.

**Request Body** (all fields optional):
```json
{
  "query": "I want a healthy Italian pasta dish",
  "ingredients": ["chicken", "tomatoes", "garlic"],
  "dietary_preferences": ["healthy", "low-carb"],
  "preferred_cuisines": ["italian", "mediterranean"],
  "max_cooking_time": 45,
  "difficulty": "medium",
  "servings": 4,
  "cooking_skill": "medium",
  "use_fridge": false,
  "use_preferences": false,
  "save_to_db": true,
  "userId": "optional_user_id"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "recipe": {
      "id": "abc123",
      "title": "Healthy Italian Chicken Pasta",
      "description": "...",
      "ingredients": [...],
      "instructions": [...],
      "cookTimeMinutes": 30,
      "servings": 4,
      "difficulty": "medium",
      "generatedByAI": true,
      "userId": "demo_user_01",
      "basedOnRecipes": ["Recipe 1", "Recipe 2"],
      "retrievalStrategy": "semantic"
    },
    "generation_context": {
      "similar_recipes_found": 5,
      "retrieval_strategy": "semantic",
      "user_id": "demo_user_01",
      "used_fridge": false,
      "used_preferences": false,
      "ingredients_count": 3
    },
    "message": "Recipe generated successfully with AI! 🎉"
  }
}
```

**Use Cases**:
- Recipe Generator page with text input
- Ingredient-based generation
- Combining text query + specific ingredients
- Using fridge ingredients + preferences

---

### 2. Simple Fast Generator

**`POST /generate-simple`**

Fast recipe generation without semantic search. Best for quick results.

**Request Body**:
```json
{
  "ingredients": ["chicken", "rice", "vegetables"],
  "dietary_preferences": ["healthy"],
  "max_cooking_time": 30,
  "servings": 4,
  "difficulty": "easy",
  "save_to_db": true,
  "userId": "optional_user_id"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "recipe": {...},
    "message": "Simple recipe generated quickly! ⚡"
  }
}
```

**Use Cases**:
- Quick recipe generation
- When semantic search is not needed
- Simple ingredient-based recipes

---

### 3. Generate from Text

**`POST /generate-from-text`**

Natural language recipe generation from text descriptions.

**Request Body**:
```json
{
  "query": "I want a healthy Italian pasta with chicken and vegetables",
  "save_to_db": true,
  "userId": "optional_user_id"
}
```

**Response**: Same as universal generator

**Use Cases**:
- Recipe Generator page
- Natural language input
- User describes what they want

---

### 4. Generate from Ingredients

**`POST /generate-from-ingredients`**

Generate recipes from a list of ingredients.

**Request Body**:
```json
{
  "ingredients": ["chicken", "rice", "broccoli"],
  "dietary_preferences": ["healthy"],
  "max_cooking_time": 30,
  "servings": 4,
  "save_to_db": true,
  "userId": "optional_user_id"
}
```

**Response**: Same as universal generator

**Use Cases**:
- "What can I make with these?" scenarios
- Ingredient-focused generation
- Your Fridge page

---

### 5. Generate from Fridge

**`POST /generate-from-fridge`**

Automatically uses ingredients from user's fridge and their preferences.

**Request Body** (all optional):
```json
{
  "additional_ingredients": ["pasta"],
  "userId": "optional_user_id",
  "save_to_db": true
}
```

**Response**: Same as universal generator

**Use Cases**:
- Your Fridge page "Suggest Recipes" feature
- Automatic ingredient fetching
- User preference integration

---

### 6. Test RAG Service

**`GET /test-rag`** or **`POST /test-rag`**

Test the RAG service and see similar recipes without generating.

**GET Request**: Uses default ingredients
**POST Request Body**:
```json
{
  "ingredients": ["chicken", "rice"],
  "query": "healthy pasta dish",
  "limit": 5
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "test_parameters": {
      "ingredients": ["chicken", "rice"],
      "query": "healthy pasta dish",
      "limit": 5
    },
    "search_method_used": "semantic",
    "similar_recipes_found": 5,
    "recipes": [...],
    "rag_service_status": "operational ✅",
    "message": "Found 5 similar recipes using semantic search"
  }
}
```

**Use Cases**:
- Testing RAG functionality
- Debugging recipe retrieval
- Seeing what recipes exist in database

---

### 7. Service Status

**`GET /status`**

Check if AI services are operational.

**Response**:
```json
{
  "success": true,
  "data": {
    "status": {
      "rag_service": "operational ✅",
      "ai_generator": "operational ✅",
      "gemini_api_key": "configured ✅",
      "recipes_csv": "found ✅",
      "recipe_count": 13000,
      "embeddings_cached": "yes ✅",
      "overall_status": "all systems operational ✅"
    },
    "available_endpoints": [
      "/api/recipes/generate-with-ai",
      "/api/recipes/generate-simple",
      "/api/recipes/generate-from-text",
      "/api/recipes/generate-from-ingredients",
      "/api/recipes/generate-from-fridge",
      "/api/recipes/test-rag",
      "/api/recipes/status"
    ]
  }
}
```

**Use Cases**:
- Health checks
- Debugging
- Verifying setup

---

## 🎨 Frontend Integration Examples

### Recipe Generator Page

```javascript
// Generate from text query
async function generateRecipe(query) {
  const response = await window.apiClient.post('/api/recipes/generate-from-text', {
    query: query,
    save_to_db: true
  });
  
  if (response.success) {
    displayRecipe(response.data.recipe);
  }
}
```

### Your Fridge Page

```javascript
// Generate from fridge ingredients
async function generateFromFridge() {
  const response = await window.apiClient.post('/api/recipes/generate-from-fridge', {
    save_to_db: true
  });
  
  if (response.success) {
    showRecipeModal(response.data.recipe);
  }
}
```

### Custom Ingredient Selection

```javascript
// Generate from selected ingredients
async function generateFromIngredients(ingredients) {
  const response = await window.apiClient.post('/api/recipes/generate-from-ingredients', {
    ingredients: ingredients,
    dietary_preferences: ['healthy'],
    max_cooking_time: 30,
    servings: 4
  });
  
  return response.data.recipe;
}
```

### Universal Generator with All Options

```javascript
// Full-featured generation
async function generateAdvancedRecipe(options) {
  const response = await window.apiClient.post('/api/recipes/generate-with-ai', {
    query: options.query,
    ingredients: options.ingredients,
    dietary_preferences: options.dietaryPrefs,
    preferred_cuisines: options.cuisines,
    max_cooking_time: options.maxTime,
    difficulty: options.difficulty,
    servings: options.servings,
    use_fridge: options.useFridge,
    use_preferences: options.usePreferences,
    save_to_db: true
  });
  
  return response.data.recipe;
}
```

---

## 🔧 Configuration

### Environment Variables

Required in `backend/.env`:

```env
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.0-flash-exp
GEMINI_EMBEDDING_MODEL=models/text-embedding-004
```

### Recipe Database

The RAG service requires:
- `13k-recipes.csv` in project root
- CSV should have columns: `title`, `ingredients`, `directions`, `NER`, etc.

---

## ⚡ Performance Tips

### Fast Generation
- Use `/generate-simple` for instant results
- Skip RAG when you don't need semantic search

### Best Results
- Use `/generate-with-ai` with both query and ingredients
- Enable `use_preferences: true` for personalized results
- Provide dietary preferences and cuisines

### Fridge Integration
- Use `/generate-from-fridge` for automatic ingredient fetching
- Combines user preferences + fridge items
- Prioritizes expiring ingredients

---

## 🐛 Troubleshooting

### AI Services Not Available

```bash
# Check status endpoint
curl http://localhost:5000/api/recipes/status

# Verify .env file
cat backend/.env

# Ensure GEMINI_API_KEY is set
```

### No Similar Recipes Found

The system has 3 fallback strategies:
1. **Semantic search** (best) - uses embeddings
2. **Ingredient-based** - matches ingredients
3. **Keyword search** - simple text matching

If all fail, generates recipe from scratch.

### RAG Service Issues

```bash
# Test RAG service
curl http://localhost:5000/api/recipes/test-rag

# Check if 13k-recipes.csv exists
ls 13k-recipes.csv

# Verify recipe count in status
curl http://localhost:5000/api/recipes/status
```

---

## 📊 Retrieval Strategies

The system automatically selects the best retrieval strategy:

| Strategy | Description | When Used |
|----------|-------------|-----------|
| `semantic` | Embedding-based semantic search | Query + embeddings available |
| `ingredient-fallback` | Direct ingredient matching | Semantic search fails |
| `keyword-fallback` | Simple keyword matching | All else fails |
| `none` | No similar recipes found | Generates from scratch |

---

## 🎯 Best Practices

### For Recipe Generator Page
- Use `/generate-from-text` with natural language
- Allow users to add specific ingredients
- Provide dietary preference options

### For Your Fridge Page
- Use `/generate-from-fridge` for automatic integration
- Show which fridge ingredients are being used
- Highlight expiring ingredients in results

### For Meal Planner
- Use `/generate-with-ai` with preferences enabled
- Set appropriate servings and cooking time
- Filter by difficulty based on user skill

### For Custom Integrations
- Start with `/test-rag` to verify setup
- Check `/status` for service health
- Use appropriate endpoint for your use case

---

## 🔐 Authentication (Optional)

All endpoints work without authentication (uses demo user).

To use with authenticated users:
1. Send `Authorization: Bearer <firebase_token>` header
2. Or send `X-User-Id: <user_id>` header
3. Or include `userId` in request body

If not provided, defaults to `demo_user_01`.

---

## 📝 Recipe Schema

Generated recipes follow this structure:

```json
{
  "id": "abc123",
  "title": "Recipe Title",
  "description": "Short description",
  "ingredients": [
    {"name": "ingredient", "amount": "1", "unit": "cup"}
  ],
  "instructions": [
    {"step": 1, "instruction": "Do this..."}
  ],
  "prepTimeMinutes": 15,
  "cookTimeMinutes": 30,
  "servings": 4,
  "difficulty": "medium",
  "cuisine": "Italian",
  "dietaryPreferences": ["healthy", "low-carb"],
  "nutritionInfo": {
    "calories": 450,
    "protein": 30,
    "carbs": 40,
    "fat": 15
  },
  "generatedByAI": true,
  "userId": "demo_user_01",
  "createdAt": "2025-10-31T...",
  "basedOnRecipes": ["Recipe 1", "Recipe 2"],
  "retrievalStrategy": "semantic"
}
```

---

## 🚀 Quick Start

```javascript
// 1. Check if services are ready
const status = await fetch('http://localhost:5000/api/recipes/status');
console.log(await status.json());

// 2. Generate a simple recipe
const response = await fetch('http://localhost:5000/api/recipes/generate-simple', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    ingredients: ['chicken', 'rice', 'vegetables']
  })
});
const result = await response.json();
console.log(result.data.recipe);

// 3. Test RAG retrieval
const rag = await fetch('http://localhost:5000/api/recipes/test-rag');
console.log(await rag.json());
```

---

**Last Updated**: October 31, 2025  
**API Version**: 1.0  
**Support**: All endpoints accessible without authentication
