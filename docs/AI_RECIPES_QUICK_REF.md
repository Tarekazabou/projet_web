# 🚀 AI Recipes Quick Reference

## Base URL
```
http://localhost:5000/api/recipes
```

## Endpoints at a Glance

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/generate-with-ai` | POST | Universal generator (text + ingredients) | ❌ No |
| `/generate-simple` | POST | Fast generation (no RAG) | ❌ No |
| `/generate-from-text` | POST | Natural language input | ❌ No |
| `/generate-from-ingredients` | POST | From ingredient list | ❌ No |
| `/generate-from-fridge` | POST | Auto-fetch fridge items | ❌ No |
| `/test-rag` | GET/POST | Test semantic search | ❌ No |
| `/status` | GET | Service health check | ❌ No |

## Quick Examples

### Text Query
```javascript
await window.apiClient.post('/api/recipes/generate-from-text', {
  query: 'healthy Italian pasta'
})
```

### Ingredients
```javascript
await window.apiClient.post('/api/recipes/generate-from-ingredients', {
  ingredients: ['chicken', 'rice', 'vegetables']
})
```

### Fridge
```javascript
await window.apiClient.post('/api/recipes/generate-from-fridge')
```

### Fast
```javascript
await window.apiClient.post('/api/recipes/generate-simple', {
  ingredients: ['beef', 'potatoes']
})
```

### Status
```javascript
await fetch('/api/recipes/status').then(r => r.json())
```

## Response Format

```json
{
  "success": true,
  "data": {
    "recipe": {
      "id": "abc123",
      "title": "Recipe Title",
      "ingredients": [...],
      "instructions": [...],
      "generatedByAI": true
    },
    "generation_context": {...},
    "message": "Success! 🎉"
  }
}
```

## Configuration

```env
# backend/.env
GEMINI_API_KEY=your_key_here
```

## Troubleshooting

```bash
# Check status
curl http://localhost:5000/api/recipes/status

# Test RAG
curl http://localhost:5000/api/recipes/test-rag

# Verify module
python test_ai_endpoints.py
```

## Documentation

- **Full API**: `docs/AI_RECIPES_API.md`
- **Summary**: `docs/AI_RECIPES_UPDATE_SUMMARY.md`
- **Complete**: `docs/AI_RECIPES_COMPLETE.md`
- **This**: `docs/AI_RECIPES_QUICK_REF.md`

---

**✅ All endpoints work without authentication!**
