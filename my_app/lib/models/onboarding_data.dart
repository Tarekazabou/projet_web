class OnboardingData {
  String? gender;
  double? weight; // in kg
  double? height; // in cm
  List<String> allergies;
  List<String> fridgeItems;
  String? dietType;
  Map<String, dynamic>? nutritionGoals;

  OnboardingData({
    this.gender,
    this.weight,
    this.height,
    this.allergies = const [],
    this.fridgeItems = const [],
    this.dietType,
    this.nutritionGoals,
  });

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'weight': weight,
      'height': height,
      'allergies': allergies,
      'fridgeItems': fridgeItems,
      'dietType': dietType,
      'nutritionGoals': nutritionGoals,
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      gender: json['gender'],
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      allergies: List<String>.from(json['allergies'] ?? []),
      fridgeItems: List<String>.from(json['fridgeItems'] ?? []),
      dietType: json['dietType'],
      nutritionGoals: json['nutritionGoals'],
    );
  }
}
