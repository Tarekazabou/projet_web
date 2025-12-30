class FridgeItem {
  final String? id;
  final String ingredientName;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final String category;
  final DateTime? addedAt;
  final String? notes;

  FridgeItem({
    this.id,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    required this.category,
    this.addedAt,
    this.notes,
  });

  /// Alias for ingredientName for easier access
  String get name => ingredientName;

  /// Calculate days until expiry (negative if expired)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    return DateTime(
      expiryDate!.year,
      expiryDate!.month,
      expiryDate!.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Check if item is expired
  bool get isExpired {
    final days = daysUntilExpiry;
    return days != null && days < 0;
  }

  /// Check if item is expiring soon (within 3 days)
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days >= 0 && days <= 3;
  }

  /// Get expiry status text
  String get expiryStatusText {
    final days = daysUntilExpiry;
    if (days == null) return 'No expiry date';
    if (days < 0) return 'Expired ${-days} days ago';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    return 'Expires in $days days';
  }

  /// Get formatted quantity with unit
  String get formattedQuantity => '$quantity $unit';

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      id: json['id'],
      ingredientName: json['ingredientName'] ?? json['ingredient_name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'pieces',
      expiryDate: json['expiryDate'] != null || json['expiry_date'] != null
          ? DateTime.tryParse(json['expiryDate'] ?? json['expiry_date'] ?? '')
          : null,
      category: json['category'] ?? 'Autres',
      addedAt: json['addedAt'] != null || json['added_at'] != null
          ? DateTime.tryParse(json['addedAt'] ?? json['added_at'] ?? '')
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unit': unit,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      'category': category,
      if (addedAt != null) 'addedAt': addedAt!.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  /// Create a copy with updated fields
  FridgeItem copyWith({
    String? id,
    String? ingredientName,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    String? category,
    DateTime? addedAt,
    String? notes,
  }) {
    return FridgeItem(
      id: id ?? this.id,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      category: category ?? this.category,
      addedAt: addedAt ?? this.addedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'FridgeItem(id: $id, name: $ingredientName, quantity: $quantity $unit, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FridgeItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
