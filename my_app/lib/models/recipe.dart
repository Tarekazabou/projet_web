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
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'] ?? 'Untitled Recipe',
      description: json['description'],
      ingredients: json['ingredients'] ?? [],
      instructions: (json['instructions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      prepTimeMinutes: json['prepTimeMinutes'],
      cookTimeMinutes: json['cookTimeMinutes'],
      servingSize: json['servingSize'] ?? json['servings'] ?? 4,
      difficulty: json['difficulty'] ?? 'medium',
      cuisine: json['cuisine'],
      dietaryPreferences: (json['dietaryPreferences'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nutrition: json['nutrition'],
      generatedByAI: json['generatedByAI'] ?? false,
      basedOnFridge: json['basedOnFridge'],
      fridgeIngredients: (json['fridgeIngredients'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  int get totalTime => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);


  String formatIngredient(dynamic ingredient) {
    if (ingredient is String) return ingredient;
    if (ingredient is Map) {
      final parts = <String>[];
      if (ingredient['quantity'] != null) parts.add(ingredient['quantity'].toString());
      if (ingredient['unit'] != null) parts.add(ingredient['unit'].toString());
      if (ingredient['name'] != null) parts.add(ingredient['name'].toString());
      return parts.join(' ');
    }
    return ingredient.toString();
  }
}
