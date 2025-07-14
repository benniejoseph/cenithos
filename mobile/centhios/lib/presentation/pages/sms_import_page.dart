import 'package:centhios/app_theme.dart';
import 'package:centhios/core/services/sms_import_service.dart';
import 'package:centhios/data/repositories/categories_repository.dart';
import 'package:centhios/presentation/widgets/add_transaction_dialog.dart';
import 'package:centhios/presentation/widgets/transaction_detail_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:centhios/core/config.dart';
import 'package:intl/intl.dart';

import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/core/services/firebase_providers.dart';

class SmsImportPage extends ConsumerStatefulWidget {
  const SmsImportPage({super.key});

  @override
  ConsumerState<SmsImportPage> createState() => _SmsImportPageState();
}

class _SmsImportPageState extends ConsumerState<SmsImportPage> {
  bool _isLoading = false;
  String _loadingStatus = 'Ready to scan.';
  List<Transaction> _foundTransactions = [];
  final Set<int> _selectedIndices = {};

  // Filter controllers
  final _countController = TextEditingController(text: '500');
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    // No longer start import automatically
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isInfo = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : (isInfo ? Colors.blue.shade700 : Colors.green),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }

  Future<void> _startSmsImport() async {
    setState(() {
      _isLoading = true;
      _loadingStatus = 'Requesting SMS permissions...';
    });
    print("[SmsImportPage] INFO: Starting SMS import process.");

    var status = await Permission.sms.request();
    if (!status.isGranted) {
      print("[SmsImportPage] ERROR: SMS permission not granted.");
      _showSnackBar('SMS permission is required to import transactions.',
          isError: true);
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _loadingStatus = 'Fetching categories & reading SMS...');
    print("[SmsImportPage] INFO: Fetching categories from provider.");
    try {
      // Fetch categories first
      final categories = await ref.read(categoriesProvider.future);
      print("[SmsImportPage] INFO: Successfully fetched ${categories.length} categories.");
      final service = ref.read(smsImportServiceProvider);

      final transactions = await service.analyzeSms(
        dateRange: _dateRange,
        categories: categories, // Pass categories to the service
      );
      setState(() {
        _foundTransactions = transactions;
        _loadingStatus =
            'Found ${_foundTransactions.length} potential transactions.';
        _isLoading = false;
        // Pre-select all found transactions
        _selectedIndices
            .addAll(List.generate(_foundTransactions.length, (index) => index));
      });
      if (_foundTransactions.isEmpty) {
        _showSnackBar('Could not find any new transactions from your SMS.',
            isError: false);
      }
    } catch (e) {
      print("[SmsImportPage] CRITICAL: Error during import process: $e");
      _showSnackBar('An error occurred: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelectedTransactions() async {
    if (_selectedIndices.isEmpty) {
      _showSnackBar('No transactions selected.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingStatus = 'Saving ${_selectedIndices.length} transactions...';
    });

    try {
      final selected =
          _selectedIndices.map((index) => _foundTransactions[index]).toList();
      final report =
          await ref.read(smsImportServiceProvider).saveTransactions(selected as List<Transaction>);

      final created = report.created;
      final duplicates = report.duplicates;
      final errors = report.errors;

      List<String> messages = [];
      if (created > 0) messages.add('$created successful');
      if (duplicates > 0) messages.add('$duplicates duplicates');
      if (errors > 0) messages.add('$errors failed');

      final message =
          messages.isEmpty ? 'No new transactions found.' : messages.join(', ');
      _showSnackBar(
        'Import complete: $message',
        isError: errors > 0 && created == 0,
        isInfo: errors == 0 && duplicates > 0 && created == 0,
      );

      if (mounted && created > 0) {
        // Pop only if something was actually imported
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar('An error occurred while saving: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.theme;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Import SMS Transactions',
            style: theme.textTheme.headlineMedium),
        backgroundColor: AppTheme.background.withOpacity(0.85),
        elevation: 0,
        actions: [
          if (_foundTransactions.isNotEmpty)
            IconButton(
              icon: Icon(_selectedIndices.length == _foundTransactions.length
                  ? Icons.check_box
                  : Icons.check_box_outline_blank),
              onPressed: () {
                setState(() {
                  if (_selectedIndices.length == _foundTransactions.length) {
                    _selectedIndices.clear();
                  } else {
                    _selectedIndices.addAll(List.generate(
                        _foundTransactions.length, (index) => index));
                  }
                });
              },
            )
        ],
      ),
      body: Column(
        children: [
          _buildFilterControls(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator(theme)
                : _buildTransactionList(),
          ),
        ],
      ),
      floatingActionButton: _foundTransactions.isNotEmpty && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _saveSelectedTransactions,
              label: Text('Import (${_selectedIndices.length})'),
              icon: const Icon(Icons.download_done),
            )
          : null,
    );
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scan Options', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateRangePicker(context),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _startSmsImport,
                icon: const Icon(Icons.radar_outlined, color: Colors.white),
                label: const Text('Scan', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSelectAllCheckbox(),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: _dateRange ??
              DateTimeRange(
                  start: now.subtract(const Duration(days: 30)), end: now),
          firstDate: DateTime(now.year - 2),
          lastDate: now,
        );
        if (picked != null) {
          setState(() {
            _dateRange = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.calendar_today_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _dateRange == null
                    ? 'Select Date Range'
                    : '${DateFormat.yMMMd().format(_dateRange!.start)} - ${DateFormat.yMMMd().format(_dateRange!.end)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllCheckbox() {
    if (_foundTransactions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Checkbox(
            value: _selectedIndices.length == _foundTransactions.length,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedIndices.addAll(List.generate(
                      _foundTransactions.length, (index) => index));
                } else {
                  _selectedIndices.clear();
                }
              });
            },
            activeColor: AppTheme.primary,
            checkColor: AppTheme.background,
          ),
          const SizedBox(width: 8),
          Text(
            'Select All (${_foundTransactions.length})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/ai_load.json',
              width: 250, height: 250),
          const SizedBox(height: 20),
          Text(_loadingStatus,
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_foundTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/sms_scan.json',
                width: 250, height: 250),
            const SizedBox(height: 20),
            Text(
              'Ready to find your transactions.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a date range and tap "Scan".',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _foundTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _foundTransactions[index];
        final isSelected = _selectedIndices.contains(index);

        final isExpense = transaction.type == 'expense';

        return Slidable(
          key: ValueKey(transaction.id ?? index),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) {
                  // Handle delete
                  setState(() {
                    _foundTransactions.removeAt(index);
                    _selectedIndices.remove(index);
                    // Adjust other selected indices
                    final newSelections = _selectedIndices
                        .map((i) => i > index ? i - 1 : i)
                        .toSet();
                    _selectedIndices
                      ..clear()
                      ..addAll(newSelections);
                  });
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Discard',
              ),
            ],
          ),
          child: ListTile(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            },
            leading: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedIndices.add(index);
                  } else {
                    _selectedIndices.remove(index);
                  }
                });
              },
            ),
            title: Text(transaction.description ?? 'No Description',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${transaction.category} • ${DateFormat.yMMMd().format(transaction.date)}'),
            trailing: GestureDetector(
              onTap: () {
                _showTransactionDetails(transaction);
              },
              child: Text(
                '${isExpense ? '-' : '+'}${NumberFormat.currency(symbol: '₹').format(transaction.amount)}',
                style: TextStyle(
                  color: isExpense ? Colors.redAccent : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _editTransaction(int index) async {
    final transactionToEdit = _foundTransactions[index];

    // 2. Show the dialog with the Transaction object
    final updatedTransaction = await showDialog<Transaction>(
      context: context,
      builder: (context) => AddTransactionDialog(
        transaction: transactionToEdit,
      ),
    );

    // 3. If updated, update the state with the new Transaction object
    if (updatedTransaction != null) {
      setState(() {
        _foundTransactions[index] = updatedTransaction;
      });
      _showSnackBar('Transaction updated locally.', isError: false);
    }
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          // The sheet expects a Transaction object directly
          return TransactionDetailSheet(transaction: transaction);
        });
  }

  Widget _buildSubtitle(BuildContext context, Map<dynamic, dynamic> tx) {
    final category = tx['category'] ?? 'Uncategorized';
    final date = tx['date'] ?? '';
    final bank = tx['bank'];

    List<String> parts = [category, date];
    if (bank != null && bank.toString().isNotEmpty) {
      parts.add(bank);
    }

    return Text(
      parts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ImportedTransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transactionMap;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _ImportedTransactionListItem({
    required this.transactionMap,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Convert map to transaction object for use in the UI
    final transaction = Transaction.fromJson(transactionMap);
    final isIncome = transaction.type == 'income';
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Slidable(
      key: ValueKey(transaction.ref_id ?? transaction.description),
       startActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (ctx) => _showEditDialog(context, transaction),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: CupertinoIcons.pencil,
            label: 'Edit',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _showDetailsSheet(context, transaction),
        leading: Checkbox(
          value: isSelected,
          onChanged: onChanged,
        ),
        title: Text(
          transaction.description ?? 'No Description',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.category ?? 'Uncategorized'),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date)),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${currencyFormat.format(transaction.amount)}',
          style: TextStyle(
            color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (_) => AddTransactionDialog(transaction: transaction),
    );
  }

  void _showDetailsSheet(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TransactionDetailSheet(transaction: transaction);
      },
    );
  }
}
