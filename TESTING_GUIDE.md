# 🧪 Quick Testing Guide

## Test the API Key Configuration Feature

### 1. Open the Web Interface
- Server is running at: http://localhost:5000
- You should see the navigation bar with a robot icon (🤖)

### 2. Check Initial Status
**Look for**: Status indicator in navbar
- **Expected**: Shows "⚠️ AI Not Configured" (red badge)

### 3. Open Configuration Modal
**Action**: Click the robot icon (🤖) in the navbar
**Expected**: 
- Modal pops up with title "Configure AI Recipe Generation"
- Contains instructions to get API key
- Has input field for API key
- Has two buttons: "Test Connection" and "Test & Save"
- Buttons are disabled (input is empty)

### 4. Test Input Validation
**Action**: Type some characters in the API key field
**Expected**:
- Buttons become enabled
- Show/hide eye icon appears

**Action**: Click the eye icon
**Expected**:
- Password field switches to text field
- You can see what you typed

### 5. Test Invalid API Key
**Action**: 
1. Type "INVALID_KEY_123" in the field
2. Click "Test Connection"

**Expected**:
- Button shows "🔄 Testing..." (loading state)
- After a moment, status box appears in red
- Error message: "API key test failed - no response from Gemini" or similar
- Button returns to normal state

### 6. Test Valid API Key

#### Option A: If You Have a Real Gemini API Key
**Action**:
1. Get your free key from https://makersuite.google.com/app/apikey
2. Paste it in the field
3. Click "Test & Save"

**Expected**:
- Button shows "🔄 Testing & Saving..."
- Status box shows "Step 1/2: Testing API key..."
- Then "Step 2/2: Saving to configuration..."
- Green success message: "🎉 Success! Your API key has been saved..."
- Status indicator in navbar changes to "✅ AI Active" (green badge)
- Modal auto-closes after 3 seconds

#### Option B: Simulate Without Real Key
**Action**: Check the backend logs
```powershell
# In your terminal running the server, watch for:
# POST /api/settings/gemini-api-key/test
# POST /api/settings/gemini-api-key/save
```

### 7. Verify Configuration
**Action**: 
1. Close and reopen the modal
2. Or refresh the page

**Expected**:
- Status indicator still shows "✅ AI Active"
- Modal's "Current Status" section shows "Configured & Active"

### 8. Test Backend Endpoints Directly

Open a new PowerShell terminal:

```powershell
# Test status check
Invoke-RestMethod -Uri "http://localhost:5000/api/settings/gemini-api-key/status" -Method GET

# Expected output:
# success       : True
# is_configured : False (or True if key is set)
# message       : ...

# Test with invalid key
$body = @{ api_key = "INVALID" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:5000/api/settings/gemini-api-key/test" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"

# Expected: Error response
```

### 9. Check .env File
**Action**: Open `backend/.env` in the editor
**Expected**:
- If you saved a key, you should see:
  ```
  GEMINI_API_KEY=your_key_here
  ```

### 10. Test AI Recipe Generation (After Valid Key)
**Action in browser**:
1. Navigate to "Recipe Generator" page
2. Add ingredients: chicken, garlic, tomatoes
3. Select dietary preferences: healthy
4. Click "Generate Recipes"

**Expected**:
- Recipes are generated using AI
- Each recipe shows "Based on X similar recipes"
- Recipes are unique and creative

---

## 🎯 What to Look For

### ✅ Success Indicators
- [ ] Modal opens and closes smoothly
- [ ] Buttons enable/disable correctly
- [ ] Password toggle works
- [ ] Status indicator updates
- [ ] Test connection validates API key
- [ ] Save creates/updates .env file
- [ ] No console errors in browser DevTools
- [ ] Server logs show successful requests

### ❌ Common Issues

**Issue**: Modal doesn't open
- **Check**: Browser console for JavaScript errors
- **Fix**: Make sure `js/settings.js` loaded

**Issue**: "Network error"
- **Check**: Server is running on port 5000
- **Fix**: Restart server

**Issue**: Test always fails
- **Check**: API key copied correctly (no extra spaces)
- **Check**: Internet connection working
- **Fix**: Try a fresh API key from Google

**Issue**: .env not updating
- **Check**: File permissions
- **Check**: Path in backend/routes/settings.py
- **Fix**: Manually create .env file first

---

## 🎬 Demo Script

### For Recording/Presenting
1. **"Let me show you how easy it is to set up AI recipe generation"**
2. **Show initial state**: "Notice the 'AI Not Configured' indicator"
3. **Click robot icon**: "Just click this button to configure"
4. **Show modal**: "The app guides you through getting a free API key"
5. **Click link**: "It even provides direct links to Google AI Studio"
6. **Paste key**: "Paste your key here"
7. **Test**: "The app validates it works before saving"
8. **Save**: "One click to save and activate"
9. **Show success**: "Now AI recipe generation is active!"
10. **Demo generation**: "Let's create a recipe..."

---

## 📸 Visual Checklist

### Before Configuration
```
Navbar: [Home] [Fridge] [Recipes] ... [⚠️ AI Not Configured] [🤖] [⚙️] [👤]
```

### After Configuration
```
Navbar: [Home] [Fridge] [Recipes] ... [✅ AI Active] [🤖] [⚙️] [👤]
```

### Modal States
1. **Closed**: Not visible
2. **Open - Empty**: Input empty, buttons disabled
3. **Open - Typing**: Buttons enabled
4. **Open - Testing**: Loading spinner, status box
5. **Open - Success**: Green message, badge updated
6. **Open - Error**: Red message, buttons enabled

---

## 🚀 Ready to Test!

**Your server is running at**: http://localhost:5000

**Next step**: Open the browser and click the robot icon (🤖)

**Have fun testing!** 🎉
