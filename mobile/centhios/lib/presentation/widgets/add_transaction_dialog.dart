import 'dart:ui';

import 'package:centhios/app_theme.dart';
import 'package:centhios/data/repositories/categories_repository.dart';
import 'package:centhios/data/repositories/transactions_repository.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/presentation/pages/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void showAddTransactionDialog(BuildContext context,
    {Transaction? transaction}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => AddTransactionDialog(transaction: transaction),
  );
}

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key, this.transaction});
  final Transaction? transaction;

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  String _selectedType = 'expense';
  String _selectedCategory = 'Other';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // For feedback loop
  String? _originalCategory;

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.transaction?.description ?? '');
    _amountController = TextEditingController(
        text: widget.transaction?.amount.toStringAsFixed(0) ?? '');
    if (isEditing) {
      final t = widget.transaction!;
      _selectedType = t.type;
      _selectedDate = t.date;
      _selectedCategory = t.category ?? 'Uncategorized';
      // Store original category for feedback loop
      _originalCategory = t.category;
    } else {
      _selectedCategory = 'Uncategorized';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final amount = double.tryParse(_amountController.text) ?? 0.0;
        final description = _descriptionController.text;

        if (isEditing) {
          // AI Feedback Loop Logic
          final originalTx = widget.transaction!;
          final bool isAiSource = originalTx.source == 'sms-ai';
          final bool categoryChanged = _originalCategory != null &&
              _originalCategory != _selectedCategory;

          if (isAiSource && categoryChanged) {
            // No need to await, let it run in the background
            ref.read(transactionsRepositoryProvider).sendCategoryFeedback(
                  transactionId: originalTx.id,
                  description: originalTx.description ?? '',
                  oldCategory: _originalCategory!,
                  newCategory: _selectedCategory,
                );
          }

          final updatedTransaction = originalTx.copyWith(
            description: description,
            amount: amount,
            type: _selectedType,
            category: _selectedCategory,
            date: _selectedDate,
          );
          await ref
              .read(transactionsRepositoryProvider)
              .updateTransaction(updatedTransaction);
        } else {
          await ref.read(transactionsRepositoryProvider).createTransaction(
                description: description,
                amount: amount,
                date: _selectedDate,
                type: _selectedType,
                category: _selectedCategory,
              );
        }
        ref.invalidate(transactionsProvider);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaction saved successfully!'),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to save transaction: $e'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16)),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Theme(
        // Apply custom theme to the dialog's content
        data: Theme.of(context).copyWith(
          inputDecorationTheme: AppTheme.theme.inputDecorationTheme.copyWith(
            fillColor: Colors.black.withOpacity(0.4), // Changed to black
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.border.withOpacity(0.2)),
            ),
          ),
        ),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.border.withOpacity(0.3)),
          ),
          title: Text(
            isEditing ? 'Edit Transaction' : 'New Transaction',
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                        labelText: 'Amount', prefixText: '₹'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          dropdownColor: Colors.black
                              .withOpacity(0.9), // Set dropdown menu color
                          onChanged: (v) => setState(() => _selectedType = v!),
                          items: const [
                            DropdownMenuItem(
                                value: 'expense', child: Text('Expense')),
                            DropdownMenuItem(
                                value: 'income', child: Text('Income')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: categoriesAsyncValue.when(
                          data: (categories) {
                            // Ensure the currently selected category is in the list.
                            final categoryItems = categories.toSet();
                            categoryItems.add(_selectedCategory);
                            final finalCategories = categoryItems.toList();
                            // Ensure the value passed to Dropdown is in the list
                            final String? selectedValue =
                                finalCategories.contains(_selectedCategory)
                                    ? _selectedCategory
                                    : null;

                            return DropdownButtonFormField<String>(
                              value: selectedValue,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              dropdownColor: Colors.black
                                  .withOpacity(0.9), // Set dropdown menu color
                              onChanged: (v) =>
                                  setState(() => _selectedCategory = v!),
                              isExpanded: true,
                              items: finalCategories
                                  .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        overflow: TextOverflow.ellipsis,
                                      )))
                                  .toList(),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) =>
                              const Text('Could not load categories'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat.yMMMd().format(_selectedDate)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
