import 'package:centhios/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Fancy emerald green gradient shape
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C6A7).withOpacity(0.4),
                    const Color(0xFF00C6A7).withOpacity(0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: AppTheme.theme.textTheme.titleLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatter.format(totalBalance),
                            style: AppTheme.theme.textTheme.displayMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w100,
                              color:
                                  const Color(0xFF23E9B4), // Emerald-like green
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Lottie.asset(
                        'assets/animations/financial_growth.json',
                        errorBuilder: (context, error, stackTrace) {
                          // A more fitting placeholder
                          return const Icon(
                            Icons.eco_rounded,
                            color: Color(0xFF23E9B4),
                            size: 40,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIncomeExpenseRow('Income',
                        formatter.format(totalIncome), AppTheme.primary),
                    _buildIncomeExpenseRow('Expense',
                        formatter.format(totalExpense), Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
}
