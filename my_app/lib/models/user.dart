class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final List<String> dietaryRestrictions;
  final List<String> allergens;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.dietaryRestrictions = const [],
    this.allergens = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['user_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      dietaryRestrictions: json['dietaryRestrictions'] != null
          ? List<String>.from(json['dietaryRestrictions'])
          : (json['dietary_restrictions'] != null
                ? List<String>.from(json['dietary_restrictions'])
                : []),
      allergens: json['allergens'] != null
          ? List<String>.from(json['allergens'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'dietaryRestrictions': dietaryRestrictions,
      'allergens': allergens,
    };
  }
}
