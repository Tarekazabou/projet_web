# AI Recipe Generation - API Key Setup Guide

## Overview
Your app now features a user-friendly interface for configuring the Google Gemini API key directly from the web interface!

## Features

### 🎯 User Interface
- **Status Indicator**: Shows whether AI is configured in the navigation bar
- **Setup Button**: Robot icon (🤖) in the navbar opens the configuration modal
- **Test & Save**: Built-in API key testing before saving

### 🔧 Backend Endpoints

1. **Test API Key**
   ```
   POST /api/settings/gemini-api-key/test
   Body: { "api_key": "your_key" }
   ```
   - Tests the key with Google Gemini
   - Returns success/error with details

2. **Save API Key**
   ```
   POST /api/settings/gemini-api-key/save
   Body: { "api_key": "your_key" }
   ```
   - Saves to `.env` file
   - Updates environment immediately

3. **Check Status**
   ```
   GET /api/settings/gemini-api-key/status
   ```
   - Returns whether key is configured

4. **Remove Key**
   ```
   DELETE /api/settings/gemini-api-key/remove
   ```
   - Removes key from `.env`

## User Workflow

### Step 1: Access Configuration
1. Start your server: `python backend/run_server.py`
2. Open the web interface: http://localhost:5000
3. Click the **robot icon (🤖)** in the navigation bar

### Step 2: Get Free API Key
1. Click the link in the modal to visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account (no credit card required!)
3. Click "Create API Key"
4. Copy the generated key

### Step 3: Configure in App
1. Paste the API key in the input field
2. Click **"Test Connection"** to verify it works
3. Click **"Test & Save"** to save it to your configuration
4. See success message: "🎉 AI recipe generation is now active!"

### Step 4: Use AI Generation
- The status indicator will show "✅ AI Active"
- Recipe generation will now use the RAG + AI pipeline
- 13,000+ recipes available for context!

## Technical Details

### What Happens Behind the Scenes

1. **Testing**: 
   - Sends a simple query to Google Gemini
   - Validates the API key is working
   - Shows detailed error messages if it fails

2. **Saving**:
   - Writes to `backend/.env` file as `GEMINI_API_KEY=your_key`
   - Updates the running environment immediately
   - No server restart needed!

3. **Security**:
   - API key stored server-side only
   - Never sent to browser after saving
   - Password field with show/hide toggle

### API Key Limits (Free Tier)
- **60 requests per minute**
- **1,500 requests per day**
- More than enough for personal use!

## Troubleshooting

### "API key test failed - no response"
- Check your internet connection
- Make sure the key was copied correctly (no extra spaces)

### "API_KEY_INVALID"
- The key might be wrong or expired
- Generate a new key from Google AI Studio

### "quota exceeded"
- You've hit the free tier limit
- Wait for the quota to reset (per minute or per day)

### "permission denied"
- Make sure Gemini API is enabled in your Google Cloud project
- Visit the Google Cloud Console and enable it

## Files Modified

### Backend
- ✅ `backend/routes/settings.py` - New settings endpoints
- ✅ `backend/src/app.py` - Registered settings blueprint

### Frontend
- ✅ `frontend/js/settings.js` - Settings manager class
- ✅ `frontend/index.html` - Added AI setup button and script
- ✅ `frontend/css/components.css` - Modal and status styles

## Example Flow

```javascript
// Frontend calls backend
fetch('/api/settings/gemini-api-key/test', {
    method: 'POST',
    body: JSON.stringify({ api_key: 'AIza...' })
});

// Backend tests with Gemini
genai.configure(api_key='AIza...')
model.generate_content("Hello")

// Success! Save to .env
GEMINI_API_KEY=AIza...

// Now AI recipes work!
fetch('/api/recipes/generate-with-ai', {
    method: 'POST',
    body: JSON.stringify({
        ingredients: ['chicken', 'tomatoes'],
        dietary_preferences: ['healthy']
    })
});
```

## Benefits

✅ **User-Friendly**: No need to manually edit `.env` files
✅ **Instant Validation**: Test before saving
✅ **Visual Feedback**: Status indicator shows configuration state
✅ **Error Handling**: Clear error messages guide users
✅ **Secure**: API key stored server-side only
✅ **No Restart**: Changes take effect immediately

---

**You're all set!** 🎉

Your users can now configure AI recipe generation with just a few clicks!
