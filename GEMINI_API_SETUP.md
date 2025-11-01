# 🔑 Setting Up Gemini API Key for AI Recipe Generation

## Why You Need This

Your RAG (Retrieval-Augmented Generation) system uses Google's Gemini AI for two critical functions:

1. **Semantic Embeddings** - Converting recipes into vector representations for intelligent similarity search
2. **Recipe Generation** - Creating new recipes based on user requirements and retrieved context

Without the API key, the system falls back to basic keyword matching, which significantly reduces recipe quality.

---

## 📋 Step-by-Step Setup

### Step 1: Get Your Gemini API Key

1. **Go to Google AI Studio**: https://makersuite.google.com/app/apikey
2. **Sign in** with your Google account
3. **Click "Create API Key"**
4. **Copy the generated key** (it starts with something like `AIza...`)

⚠️ **Keep this key secret!** Don't share it or commit it to Git.

---

### Step 2: Create .env File in Backend Directory

```powershell
# Navigate to backend directory
cd backend

# Copy the example file
Copy-Item .env.example .env

# OR create manually:
New-Item .env -ItemType File
```

---

### Step 3: Add Your API Key to .env

Open `backend/.env` and replace `your_gemini_api_key_here` with your actual key:

```bash
# AI Services
GEMINI_API_KEY=AIzaSyD1234567890abcdefghijklmnopqrstuvw
GEMINI_MODEL=gemini-2.0-flash-exp
GEMINI_EMBEDDING_MODEL=models/text-embedding-004

# RAG Configuration
RAG_RECIPES_CSV=13k-recipes.csv
RAG_EMBEDDING_CACHE=backend/data/recipe_embeddings.npz
RAG_MAX_EMBEDDED_RECIPES=5000
RAG_TOP_K=5
```

---

### Step 4: Verify Configuration

Run the test script:

```powershell
python test_ai_recipe_generation.py
```

Expected output:
```
✅ AI Service Status Check Passed
   - RAG Service: available
   - AI Generator: available
   - Gemini API Key: configured ✅
   - Recipe Count: 13000
```

---

## 🚀 Understanding RAG Configuration

### `RAG_MAX_EMBEDDED_RECIPES`

Controls how many recipes from the 13k dataset get embedded:

- **1000** - Fast startup (10-15 minutes), decent quality
- **5000** - Balanced (30-45 minutes), good quality ⭐ **RECOMMENDED**
- **10000** - Slow startup (60-90 minutes), excellent quality
- **13000** - All recipes (120+ minutes), maximum quality

💡 **First time only!** Embeddings are cached, so subsequent startups are instant.

### `RAG_TOP_K`

Number of similar recipes retrieved for context:

- **3** - Fast, minimal context
- **5** - Balanced ⭐ **RECOMMENDED**
- **10** - More context, slower generation

---

## 🔍 How RAG Improves Recipe Generation

### Without RAG (Keyword Fallback)
```
User: "Italian pasta with chicken"
System: Matches "pasta" → Returns generic recipes
Result: Basic, generic recipe
```

### With RAG (Semantic Search)
```
User: "Italian pasta with chicken"
System: Understands context → Finds similar Italian chicken pasta dishes
        → Analyzes cooking techniques, ingredient combinations
        → Generates recipe inspired by 5 best matches
Result: Authentic, high-quality Italian chicken pasta recipe
```

---

## 📊 First Run - Building Embeddings

The first time you start the server with RAG enabled:

```
🔄 Building recipe embedding index for 5000 recipes...
✅ Embedded 250/5000 recipes
✅ Embedded 500/5000 recipes
...
✅ Embedded 5000/5000 recipes
💾 Saved embedding cache to backend/data/recipe_embeddings.npz
```

This creates `recipe_embeddings.npz` (~50-100MB) that gets loaded instantly on future runs.

---

## 🧪 Testing Your Setup

### Test 1: Check Status
```powershell
python test_ai_recipe_generation.py
```

### Test 2: Generate a Recipe
```powershell
# Open browser and test in Your Fridge page
# Or use curl:
curl -X POST http://localhost:5000/api/recipes/generate-with-ai ^
  -H "Content-Type: application/json" ^
  -d "{\"query\": \"healthy dinner\", \"ingredients\": [\"chicken\", \"broccoli\"]}"
```

### Test 3: Test RAG Retrieval
```powershell
python backend/test_rag_system.py
```

Expected output:
```
🔍 Testing RAG with semantic search
✅ Found 5 similar recipes
   1. Grilled Chicken with Broccoli
   2. Healthy Chicken Stir-Fry
   ...
```

---

## 🛠️ Troubleshooting

### Issue: "GEMINI_API_KEY not found"

**Solution:**
1. Verify `.env` file exists in `backend/` directory
2. Check key is not wrapped in quotes: `GEMINI_API_KEY=AIza...` (NOT `"AIza..."`)
3. Restart the server after adding the key

### Issue: "API key invalid"

**Solution:**
1. Verify key is correct (no extra spaces)
2. Check your Google Cloud billing is enabled
3. API might have usage limits - check Google AI Studio

### Issue: "Semantic retrieval unavailable"

**Solution:**
1. Check logs for embedding build errors
2. Verify `13k-recipes.csv` exists in project root
3. Check disk space (embeddings need ~100MB)

### Issue: Slow first startup

**Expected!** Building embeddings takes time:
- 1000 recipes: ~10-15 minutes
- 5000 recipes: ~30-45 minutes
- 13000 recipes: ~2 hours

💡 Subsequent startups are instant (loads from cache).

---

## 💰 Cost Considerations

### Gemini API Pricing (as of 2024)

**Free Tier:**
- 15 requests per minute
- 1 million tokens per day
- 1,500 requests per day

**Embedding Model (text-embedding-004):**
- Free for first 1M tokens/month
- $0.00001 per 1k tokens after

**Generation Model (gemini-2.0-flash-exp):**
- Free for first 2M tokens/month
- $0.00001 per 1k tokens after

💡 **For development, the free tier is more than enough!**

### Estimated Usage

**Building embeddings (one-time):**
- 5000 recipes × ~500 tokens = 2.5M tokens
- Cost: ~$0.025 (first time only, then cached)

**Recipe generation (per request):**
- ~5k tokens (context + generation)
- Cost: ~$0.00005 per recipe
- 1000 recipes = ~$0.05

---

## 🔒 Security Best Practices

### DO ✅
- Keep `.env` file local (it's in `.gitignore`)
- Use environment variables in production
- Rotate keys if exposed
- Set up billing alerts in Google Cloud

### DON'T ❌
- Commit `.env` to Git
- Share API keys publicly
- Use development keys in production
- Hardcode keys in source files

---

## 📈 Performance Tips

### Optimize Embedding Build Time
```bash
# Start with smaller dataset for testing
RAG_MAX_EMBEDDED_RECIPES=1000

# Increase once you're ready
RAG_MAX_EMBEDDED_RECIPES=5000
```

### Reduce API Calls
```bash
# Cache embeddings (done automatically)
# Use lower RAG_TOP_K for faster generation
RAG_TOP_K=3
```

### Monitor Usage
Check your usage at: https://console.cloud.google.com/apis/dashboard

---

## 🎯 Quick Start Summary

```powershell
# 1. Get API key from https://makersuite.google.com/app/apikey
# 2. Create .env file
cd backend
Copy-Item .env.example .env

# 3. Edit .env and add your key
# GEMINI_API_KEY=AIzaSy...

# 4. Restart server
cd ..
python backend/run_server.py

# 5. Test
python test_ai_recipe_generation.py
```

---

## 📚 Additional Resources

- **Gemini API Docs**: https://ai.google.dev/docs
- **Embedding Guide**: https://ai.google.dev/docs/embeddings
- **RAG Best Practices**: https://ai.google.dev/docs/retrieval_augmented_generation
- **Google AI Studio**: https://makersuite.google.com/

---

## ✅ Verification Checklist

- [ ] Got Gemini API key from Google AI Studio
- [ ] Created `backend/.env` file
- [ ] Added `GEMINI_API_KEY` to .env
- [ ] Restarted backend server
- [ ] Ran `test_ai_recipe_generation.py` successfully
- [ ] Status check shows "Gemini API Key: configured ✅"
- [ ] Embeddings building or cached
- [ ] AI recipe generation works

🎉 **Once all checked, your RAG system is fully operational!**
