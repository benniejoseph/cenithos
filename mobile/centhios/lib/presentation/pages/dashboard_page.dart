import 'package:centhios/app_theme.dart';
import 'package:centhios/core/services/dashboard_providers.dart';
import 'package:centhios/data/models/budget_model.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/presentation/widgets/balance_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';

// Main Dashboard Page
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsFutureProvider);
    final budgetsAsync = ref.watch(budgetsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Dashboard', style: AppTheme.theme.textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: transactionsAsync.when(
        data: (transactions) => budgetsAsync.when(
          data: (budgets) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(transactionsFutureProvider);
                ref.invalidate(budgetsFutureProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildBalanceCard(context, transactions),
                  const SizedBox(height: 24),
                  _buildChartCard(context, transactions),
                  const SizedBox(height: 24),
                  _buildBudgetsSection(context, budgets),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(context, transactions),
                  const SizedBox(height: 100), // Space for floating nav bar
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
              child: Text('Error fetching budgets: $err',
                  style: AppTheme.theme.textTheme.bodyMedium)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text('Error fetching transactions: $err',
                style: AppTheme.theme.textTheme.bodyMedium)),
      ),
    );
  }

  Widget _buildGlassmorphicCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: AppTheme.border.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, List<Transaction> transactions) {
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, item) => sum + item.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, item) => sum + item.amount);
    final totalBalance = totalIncome - totalExpense;

    return BalanceCard(
      totalBalance: totalBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }

  Widget _buildIncomeExpenseRow(String title, String amount, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.theme.textTheme.bodySmall),
            Text(amount, style: AppTheme.theme.textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetsSection(BuildContext context, List<Budget> budgets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budgets Overview',
            style: AppTheme.theme.textTheme.headlineMedium),
        const SizedBox(height: 16),
        if (budgets.isEmpty)
          const Center(child: Text('No budgets yet.'))
        else
          Card(
            color: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00C6A7).withOpacity(0.3),
                          const Color(0xFF00C6A7).withOpacity(0),
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: budgets
                        .map((budget) => _budgetTile(context, budget))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _budgetTile(BuildContext context, Budget budget) {
    final progress = budget.spentAmount / budget.budgetedAmount;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(budget.category,
                    style: AppTheme.theme.textTheme.titleLarge),
                Text(
                  '${formatter.format(budget.spentAmount)} / ${formatter.format(budget.budgetedAmount)}',
                  style: AppTheme.theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.isNaN || progress.isInfinite ? 0 : progress,
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
      BuildContext context, List<Transaction> transactions) {
    final recent = transactions.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Transactions',
            style: AppTheme.theme.textTheme.headlineMedium),
        const SizedBox(height: 16),
        if (recent.isEmpty)
          const Center(child: Text('No transactions yet.'))
        else
          _buildGlassmorphicCard(
            child: Column(
              children:
                  recent.map((t) => _transactionTile(context, t)).toList(),
            ),
          )
      ],
    );
  }

  Widget _transactionTile(BuildContext context, Transaction transaction) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isIncome = transaction.type == 'income';
    return ListTile(
      leading: SizedBox(
        width: 35,
        height: 35,
        child: Image.asset(
          isIncome
              ? 'assets/images/credited.png'
              : 'assets/images/withdraw.png',
        ),
      ),
      title: Text(transaction.description ?? '',
          style: AppTheme.theme.textTheme.bodyLarge),
      subtitle: Text(DateFormat.yMMMd().format(transaction.date),
          style: AppTheme.theme.textTheme.bodySmall),
      trailing: Text(
        '${isIncome ? '+' : '-'}${formatter.format(transaction.amount)}',
        style: AppTheme.theme.textTheme.bodyLarge?.copyWith(
          color: isIncome ? AppTheme.primary : AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, List<Transaction> transactions) {
    // Logic to prepare chart data
    final spotsIncome = <FlSpot>[];
    final spotsExpense = <FlSpot>[];
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final dailyTotals = <DateTime, Map<String, double>>{};

    for (final t in transactions) {
      if (t.date.isAfter(thirtyDaysAgo)) {
        final day = DateTime(t.date.year, t.date.month, t.date.day);
        dailyTotals.putIfAbsent(day, () => {'income': 0.0, 'expense': 0.0});
        if (t.type == 'income') {
          dailyTotals[day]!['income'] = dailyTotals[day]!['income']! + t.amount;
        } else {
          dailyTotals[day]!['expense'] =
              dailyTotals[day]!['expense']! + t.amount;
        }
      }
    }

    final sortedDays = dailyTotals.keys.toList()..sort();
    for (final day in sortedDays) {
      final x = day.difference(thirtyDaysAgo).inDays.toDouble();
      spotsIncome.add(FlSpot(x, dailyTotals[day]!['income']!));
      spotsExpense.add(FlSpot(x, dailyTotals[day]!['expense']!));
    }

    return _buildGlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity', style: AppTheme.theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                        color: AppTheme.border.withOpacity(0.1),
                        strokeWidth: 1);
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                        color: AppTheme.border.withOpacity(0.1),
                        strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value % 5000 != 0) return const SizedBox();
                        return Text('${(value / 1000).toStringAsFixed(0)}k',
                            style: AppTheme.theme.textTheme.bodySmall,
                            textAlign: TextAlign.left);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppTheme.border, width: 1)),
                minX: 0,
                maxX: 30, // 30 days
                minY: 0,
                // Adjust max Y based on data
                lineBarsData: [
                  _lineChartBarData(spotsIncome, AppTheme.primary),
                  _lineChartBarData(spotsExpense, Colors.redAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.2),
      ),
    );
  }
}
