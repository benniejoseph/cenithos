import 'package:centhios/app_theme.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final Future<void> Function(BuildContext)? onDelete;
  final Future<void> Function(BuildContext)? onEdit;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isIncome = transaction.type == 'income';

    return Slidable(
      key: ValueKey(transaction.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            label: 'Edit',
            backgroundColor: AppTheme.secondary,
            icon: Icons.edit,
            onPressed: onEdit,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(onDismissed: () => onDelete?.call(context)),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            label: 'Delete',
            backgroundColor: Theme.of(context).colorScheme.error,
            icon: Icons.delete,
            onPressed: onDelete,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                left: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.green.shade300.withOpacity(0.25),
                        Colors.green.shade300.withOpacity(0),
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: Icon(
                        transaction.getCategoryIcon(),
                        color: Colors.green.shade300,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description ?? 'N/A',
                            style: AppTheme.theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${transaction.category} • ${DateFormat.yMMMd().format(transaction.date)}',
                            style: AppTheme.theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${isIncome ? '+' : '-'}${formatter.format(transaction.amount)}',
                      style: AppTheme.theme.textTheme.bodyLarge?.copyWith(
                        color: isIncome ? Colors.green.shade300 : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
