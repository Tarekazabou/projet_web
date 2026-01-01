class Recipe {
  final String? id;
  final String title;
  final String? description;
  final List<dynamic> ingredients;
  final List<String> instructions;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int servingSize;
  final String difficulty;
  final String? cuisine;
  final List<String> dietaryPreferences;
  final Map<String, dynamic>? nutrition;
  final bool generatedByAI;
  final bool? basedOnFridge;
  final List<String>? fridgeIngredients;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final DateTime? createdAt;

  Recipe({
    this.id,
    required this.title,
    this.description,
    required this.ingredients,
    required this.instructions,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    required this.servingSize,
    required this.difficulty,
    this.cuisine,
    this.dietaryPreferences = const [],
    this.nutrition,
    this.generatedByAI = false,
    this.basedOnFridge,
    this.fridgeIngredients,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    this.createdAt,
  });

  /// Total cooking time in minutes
  int get totalTime => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);

  /// Get formatted total time (e.g., "1h 30min")
  String get formattedTotalTime {
    final total = totalTime;
    if (total == 0) return 'N/A';
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (hours == 0) return '${minutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  /// Get formatted prep time
  String get formattedPrepTime {
    if (prepTimeMinutes == null || prepTimeMinutes == 0) return 'N/A';
    return '${prepTimeMinutes}min';
  }

  /// Get formatted cook time
  String get formattedCookTime {
    if (cookTimeMinutes == null || cookTimeMinutes == 0) return 'N/A';
    return '${cookTimeMinutes}min';
  }

  /// Get difficulty display text
  String get difficultyDisplay {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  /// Get calories from nutrition info
  int? get calories {
    if (nutrition == null) return null;
    return nutrition!['calories'] as int?;
  }

  /// Get protein from nutrition info
  String? get protein {
    if (nutrition == null) return null;
    final value = nutrition!['protein'];
    return value?.toString();
  }

  /// Get carbs from nutrition info
  String? get carbs {
    if (nutrition == null) return null;
    final value = nutrition!['carbs'] ?? nutrition!['carbohydrates'];
    return value?.toString();
  }

  /// Get fat from nutrition info
  String? get fat {
    if (nutrition == null) return null;
    final value = nutrition!['fat'];
    return value?.toString();
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'] ?? 'Untitled Recipe',
      description: json['description'],
      ingredients: json['ingredients'] ?? [],
      instructions: _parseInstructions(json['instructions']),
      prepTimeMinutes: json['prepTimeMinutes'] ?? json['prep_time_minutes'],
      cookTimeMinutes: json['cookTimeMinutes'] ?? json['cook_time_minutes'],
      servingSize:
          json['servingSize'] ?? json['servings'] ?? json['serving_size'] ?? 4,
      difficulty: json['difficulty'] ?? 'medium',
      cuisine: json['cuisine'],
      dietaryPreferences:
          _parseStringList(
            json['dietaryPreferences'] ?? json['dietary_preferences'],
          ) ??
          [],
      nutrition: json['nutrition'],
      generatedByAI: json['generatedByAI'] ?? json['generated_by_ai'] ?? false,
      basedOnFridge: json['basedOnFridge'] ?? json['based_on_fridge'],
      fridgeIngredients: _parseStringList(
        json['fridgeIngredients'] ?? json['fridge_ingredients'],
      ),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] ?? json['review_count'],
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '')
          : null,
    );
  }

  static List<String> _parseInstructions(dynamic instructions) {
    if (instructions == null) return [];
    if (instructions is List) {
      return instructions.map((e) => e.toString()).toList();
    }
    if (instructions is String) {
      return instructions
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    return [];
  }

  static List<String>? _parseStringList(dynamic list) {
    if (list == null) return null;
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      if (prepTimeMinutes != null) 'prepTimeMinutes': prepTimeMinutes,
      if (cookTimeMinutes != null) 'cookTimeMinutes': cookTimeMinutes,
      'servingSize': servingSize,
      'difficulty': difficulty,
      if (cuisine != null) 'cuisine': cuisine,
      'dietaryPreferences': dietaryPreferences,
      if (nutrition != null) 'nutrition': nutrition,
      'generatedByAI': generatedByAI,
      if (basedOnFridge != null) 'basedOnFridge': basedOnFridge,
      if (fridgeIngredients != null) 'fridgeIngredients': fridgeIngredients,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'reviewCount': reviewCount,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Format an ingredient for display
  String formatIngredient(dynamic ingredient) {
    if (ingredient is String) return ingredient;
    if (ingredient is Map) {
      final parts = <String>[];
      if (ingredient['quantity'] != null)
        parts.add(ingredient['quantity'].toString());
      if (ingredient['unit'] != null) parts.add(ingredient['unit'].toString());
      if (ingredient['name'] != null) parts.add(ingredient['name'].toString());
      return parts.join(' ');
    }
    return ingredient.toString();
  }

  /// Create a copy with updated fields
  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<dynamic>? ingredients,
    List<String>? instructions,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? servingSize,
    String? difficulty,
    String? cuisine,
    List<String>? dietaryPreferences,
    Map<String, dynamic>? nutrition,
    bool? generatedByAI,
    bool? basedOnFridge,
    List<String>? fridgeIngredients,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servingSize: servingSize ?? this.servingSize,
      difficulty: difficulty ?? this.difficulty,
      cuisine: cuisine ?? this.cuisine,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      nutrition: nutrition ?? this.nutrition,
      generatedByAI: generatedByAI ?? this.generatedByAI,
      basedOnFridge: basedOnFridge ?? this.basedOnFridge,
      fridgeIngredients: fridgeIngredients ?? this.fridgeIngredients,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, difficulty: $difficulty, totalTime: $totalTime min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
