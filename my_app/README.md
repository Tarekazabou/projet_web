# Mealy Flutter Mobile App

A mobile application for AI-powered meal planning and recipe generation.

## Features

- 🏠 **Home**: Browse AI-generated recipes
- 🧊 **Fridge**: Manage your ingredients and get recipe suggestions
- ✨ **Generate**: Create custom recipes with AI based on your preferences
- �️ **Quick Actions Navigation**: Launch any primary screen via tappable cards (no bottom nav bar)
- �📅 **Plan**: Organize your meals for the week
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

The app connects to your Flask backend. Update the `baseUrl` in `lib/services/api_service.dart` based on your platform:

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
│   └── recipe.dart
├── providers/                # State management
│   ├── fridge_provider.dart
│   └── recipe_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── fridge_screen.dart
│   ├── recipe_generator_screen.dart
│   ├── meal_planner_screen.dart
│   └── profile_screen.dart
├── services/                 # API communication
│   └── api_service.dart
└── widgets/                  # Reusable components
    ├── recipe_card.dart
    └── recipe_detail_sheet.dart
```

## Backend API Endpoints Used

- `GET /api/fridge/items` - Get fridge items
- `POST /api/fridge/items` - Add fridge item
- `DELETE /api/fridge/items/{id}` - Delete fridge item
- `GET /api/recipes/list` - Get AI-generated recipes
- `POST /api/ai-recipes/generate` - Generate new recipe
- `POST /api/ai-recipes/suggest-from-fridge` - Get recipe suggestions from fridge

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
3. Update `baseUrl` in `api_service.dart` to your computer's IP
4. Run `flutter run`

## Troubleshooting

### Connection Issues
- Ensure backend is running: `python backend/run_server.py`
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

## Next Steps

- [ ] Implement Firebase authentication
- [ ] Add image upload for recipes
- [ ] Enable offline mode with local caching
- [ ] Add push notifications for meal reminders
- [ ] Implement recipe rating and reviews

## License

MIT License - See backend LICENSE file

