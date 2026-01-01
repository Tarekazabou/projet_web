class ShoppingItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final bool isChecked;
  final bool isFromHabits;
  final DateTime addedAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.unit = 'piece',
    this.isChecked = false,
    this.isFromHabits = false,
    required this.addedAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    bool? isChecked,
    bool? isFromHabits,
    DateTime? addedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      isFromHabits: isFromHabits ?? this.isFromHabits,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked,
      'isFromHabits': isFromHabits,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'other',
      quantity: json['quantity'] ?? 1,
      unit: json['unit'] ?? 'piece',
      isChecked: json['isChecked'] ?? false,
      isFromHabits: json['isFromHabits'] ?? false,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
    );
  }
}
