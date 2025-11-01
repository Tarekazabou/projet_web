# 🤖 AI-Only Recipe System

## Overview

This project uses **AI generation only** for recipes. There are **no CRUD operations** (create, read, update, delete) or manual recipe management.

All recipes are generated dynamically using:
- **Gemini AI** for generation
- **RAG (Retrieval-Augmented Generation)** with 13k recipe database for context
- **User preferences** and fridge ingredients for personalization

---

## ✅ What's Included

### AI Generation Endpoints
- ✅ `/api/recipes/generate-with-ai` - Universal AI generator
- ✅ `/api/recipes/generate-simple` - Fast generation without RAG
- ✅ `/api/recipes/generate-from-text` - Natural language input
- ✅ `/api/recipes/generate-from-ingredients` - From ingredient list
- ✅ `/api/recipes/generate-from-fridge` - Auto-fetch fridge items
- ✅ `/api/recipes/test-rag` - Test semantic search
- ✅ `/api/recipes/status` - Service health check

### Features
- ✅ No authentication required
- ✅ Works from all pages
- ✅ Saves generated recipes to Firestore
- ✅ Uses user preferences when available
- ✅ Integrates with fridge ingredients

---

## ❌ What's Removed

### CRUD Operations (Removed)
- ❌ `/api/recipes/search` - Recipe search
- ❌ `/api/recipes/<id>` GET - Get recipe by ID
- ❌ `/api/recipes/` POST - Create manual recipe
- ❌ `/api/recipes/<id>` PUT - Update recipe
- ❌ `/api/recipes/<id>` DELETE - Delete recipe
- ❌ `/api/recipes/categories` - Get categories

### Why Removed?
- Focus on AI generation only
- Simpler codebase
- No manual recipe management needed
- All recipes are AI-generated on demand

---

## 🚀 How It Works

### 1. User Requests a Recipe
```javascript
// From any page
await window.apiClient.post('/api/recipes/generate-from-text', {
  query: 'healthy pasta dish'
})
```

### 2. AI Generates Recipe
- Searches 13k recipe database for similar recipes (RAG)
- Uses Gemini AI to generate new recipe
- Saves to Firestore automatically
- Returns complete recipe

### 3. Recipe is Ready
- User gets fresh AI-generated recipe
- Recipe is saved in database with ID
- Can be displayed, used in meal plans, etc.

---

## 📊 Recipe Flow

```
User Input → RAG Search (13k recipes) → AI Generation (Gemini) → Save to Firestore → Return Recipe
```

**No manual CRUD** - Everything is AI-generated!

---

## 🎯 Use Cases

### Recipe Generator Page
```javascript
// Generate from text query
const recipe = await generateFromText('Italian pasta');
```

### Your Fridge Page
```javascript
// Generate from fridge ingredients
const recipe = await generateFromFridge();
```

### Meal Planner
```javascript
// Generate with preferences
const recipe = await generateWithAI({
  query: 'dinner',
  use_preferences: true
});
```

---

## 💾 Data Storage

Generated recipes ARE saved to Firestore:
- Collection: `Recipe`
- Fields: All recipe data + metadata
- Metadata includes: `generatedByAI: true`, `userId`, `basedOnRecipes`, etc.

But there's no manual editing or management - only AI generation!

---

## 🔧 Configuration

```env
# Required in backend/.env
GEMINI_API_KEY=your_key_here
```

Files needed:
- `13k-recipes.csv` - For RAG context
- Firebase credentials JSON

---

## 📚 Documentation

- **Full API**: `docs/AI_RECIPES_API.md`
- **Quick Ref**: `docs/AI_RECIPES_QUICK_REF.md`
- **This Doc**: `docs/AI_ONLY_RECIPES.md`

---

**Status**: ✅ AI-only system active - No CRUD operations
**Last Updated**: October 31, 2025
