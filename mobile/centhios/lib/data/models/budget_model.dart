import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String userId;
  final String category;
  final double budgetedAmount;
  final double spentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.budgetedAmount,
    required this.spentAmount,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Budget.fromMap(Map<String, dynamic> data, String documentId) {
    return Budget(
      id: documentId,
      userId: data['userId'],
      category: data['category'],
      budgetedAmount: (data['budgetedAmount'] as num).toDouble(),
      spentAmount: (data['spentAmount'] as num).toDouble(),
      startDate: DateTime.parse(data['startDate'] as String),
      endDate: DateTime.parse(data['endDate'] as String),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'budgetedAmount': budgetedAmount,
      'spentAmount': spentAmount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Budget copyWith({
    String? id,
    String? userId,
    String? category,
    double? budgetedAmount,
    double? spentAmount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      budgetedAmount: budgetedAmount ?? this.budgetedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
