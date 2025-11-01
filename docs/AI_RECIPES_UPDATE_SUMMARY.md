# AI Recipe Endpoints - Universal Access Update

## 🎯 What Changed

All AI recipe generation endpoints in `backend/routes/ai_recipes.py` have been updated to:

✅ **Work from ALL pages** (no authentication required)
✅ **Support flexible inputs** (text, ingredients, or both)
✅ **Auto-fallback to demo user** when not authenticated
✅ **Include CORS support** with OPTIONS handling
✅ **Provide comprehensive documentation** with emojis and examples

---

## 📡 Available Endpoints

| Endpoint | Method | Purpose | Use Case |
|----------|--------|---------|----------|
| `/generate-with-ai` | POST | Universal generator | All scenarios |
| `/generate-simple` | POST | Fast generation (no RAG) | Quick results |
| `/generate-from-text` | POST | Natural language input | Recipe Generator page |
| `/generate-from-ingredients` | POST | From ingredient list | Your Fridge page |
| `/generate-from-fridge` | POST | Auto-fetch fridge items | Fridge integration |
| `/test-rag` | GET/POST | Test semantic search | Debugging |
| `/status` | GET | Service health check | Monitoring |

**Base URL**: `http://localhost:5000/api/recipes`

---

## 🚀 Key Features

### 1. No Authentication Required
```javascript
// Works without login - uses demo_user_01 automatically
fetch('/api/recipes/generate-from-text', {
  method: 'POST',
  body: JSON.stringify({ query: 'healthy pasta' })
})
```

### 2. Flexible Inputs
```javascript
// Text only
{ query: "I want Italian pasta" }

// Ingredients only
{ ingredients: ["chicken", "rice"] }

// Both combined
{ query: "healthy dinner", ingredients: ["chicken", "vegetables"] }

// With preferences
{ 
  query: "dinner", 
  use_fridge: true, 
  use_preferences: true 
}
```

### 3. Auto-Fallback User
```javascript
// No userId provided → uses demo_user_01
// userId in body → uses that user
// Authorization header → uses Firebase user
// X-User-Id header → uses that user
```

### 4. CORS Support
```javascript
// All endpoints support OPTIONS for CORS preflight
// Works from any frontend page
```

---

## 📂 Files Modified

### `backend/routes/ai_recipes.py`
- ✅ Removed auth requirements from all endpoints
- ✅ Added `get_user_id()` helper function
- ✅ Added OPTIONS method to all POST endpoints
- ✅ Added comprehensive docstrings with emojis
- ✅ Added 4 new convenience endpoints:
  - `/generate-from-text`
  - `/generate-from-ingredients`
  - `/generate-from-fridge`
  - `/status`
- ✅ Enhanced `/generate-with-ai` with more flexibility
- ✅ Enhanced `/generate-simple` with better docs
- ✅ Enhanced `/test-rag` with GET support
- ✅ Added detailed logging with emojis

### `backend/utils/auth.py`
- ✅ Added `get_current_user_id()` helper function
- ✅ Optional user ID retrieval without requiring auth

### `docs/AI_RECIPES_API.md` (NEW)
- ✅ Complete API documentation
- ✅ Request/response examples
- ✅ Frontend integration code
- ✅ Troubleshooting guide
- ✅ Best practices

### `docs/AI_RECIPES_UPDATE_SUMMARY.md` (NEW)
- ✅ This summary document

---

## 🎨 Frontend Integration

### Recipe Generator Page
```javascript
// Natural language generation
async function generateRecipe(query) {
  const response = await window.apiClient.post('/api/recipes/generate-from-text', {
    query: query
  });
  displayRecipe(response.data.recipe);
}
```

### Your Fridge Page
```javascript
// Automatic fridge + preferences
async function suggestFromFridge() {
  const response = await window.apiClient.post('/api/recipes/generate-from-fridge');
  showRecipeModal(response.data.recipe);
}
```

### Any Page with Ingredients
```javascript
// Custom ingredients
async function generateFromIngredients(ingredients) {
  const response = await window.apiClient.post('/api/recipes/generate-from-ingredients', {
    ingredients: ingredients,
    dietary_preferences: ['healthy']
  });
  return response.data.recipe;
}
```

---

## 🧪 Testing

### Test All Services
```bash
# 1. Check service status
curl http://localhost:5000/api/recipes/status

# 2. Test RAG retrieval
curl http://localhost:5000/api/recipes/test-rag

# 3. Generate simple recipe
curl -X POST http://localhost:5000/api/recipes/generate-simple \
  -H "Content-Type: application/json" \
  -d '{"ingredients":["chicken","rice"]}'

# 4. Generate from text
curl -X POST http://localhost:5000/api/recipes/generate-from-text \
  -H "Content-Type: application/json" \
  -d '{"query":"healthy pasta dish"}'
```

### Frontend Testing
```javascript
// Open browser console (F12)

// 1. Check status
fetch('/api/recipes/status').then(r => r.json()).then(console.log);

// 2. Test simple generation
fetch('/api/recipes/generate-simple', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({ingredients: ['chicken', 'rice']})
}).then(r => r.json()).then(console.log);

// 3. Test RAG
fetch('/api/recipes/test-rag').then(r => r.json()).then(console.log);
```

---

## 🔧 Configuration Required

### Backend `.env`
```env
GEMINI_API_KEY=your_api_key_here
GEMINI_MODEL=gemini-2.0-flash-exp
```

### Recipe Database
- Ensure `13k-recipes.csv` exists in project root
- RAG service loads this on initialization

---

## 📊 Endpoint Flow

### Universal Generator (`/generate-with-ai`)
```
1. Initialize services (RAG + AI)
2. Get/create user ID (demo if none)
3. [Optional] Load user preferences from DB
4. [Optional] Load fridge ingredients from DB
5. Validate inputs (query OR ingredients required)
6. Retrieve similar recipes (3 fallback strategies)
7. Build context prompt
8. Generate recipe with AI
9. Add metadata
10. Save to Firestore
11. Return recipe + context
```

### Simple Generator (`/generate-simple`)
```
1. Initialize AI service only
2. Get/create user ID
3. Validate ingredients (required)
4. Generate recipe directly (no RAG)
5. Add metadata
6. Save to Firestore
7. Return recipe
```

---

## 🎯 Benefits

### For Users
- ✅ Works from any page
- ✅ No login required for testing
- ✅ Instant recipe generation
- ✅ Flexible input options

### For Developers
- ✅ Easy integration from any component
- ✅ No auth token handling needed
- ✅ Comprehensive error messages
- ✅ Well-documented API

### For Testing
- ✅ Test endpoints without authentication
- ✅ Health check endpoint
- ✅ RAG testing endpoint
- ✅ Detailed logging

---

## 🚀 Next Steps

### Immediate
1. ✅ Test `/status` endpoint
2. ✅ Test `/test-rag` endpoint
3. ✅ Try generating a recipe

### Frontend Integration
1. Update Recipe Generator page to use `/generate-from-text`
2. Update Your Fridge page to use `/generate-from-fridge`
3. Add "Generate Recipe" buttons on other pages

### Enhancements
1. Add recipe rating/feedback
2. Add recipe favorites
3. Add recipe sharing
4. Add meal plan integration

---

## 📝 API Response Structure

All endpoints return consistent response format:

### Success
```json
{
  "success": true,
  "data": {
    "recipe": {...},
    "generation_context": {...},
    "message": "Recipe generated successfully! 🎉"
  }
}
```

### Error
```json
{
  "success": false,
  "error": "Error message",
  "message": "Human-readable message"
}
```

---

## 🐛 Troubleshooting

### Service Not Initialized
```bash
# Check .env file
cat backend/.env

# Verify GEMINI_API_KEY
# Restart backend server
python backend/run_server.py
```

### RAG Service Issues
```bash
# Check if CSV exists
ls 13k-recipes.csv

# Test RAG endpoint
curl http://localhost:5000/api/recipes/test-rag
```

### CORS Errors
```javascript
// All endpoints support OPTIONS
// Check browser console for specific errors
// Verify backend is running on correct port
```

---

## 📚 Documentation

- **Full API Docs**: `docs/AI_RECIPES_API.md`
- **Project Structure**: `PROJECT_STRUCTURE.md`
- **Debug Guide**: `DEBUG_GUIDE.md`

---

**Last Updated**: October 31, 2025  
**Version**: 1.0  
**Status**: ✅ Ready for use from all pages
