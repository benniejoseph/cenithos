import 'dart:ui';

import 'package:centhios/app_theme.dart';
import 'package:centhios/data/models/goal_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal});

  final Goal goal;

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress > 0.6) return AppTheme.primary;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0)
            .clamp(0.0, 1.0);
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final theme = AppTheme.theme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: AppTheme.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(goal.name, style: theme.textTheme.titleLarge),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _getProgressColor(progress),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.background.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress)),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                            text: currencyFormat.format(goal.currentAmount),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        const TextSpan(text: ' saved'),
                      ],
                    ),
                  ),
                  Text(
                    'of ${currencyFormat.format(goal.targetAmount)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
