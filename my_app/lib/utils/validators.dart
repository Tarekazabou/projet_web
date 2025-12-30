import 'constants.dart';

/// Form validation utilities
class Validators {
  Validators._();

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (value.length > AppConstants.maxEmailLength) {
      return 'Email is too long';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password is too long';
    }

    return null;
  }

  /// Validate password with strength requirements
  static String? strongPassword(String? value) {
    final basicValidation = password(value);
    if (basicValidation != null) return basicValidation;

    if (!RegExp(r'[A-Z]').hasMatch(value!)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validate confirm password
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate username
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < 2) {
      return 'Username must be at least 2 characters';
    }

    if (value.length > AppConstants.maxUsernameLength) {
      return 'Username is too long';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  /// Validate required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate number
  static String? number(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  /// Validate positive number
  static String? positiveNumber(
    String? value, {
    String fieldName = 'This field',
  }) {
    final numberValidation = number(value, fieldName: fieldName);
    if (numberValidation != null) return numberValidation;

    final num = double.parse(value!);
    if (num <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  /// Validate min length
  static String? minLength(
    String? value,
    int minLength, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate max length
  static String? maxLength(
    String? value,
    int maxLength, {
    String fieldName = 'This field',
  }) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }
}
