import 'package:centhios/app_theme.dart';
import 'package:centhios/data/models/budget_model.dart';
import 'package:centhios/data/repositories/budgets_repository.dart';
import 'package:centhios/presentation/widgets/budget_card.dart';
import 'package:centhios/presentation/widgets/create_budget_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final budgetsProvider = FutureProvider.autoDispose<List<Budget>>((ref) async {
  final repository = ref.watch(budgetsRepositoryProvider);
  // Invalidate this provider when a budget is created/updated/deleted
  ref.onDispose(() {});
  return repository.getBudgets();
});

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(budgetsProvider.future),
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          child: budgetsAsync.when(
            data: (budgets) {
              if (budgets.isEmpty) {
                return const Center(
                  child: Text("You haven't created any budgets yet."),
                );
              }
              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(context, budgets),
                  const SizedBox(height: 24),
                  ...budgets.map((budget) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Dismissible(
                          key: Key(budget.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            ref
                                .read(budgetsRepositoryProvider)
                                .deleteBudget(budget.id);
                            ref.invalidate(budgetsProvider);
                          },
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete_sweep_rounded,
                                color: AppTheme.textPrimary),
                          ),
                          child: GestureDetector(
                            onTap: () => showCreateBudgetDialog(context, ref,
                                budgetToEdit: budget),
                            child: BudgetCard(budget: budget),
                          ),
                        ),
                      )),
                  const SizedBox(height: 100), // Space for floating nav bar
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () => showCreateBudgetDialog(context, ref),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: AppTheme.textPrimary),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('Budgets', style: AppTheme.theme.textTheme.headlineMedium),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<Budget> budgets) {
    final totalBudgeted = budgets.fold(0.0, (sum, b) => sum + b.budgetedAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final remaining = totalBudgeted - totalSpent;
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.surface.withOpacity(0.15),
        border: Border.all(color: AppTheme.border.withOpacity(0.2), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryFigure('Budgeted', totalBudgeted, currencyFormat),
          _buildSummaryFigure('Spent', totalSpent, currencyFormat),
          _buildSummaryFigure('Remaining', remaining, currencyFormat,
              color: remaining >= 0 ? AppTheme.primary : Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildSummaryFigure(String title, double amount, NumberFormat format,
      {Color? color}) {
    return Column(
      children: [
        Text(title, style: AppTheme.theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          format.format(amount),
          style: AppTheme.theme.textTheme.titleLarge?.copyWith(
            color: color ?? AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
