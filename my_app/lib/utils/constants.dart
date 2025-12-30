/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Mealy';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String apiBaseUrl = 'http://localhost:5000/api';
  // For Android Emulator: 'http://10.0.2.2:5000/api'
  // For iOS Simulator: 'http://localhost:5000/api'
  // For real device: 'http://YOUR_IP:5000/api'

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxUsernameLength = 50;
  static const int maxEmailLength = 254;

  // Storage Keys
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  static const String authTokenKey = 'auth_token';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';

  // Categories
  static const List<String> fridgeCategories = [
    'Fruits et légumes',
    'Produits laitiers',
    'Viandes et fruits de mer',
    'Garde-manger',
    'Boissons',
    'Autres',
  ];

  static const List<String> difficultyLevels = ['easy', 'medium', 'hard'];

  static const List<String> cuisineTypes = [
    'French',
    'Italian',
    'Asian',
    'Mexican',
    'Mediterranean',
    'Indian',
    'American',
    'Other',
  ];

  static const List<String> dietaryPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'Dairy-free',
    'Keto',
    'Low-carb',
    'Halal',
    'Kosher',
  ];

  static const List<String> units = [
    'g',
    'kg',
    'ml',
    'L',
    'pieces',
    'cups',
    'tbsp',
    'tsp',
  ];
}

/// Animation durations
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 250);
}

/// App-wide spacing values
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// App-wide border radius values
class AppRadius {
  AppRadius._();

  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double circular = 100.0;
}
