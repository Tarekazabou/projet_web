# Mealy Flutter Mobile App

A mobile application for AI-powered meal planning, smart grocery lists, and recipe generation.

## What's New in Version 3.0

### 📅 Meal Planning System
- **Weekly Calendar View**: Visual meal planning with drag-and-drop support
- **AI Meal Suggestions**: Get personalized meal plans based on your preferences and fridge contents
- **Meal Type Organization**: Plan breakfast, lunch, dinner, and snacks separately
- **One-Click Scheduling**: Add recipes directly to your meal plan

### 🛒 Smart Grocery Lists
- **Auto-Generation**: Generate grocery lists from your meal plan automatically
- **Smart Categorization**: Items organized by store section (Produce, Dairy, Proteins, etc.)
- **Purchase Tracking**: Check off items as you shop
- **Fridge Integration**: Add purchased items to your fridge with one tap

## Features

- 🏠 **Home**: Browse AI-generated recipes with quick action cards
- 🧊 **Fridge**: Manage your ingredients and get recipe suggestions
- ✨ **Generate**: Create custom recipes with AI based on your preferences
- 🎯 **Quick Actions Navigation**: Launch any primary screen via tappable cards
- 📅 **Meal Planner**: Plan your weekly meals with AI assistance
- 🛒 **Grocery Lists**: Smart shopping lists generated from meal plans
- 📊 **Nutrition**: Track your daily nutritional intake
- 👤 **Profile**: Manage dietary restrictions and preferences

## Navigation Model

The app now uses a modal, stack-based navigation pattern instead of a persistent bottom navigation bar:

1. **Entry Point** – `HomeScreen` is always visible as the base layer.
2. **Quick Actions** – Tapping any quick action card or the floating action button invokes `Navigator.push(...)` with a null-safe builder check before pushing.
3. **Modal Flow** – Each destination screen (Fridge, Nutrition, Recipes, Meal Planner, Profile, etc.) sits on top of the stack, producing an iOS-style modal feel.
4. **Back Navigation** – Users exit a screen via the system back button or the AppBar back arrow, automatically returning to Home when the stack pops.

### Adding/Removing Quick Actions

Edit the `_NavigationAction` lists inside `lib/main.dart`:

- ` _primaryActions` → High-traffic destinations (Fridge, Nutrition, Groceries)
- ` _secondaryActions` → Supporting pages (Meal Planner, Profile, etc.)

Each entry accepts an icon, label, and a widget builder. Leaving a builder `null` will safely no-op thanks to the navigation null-check.

## Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Running backend server (Flask API on http://localhost:5000)

## Setup Instructions

### 1. Install Dependencies

```bash
cd my_app
flutter pub get
```

### 2. Configure Backend URL

The app connects to your Flask backend. Update `apiBaseUrl` in `lib/utils/constants.dart` based on your platform:

- **iOS Simulator**: `http://localhost:5000/api`
- **Android Emulator**: `http://10.0.2.2:5000/api`
- **Real Device**: `http://YOUR_COMPUTER_IP:5000/api`

### 3. Run the App

Make sure your Flask backend is running on port 5000, then:

```bash
flutter run
```

Or select your device in VS Code and press F5.

## Project Structure

```
lib/
├── main.dart                 # App entry point and navigation
├── models/                   # Data models
│   ├── fridge_item.dart
│   ├── recipe.dart
│   ├── meal_plan.dart        # Weekly meal planning model
│   └── grocery_item.dart     # Grocery list item model
├── providers/                # State management
│   ├── fridge_provider.dart
│   ├── recipe_provider.dart
│   ├── meal_plan_provider.dart   # Meal planning state
│   └── grocery_provider.dart     # Grocery list state
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── fridge_screen.dart
│   ├── recipe_generator_screen.dart
│   ├── meal_planner_screen.dart  # Weekly meal planning UI
│   ├── grocery_screen.dart       # Smart grocery lists
│   ├── nutrition_screen.dart
│   └── profile_screen.dart
├── services/                 # API communication
│   └── api_service.dart
└── widgets/                  # Reusable components
    ├── recipe_card.dart
    ├── recipe_detail_sheet.dart
    ├── meal_slot_card.dart       # Meal planning slot
    └── grocery_item_tile.dart    # Grocery list item
```

## Backend API Endpoints Used

### Fridge Management
- `GET /api/fridge/items` - Get fridge items
- `POST /api/fridge/items` - Add fridge item
- `PUT /api/fridge/items/{item_id}` - Update fridge item
- `DELETE /api/fridge/items/{item_id}` - Delete fridge item
- `POST /api/fridge/suggest-recipes` - Suggest recipes from fridge

### Recipe Generation
- `GET /api/recipes/list` - List recipes
- `POST /api/recipes/generate-with-ai` - Generate a recipe with Gemini
- `POST /api/recipes/generate-multiple` - Generate multiple recipes
- `GET /api/recipes/status` - AI service status

### Meal Planning
- `GET /api/meal-plans/week` - Get weekly meal plan
- `GET /api/meal-plans/` - List meal plan entries
- `POST /api/meal-plans/` - Add meal to plan
- `DELETE /api/meal-plans/{id}` - Remove meal from plan
- `POST /api/meal-plans/ai-suggest` - Get AI meal suggestions

### Grocery Lists
- `GET /api/grocery/items` - Get grocery list
- `POST /api/grocery/items` - Add grocery item
- `POST /api/grocery/toggle-purchased/{index}` - Toggle purchased status
- `DELETE /api/grocery/items/{index}` - Remove grocery item
- `POST /api/grocery/from-meal-plan` - Generate list from meal plan

### Nutrition Tracking
- `GET /api/nutrition/daily/{date}` - Get daily nutrition log
- `POST /api/nutrition/log-meal` - Log a meal

## Testing on Different Platforms

### Android Emulator
1. Create an AVD in Android Studio
2. Start the emulator
3. Run `flutter run`

### iOS Simulator (Mac only)
1. Open Simulator app
2. Run `flutter run`

### Real Device
1. Enable USB debugging (Android) or trust computer (iOS)
2. Connect device via USB
3. Update `apiBaseUrl` in `lib/utils/constants.dart` to your computer's IP
4. Run `flutter run`

## Troubleshooting

### Connection Issues
- Ensure backend is running: `cd backend && python app.py`
- Check firewall allows connections on port 5000
- For real device: Use computer's local IP, not localhost

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### Hot Reload Not Working
Press `r` in terminal or click hot reload in IDE

## Dependencies

- **provider**: State management
- **http**: HTTP client
- **dio**: Advanced HTTP client
- **google_fonts**: Custom fonts
- **firebase_core**: Firebase integration
- **cloud_firestore**: Firestore database
- **intl**: Date formatting
- **flutter_screenutil**: Responsive design
- **table_calendar**: Calendar widget for meal planning

## Completed Features

- [x] Firebase authentication
- [x] AI-powered meal planning
- [x] Smart grocery list generation
- [x] Weekly meal calendar view
- [x] Nutrition tracking dashboard

## Roadmap

- [ ] Add image upload for recipes
- [ ] Enable offline mode with local caching
- [ ] Add push notifications for meal reminders
- [ ] Implement recipe rating and reviews
- [ ] Social sharing features

## License

MIT License - See backend LICENSE file

