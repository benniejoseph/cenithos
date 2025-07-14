import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Unified fields (optional)
  final String? description;
  final String? category;
  final String? vendor;
  final String? bank;
  final String? currency;
  final String? merchant;
  final String? ref_id;
  final String? source;

  // Helper getter for date-only comparison
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  Transaction({
    this.id = '',
    required this.userId,
    required this.amount,
    required this.type,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.description,
    this.category,
    this.vendor,
    this.bank,
    this.currency,
    this.merchant,
    this.ref_id,
    this.source,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'expense',
      date: json['date'] != null
          ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      description: json['description'],
      category: json['category'] ?? 'Other',
      vendor: json['vendor'],
      bank: json['bank'],
      currency: json['currency'] ?? 'INR',
      merchant: json['merchant'],
      ref_id: json['ref_id'],
      source: json['source'] ?? 'sms-ai',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'description': description,
      'category': category,
      'vendor': vendor,
      'bank': bank,
      'currency': currency,
      'merchant': merchant,
      'ref_id': ref_id,
      'source': source,
    };
  }

  IconData getCategoryIcon() {
    switch (category?.toLowerCase()) {
      case 'food':
        return CupertinoIcons.shopping_cart;
      case 'groceries':
        return CupertinoIcons.shopping_cart;
      case 'transport':
      case 'transportation':
        return CupertinoIcons.bus;
      case 'shopping':
        return CupertinoIcons.bag;
      case 'entertainment':
        return CupertinoIcons.film;
      case 'bills':
      case 'utilities':
        return CupertinoIcons.doc_text;
      case 'health':
      case 'pharmacy':
        return CupertinoIcons.heart_fill;
      case 'income':
        return CupertinoIcons.arrow_down_circle;
      case 'salary':
        return CupertinoIcons.money_dollar_circle;
      case 'other':
      default:
        return CupertinoIcons.creditcard;
    }
  }

  Transaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? type,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? category,
    String? vendor,
    String? bank,
    String? currency,
    String? merchant,
    String? ref_id,
    String? source,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      category: category ?? this.category,
      vendor: vendor ?? this.vendor,
      bank: bank ?? this.bank,
      currency: currency ?? this.currency,
      merchant: merchant ?? this.merchant,
      ref_id: ref_id ?? this.ref_id,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// NEW: Predefined categories
class TransactionCategories {
  static const List<String> all = [
    'Income',
    'Groceries',
    'Transport',
    'Bills',
    'Entertainment',
    'Shopping',
    'Other',
  ];

  static const Map<String, IconData> icons = {
    'Income': Icons.trending_up,
    'Groceries': Icons.shopping_cart,
    'Transport': Icons.directions_car,
    'Bills': Icons.receipt,
    'Entertainment': Icons.movie,
    'Shopping': Icons.shopping_bag,
    'Other': Icons.category,
  };
}

// NEW: Filter model
class TransactionFilters {
  final String? category;
  final String? type; // Add type field
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilters({
    this.category,
    this.type, // Add to constructor
    this.startDate,
    this.endDate,
  });

  TransactionFilters copyWith({
    String? category,
    String? type, // Add to copyWith
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionFilters(
      category: category ?? this.category,
      type: type ?? this.type, // Add to copyWith
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (category != null) params['category'] = category!;
    if (type != null) params['type'] = type!; // Add to query params
    if (startDate != null) params['startDate'] = startDate!.toIso8601String();
    if (endDate != null) params['endDate'] = endDate!.toIso8601String();
    return params;
  }

  bool get isEmpty =>
      category == null && type == null && startDate == null && endDate == null;
}
