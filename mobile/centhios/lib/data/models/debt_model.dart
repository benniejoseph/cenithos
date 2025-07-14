import 'package:cloud_firestore/cloud_firestore.dart';

class Debt {
  final String id;
  final String userId;
  final String name;
  final String type;
  final double balance;
  final double interestRate;
  final double minimumPayment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Debt({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.interestRate,
    required this.minimumPayment,
    this.createdAt,
    this.updatedAt,
  });

  factory Debt.fromMap(Map<String, dynamic> data, String documentId) {
    return Debt(
      id: documentId,
      userId: data['userId'],
      name: data['name'],
      type: data['type'],
      balance: (data['balance'] as num).toDouble(),
      interestRate: (data['interestRate'] as num).toDouble(),
      minimumPayment: (data['minimumPayment'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'interestRate': interestRate,
      'minimumPayment': minimumPayment,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Debt copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? balance,
    double? interestRate,
    double? minimumPayment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      interestRate: interestRate ?? this.interestRate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Debt && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
