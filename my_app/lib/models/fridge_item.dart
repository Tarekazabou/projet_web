class FridgeItem {
  final String? id;
  final String ingredientName;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final String category;

  FridgeItem({
    this.id,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    required this.category,
  });

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      id: json['id'],
      ingredientName: json['ingredientName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'pieces',
      expiryDate: json['expiryDate'] != null 
        ? DateTime.parse(json['expiryDate'])
        : null,
      category: json['category'] ?? 'Other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate?.toIso8601String(),
      'category': category,
    };
  }
}
