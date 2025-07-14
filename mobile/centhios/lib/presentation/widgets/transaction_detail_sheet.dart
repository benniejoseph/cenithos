import 'package:centhios/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:centhios/data/models/transaction_model.dart';

class TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.type == 'income' || transaction.type == 'credit';
    final amount = transaction.amount;
    final currency = transaction.currency ?? 'INR';
    final date = transaction.date;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Transaction Details',
                        style: AppTheme.theme.textTheme.headlineSmall),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill),
                      onPressed: () => Navigator.of(context).pop(),
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.border),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildAmountDisplay(isIncome, amount, currency),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      context,
                      icon: CupertinoIcons.info_circle,
                      title: 'Description',
                      value: transaction.description ?? 'N/A',
                    ),
                    _buildDetailRow(
                      context,
                      icon: CupertinoIcons.tag,
                      title: 'Category',
                      value: transaction.category ?? 'Uncategorized',
                    ),
                    _buildDetailRow(
                      context,
                      icon: CupertinoIcons.calendar,
                      title: 'Date & Time',
                      value:
                          DateFormat('E, d MMM yyyy, hh:mm a').format(date),
                    ),
                    const Divider(height: 32, color: AppTheme.border),
                    _buildDetailRow(
                      context,
                      icon: CupertinoIcons.building_2_fill,
                      title: 'Vendor',
                      value: transaction.vendor ?? 'N/A',
                    ),
                    _buildDetailRow(
                      context,
                      icon: CupertinoIcons.creditcard,
                      title: 'Bank / Card',
                      value: transaction.bank ?? 'N/A',
                    ),
                    _buildDetailRow(
                      context,
                      icon: CupertinoIcons.number,
                      title: 'Reference ID',
                      value: transaction.ref_id ?? 'N/A',
                      isMono: true,
                    ),
                    _buildDetailRow(
                      context,
                      icon: CupertinoIcons.square_arrow_down_on_square,
                      title: 'Source',
                      value: transaction.source ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountDisplay(bool isIncome, double amount, String currency) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              isIncome ? 'Amount Credited' : 'Amount Debited',
              style: AppTheme.theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '${isIncome ? '+' : '-'} ${NumberFormat.currency(
                symbol: currency == 'INR' ? '₹' : (currency),
                decimalDigits: 2,
              ).format(amount)}',
              style: AppTheme.theme.textTheme.displaySmall?.copyWith(
                color: isIncome ? AppTheme.primary : AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool isMono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.theme.textTheme.labelLarge
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: isMono
                      ? AppTheme.theme.textTheme.bodyMedium
                          ?.copyWith(fontFamily: 'RobotoMono')
                      : AppTheme.theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
