import 'dart:ui';

import 'package:centhios/app_theme.dart';
import 'package:centhios/data/models/budget_model.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/data/repositories/budgets_repository.dart';
import 'package:centhios/presentation/pages/budgets_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showCreateBudgetDialog(BuildContext context, WidgetRef ref,
    {Budget? budgetToEdit}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => CreateBudgetDialog(budgetToEdit: budgetToEdit),
  );
}

class CreateBudgetDialog extends ConsumerStatefulWidget {
  final Budget? budgetToEdit;
  const CreateBudgetDialog({super.key, this.budgetToEdit});

  @override
  ConsumerState<CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends ConsumerState<CreateBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  String? _selectedCategory;
  bool _isLoading = false;

  bool get isEditing => widget.budgetToEdit != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.budgetToEdit?.budgetedAmount.toStringAsFixed(0) ?? '');
    _selectedCategory = widget.budgetToEdit?.category;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final budgetData = {
        "category": _selectedCategory!,
        "budgetedAmount": double.parse(_amountController.text),
      };

      try {
        final repo = ref.read(budgetsRepositoryProvider);
        if (isEditing) {
          await repo.updateBudget(widget.budgetToEdit!.id, budgetData);
        } else {
          await repo.createBudget(budgetData);
        }
        ref.invalidate(budgetsProvider);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save budget: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = TransactionCategories.all
        .where((c) => c != 'Income' && c != 'Salary')
        .toList();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: AppTheme.surface.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.border.withOpacity(0.3)),
        ),
        title: Text(
          isEditing ? 'Edit Budget' : 'New Budget',
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  onChanged: isEditing
                      ? null
                      : (v) => setState(() => _selectedCategory = v),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                      labelText: 'Budgeted Amount', prefixText: '₹'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty || double.tryParse(v) == null) {
                      return 'Enter a valid amount.';
                    }
                    if (double.parse(v) <= 0) return 'Must be positive.';
                    return null;
                  },
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
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.textPrimary)),
                    ),
                  )
                : const Text('Create Budget'),
          ),
        ],
      ),
    );
  }
}
