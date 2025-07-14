import 'dart:ui';

import 'package:centhios/app_theme.dart';
import 'package:centhios/data/models/goal_model.dart';
import 'package:centhios/data/repositories/goals_repository.dart';
import 'package:centhios/presentation/pages/goals_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void showCreateGoalDialog(BuildContext context, WidgetRef ref,
    {Goal? goalToEdit}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => CreateGoalDialog(goalToEdit: goalToEdit),
  );
}

class CreateGoalDialog extends ConsumerStatefulWidget {
  final Goal? goalToEdit;
  const CreateGoalDialog({super.key, this.goalToEdit});

  @override
  ConsumerState<CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends ConsumerState<CreateGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  bool get isEditing => widget.goalToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.goalToEdit?.name ?? '');
    _amountController = TextEditingController(
        text: widget.goalToEdit?.targetAmount.toStringAsFixed(0) ?? '');
    _selectedDate = widget.goalToEdit?.targetDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isLoading = true);

      final goalData = {
        "name": _nameController.text,
        "targetAmount": double.parse(_amountController.text),
        "targetDate": _selectedDate!.toIso8601String(),
      };

      try {
        final repo = ref.read(goalsRepositoryProvider);
        if (isEditing) {
          await repo.updateGoal(widget.goalToEdit!.id, goalData);
        } else {
          await repo.createGoal(goalData);
        }
        ref.invalidate(goalsProvider);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save goal: $e')),
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: AppTheme.surface.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.border.withOpacity(0.3)),
        ),
        title: Text(
          isEditing ? 'Edit Goal' : 'New Goal',
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Goal Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                      labelText: 'Target Amount', prefixText: '₹'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty || double.tryParse(v) == null) {
                      return 'Enter a valid amount.';
                    }
                    if (double.parse(v) <= 0) return 'Must be positive.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _pickDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Target Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select a date'
                          : DateFormat.yMMMd().format(_selectedDate!),
                    ),
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
                : Text(isEditing ? 'Save Changes' : 'Create'),
          ),
        ],
      ),
    );
  }
}
