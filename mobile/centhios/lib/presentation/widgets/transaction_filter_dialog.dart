import 'package:centhios/app_theme.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/data/repositories/categories_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionFilterDialog extends ConsumerStatefulWidget {
  final TransactionFilters initialFilters;

  const TransactionFilterDialog({super.key, required this.initialFilters});

  @override
  _TransactionFilterDialogState createState() =>
      _TransactionFilterDialogState();
}

class _TransactionFilterDialogState
    extends ConsumerState<TransactionFilterDialog> {
  late TransactionFilters _currentFilters;
  String? _selectedCategory;
  String? _selectedType;
  DateTimeRange? _selectedDateRange;

  final List<String> _types = ['income', 'expense'];

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _selectedCategory = _currentFilters.category;
    _selectedType = _currentFilters.type;
    if (_currentFilters.startDate != null && _currentFilters.endDate != null) {
      _selectedDateRange = DateTimeRange(
        start: _currentFilters.startDate!,
        end: _currentFilters.endDate!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(categoriesProvider);

    return AlertDialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Filter Transactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangePicker(context),
            const SizedBox(height: 24),
            categoriesAsyncValue.when(
              data: (categories) => _buildDropdown(
                  'Category',
                  _selectedCategory,
                  categories,
                  (val) => setState(() => _selectedCategory = val)),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),
            _buildDropdown('Type', _selectedType, _types,
                (val) => setState(() => _selectedType = val)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedCategory = null;
              _selectedType = null;
              _selectedDateRange = null;
            });
          },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final newFilters = TransactionFilters(
              category: _selectedCategory,
              type: _selectedType,
              startDate: _selectedDateRange?.start,
              endDate: _selectedDateRange?.end,
            );
            Navigator.of(context).pop(newFilters);
          },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date Range', style: AppTheme.theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 5),
              lastDate: now,
              initialDateRange: _selectedDateRange,
            );
            if (picked != null) {
              setState(() => _selectedDateRange = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.surface),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDateRange == null
                      ? 'Select a date range'
                      : '${DateFormat.yMMMd().format(_selectedDateRange!.start)} - ${DateFormat.yMMMd().format(_selectedDateRange!.end)}',
                ),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? selectedValue, List<String> items,
      ValueChanged<String?> onChanged) {
    // Ensure selectedValue is present in items, otherwise set to null
    final String? validSelectedValue =
        items.contains(selectedValue) ? selectedValue : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: validSelectedValue,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
