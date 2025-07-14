import 'package:cloud_firestore/cloud_firestore.dart';

class Investment {
  final String id;
  final String userId;
  final String name;
  final String type;
  final double currentValue;
  final double? quantity;
  final double investedAmount;
  final DateTime? lastUpdated;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Investment({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currentValue,
    this.quantity,
    required this.investedAmount,
    this.lastUpdated,
    this.createdAt,
    this.updatedAt,
  });

  factory Investment.fromMap(Map<String, dynamic> data, String documentId) {
    return Investment(
      id: documentId,
      userId: data['userId'],
      name: data['name'],
      type: data['type'],
      currentValue: (data['currentValue'] as num).toDouble(),
      quantity: (data['quantity'] as num?)?.toDouble(),
      investedAmount: (data['investedAmount'] as num).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'currentValue': currentValue,
      'quantity': quantity,
      'investedAmount': investedAmount,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Investment copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? currentValue,
    double? quantity,
    double? investedAmount,
    DateTime? lastUpdated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Investment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      currentValue: currentValue ?? this.currentValue,
      quantity: quantity ?? this.quantity,
      investedAmount: investedAmount ?? this.investedAmount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Investment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
