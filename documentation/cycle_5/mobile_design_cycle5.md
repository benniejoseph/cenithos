# Mobile Technical Design - Cycle 5

**Date:** 2025-07-02
**Author:** L2A2 (Mobile Architect)
**Based on:** `development_plan_cycle5.md`

---

## 1. Overview

This document specifies the mobile app changes required to support transaction categorization and filtering using Flutter with Riverpod state management.

---

## 2. Data Model Changes

### 2.1. Transaction Model Update

**File:** `mobile/centhios/lib/data/models/transaction_model.dart`

```dart
class Transaction {
  final String id;
  final String description;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category; // NEW: Category field
  final DateTime date;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category, // NEW: Required category
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      category: json['category'] ?? 'Other', // NEW: Default to 'Other'
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'type': type,
      'category': category, // NEW: Include category in JSON
      'date': date.toIso8601String(),
    };
  }
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
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilters({
    this.category,
    this.startDate,
    this.endDate,
  });

  TransactionFilters copyWith({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionFilters(
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (category != null) params['category'] = category!;
    if (startDate != null) params['startDate'] = startDate!.toIso8601String();
    if (endDate != null) params['endDate'] = endDate!.toIso8601String();
    return params;
  }

  bool get isEmpty => category == null && startDate == null && endDate == null;
}
```

---

## 3. Repository Layer Changes

### 3.1. Transactions Repository Update

**File:** `mobile/centhios/lib/data/repositories/transactions_repository.dart`

```dart
import 'dart:convert';
import 'package:centhios/core/services/firebase_providers.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TransactionsRepository {
  final Ref _ref;
  final String _baseUrl = dotenv.env['API_BASE_URL'] ??
      'http://localhost:5001/centhiosv2/us-central1/api';

  TransactionsRepository(this._ref);

  // UPDATED: Accept filters parameter
  Future<List<Transaction>> getTransactions([TransactionFilters? filters]) async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    
    // Build URL with query parameters
    String url = '$_baseUrl/transactions';
    if (filters != null && !filters.isEmpty) {
      final params = filters.toQueryParams();
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url += '?$query';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Transaction.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  // UPDATED: Send category data
  Future<void> createTransaction(Transaction transaction) async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(transaction.toJson()), // Uses updated toJson()
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create transaction');
    }
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref);
});
```

---

## 4. UI Components

### 4.1. Enhanced Add Transaction Dialog

**File:** `mobile/centhios/lib/presentation/widgets/add_transaction_dialog.dart`

Key changes:
- Add `String _selectedCategory = 'Other';` to state
- Add category dropdown after the type dropdown:

```dart
// NEW: Category selection dropdown
DropdownButtonFormField<String>(
  value: _selectedCategory,
  onChanged: (v) => setState(() => _selectedCategory = v!),
  items: TransactionCategories.all
      .map((category) => DropdownMenuItem(
            value: category,
            child: Row(
              children: [
                Icon(TransactionCategories.icons[category]),
                const SizedBox(width: 8),
                Text(category),
              ],
            ),
          ))
      .toList(),
  decoration: const InputDecoration(
    labelText: 'Category',
    border: OutlineInputBorder(),
  ),
),
```

- Update the `_submit()` method to include category:

```dart
await ref.read(transactionsRepositoryProvider).createTransaction(
  Transaction(
    id: '', // Will be set by backend
    description: _descriptionController.text,
    amount: double.parse(_amountController.text),
    type: _selectedType,
    category: _selectedCategory, // NEW: Include category
    date: _selectedDate,
  ),
);
```

### 4.2. Enhanced Transaction List Item

**File:** `mobile/centhios/lib/presentation/widgets/transaction_list_item.dart`

Key changes:
- Add category display below the description:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(transaction.description, style: theme.textTheme.p),
    // NEW: Category display
    Row(
      children: [
        Icon(
          TransactionCategories.icons[transaction.category] ?? Icons.category,
          size: 16,
          color: theme.colorScheme.muted,
        ),
        const SizedBox(width: 4),
        Text(
          transaction.category,
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.muted,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          DateFormat.yMMMd().format(transaction.date),
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.muted,
          ),
        ),
      ],
    ),
  ],
),
```

### 4.3. New Filter Bottom Sheet

**File:** `mobile/centhios/lib/presentation/widgets/transaction_filter_sheet.dart`

```dart
import 'package:centhios/data/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TransactionFilterSheet extends StatefulWidget {
  final TransactionFilters currentFilters;
  final Function(TransactionFilters) onFiltersChanged;

  const TransactionFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late String? _selectedCategory;
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentFilters.category;
    _startDate = widget.currentFilters.startDate;
    _endDate = widget.currentFilters.endDate;
  }

  void _applyFilters() {
    final filters = TransactionFilters(
      category: _selectedCategory,
      startDate: _startDate,
      endDate: _endDate,
    );
    widget.onFiltersChanged(filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Filter Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Category filter
          DropdownButtonFormField<String?>(
            value: _selectedCategory,
            onChanged: (v) => setState(() => _selectedCategory = v),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Categories')),
              ...TransactionCategories.all.map((category) => 
                DropdownMenuItem(value: category, child: Text(category))),
            ],
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Date range filters
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                  child: Text(_startDate?.toString().split(' ')[0] ?? 'Start Date'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShadButton.outline(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                  child: Text(_endDate?.toString().split(' ')[0] ?? 'End Date'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShadButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Page Updates

### 5.1. Enhanced Transactions Page

**File:** `mobile/centhios/lib/presentation/pages/transactions_page.dart`

Key changes:
- Add filter state management with Riverpod
- Add filter button to app bar
- Update provider to use filters

```dart
// NEW: Filter state provider
final transactionFiltersProvider = StateProvider<TransactionFilters>((ref) {
  return const TransactionFilters();
});

// UPDATED: Transactions provider that uses filters
final transactionsProvider = FutureProvider((ref) {
  final repo = ref.watch(transactionsRepositoryProvider);
  final filters = ref.watch(transactionFiltersProvider);
  return repo.getTransactions(filters.isEmpty ? null : filters);
});

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final currentFilters = ref.read(transactionFiltersProvider);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => TransactionFilterSheet(
        currentFilters: currentFilters,
        onFiltersChanged: (filters) {
          ref.read(transactionFiltersProvider.notifier).state = filters;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currentFilters = ref.watch(transactionFiltersProvider);
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        actions: [
          // NEW: Filter button
          ShadButton.ghost(
            onPressed: () => _showFilterSheet(context, ref),
            child: Icon(
              Icons.filter_list,
              color: currentFilters.isEmpty ? null : theme.colorScheme.primary,
            ),
          ),
          ShadButton.ghost(
            onPressed: () => showAddTransactionDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // NEW: Active filters display
          if (!currentFilters.isEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (currentFilters.category != null)
                    Chip(
                      label: Text(currentFilters.category!),
                      onDeleted: () {
                        ref.read(transactionFiltersProvider.notifier).state =
                            currentFilters.copyWith(category: null);
                      },
                    ),
                  if (currentFilters.startDate != null || currentFilters.endDate != null)
                    Chip(
                      label: Text('Date Range'),
                      onDeleted: () {
                        ref.read(transactionFiltersProvider.notifier).state =
                            currentFilters.copyWith(startDate: null, endDate: null);
                      },
                    ),
                ],
              ),
            ),
          
          // Transaction list
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }
                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionListItem(transaction: transaction);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 6. State Management Flow

1. **Filter Selection:** User opens filter sheet and selects criteria
2. **State Update:** `transactionFiltersProvider` is updated
3. **Provider Refresh:** `transactionsProvider` automatically refreshes due to dependency
4. **API Call:** Repository calls backend with filter query parameters
5. **UI Update:** List rebuilds with filtered results

---

## 7. Testing Considerations

- Unit tests for filter parameter building
- Widget tests for filter UI components
- Integration tests for the complete filter flow
- Test edge cases (empty results, invalid date ranges) 