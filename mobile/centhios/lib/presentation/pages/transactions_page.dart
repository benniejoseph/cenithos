import 'package:centhios/app_theme.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/data/repositories/transactions_repository.dart';
import 'package:centhios/presentation/pages/sms_import_page.dart';
import 'package:centhios/presentation/widgets/add_transaction_dialog.dart';
import 'package:centhios/presentation/widgets/transaction_detail_sheet.dart';
import 'package:centhios/presentation/widgets/transaction_filter_dialog.dart';
import 'package:centhios/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:lottie/lottie.dart';

// Providers
final transactionsProvider =
    FutureProvider.autoDispose<List<DailyTransactions>>((ref) async {
  final filters = ref.watch(transactionFiltersProvider);
  final transactions =
      await ref.watch(transactionsRepositoryProvider).getTransactions(filters);

  final grouped = groupBy(transactions, (Transaction t) => t.dateOnly);
  final dailyData = grouped.entries
      .map((e) => DailyTransactions(
          e.key, e.value..sort((a, b) => b.date.compareTo(a.date))))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  return dailyData;
});

final transactionFiltersProvider =
    StateProvider<TransactionFilters>((ref) => const TransactionFilters());

// Helper class for grouping transactions
class DailyTransactions {
  final DateTime date;
  final List<Transaction> transactions;
  DailyTransactions(this.date, this.transactions);
}

// Main Widget
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  void _showDetailsSheet(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailSheet(transaction: transaction),
    );
  }

  void _editTransaction(Transaction transaction) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddTransactionDialog(transaction: transaction),
    );
    if (result == true) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
              content: Text('Transaction updated successfully.'),
              backgroundColor: Colors.green),
        );
      ref.invalidate(transactionsProvider);
    }
  }

  void _deleteTransaction(String transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
            'Are you sure you want to delete this transaction permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(transactionsRepositoryProvider)
            .deleteTransaction(transactionId);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
                content: const Text('Transaction deleted.'),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        ref.invalidate(transactionsProvider);
      } catch (e) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
                content: Text('Error deleting transaction: $e'),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions',
            style: AppTheme.theme.textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.filter_list_alt, color: AppTheme.textPrimary),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => TransactionFilterDialog(
                initialFilters: ref.read(transactionFiltersProvider),
              ),
            ),
            tooltip: 'Filter Transactions',
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined,
                color: AppTheme.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SmsImportPage()),
            ),
            tooltip: 'Import from SMS',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
        },
        child: transactionsAsync.when(
          data: (dailyData) {
            if (dailyData.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/animations/empty_state.json',
                        width: 200, height: 200),
                    const SizedBox(height: 20),
                    const Text('No transactions yet.'),
                    const SizedBox(height: 8),
                    const Text(
                        'Pull down to refresh or add a new transaction.'),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: dailyData.length,
              itemBuilder: (context, index) {
                final daily = dailyData[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        DateFormat.yMMMMd().format(daily.date),
                        style: AppTheme.theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...daily.transactions.map((transaction) {
                      return TransactionListItem(
                        transaction: transaction,
                        onTap: () => _showDetailsSheet(transaction),
                        onEdit: (ctx) async => _editTransaction(transaction),
                        onDelete: (ctx) async =>
                            _deleteTransaction(transaction.id),
                      );
                    }).toList(),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => const AddTransactionDialog(),
          ),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}
