import 'package:centhios/data/repositories/predictions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart';

final predictionsRepositoryProvider =
    Provider((ref) => PredictionsRepository());

final spendingPredictionProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  // TODO: Replace with actual user ID
  const userId = 'test-user-id';
  return ref.watch(predictionsRepositoryProvider).getSpendingPrediction(userId);
});

class PredictionsPage extends ConsumerWidget {
  const PredictionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(spendingPredictionProvider);
    final theme = ShadTheme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Forecast'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(spendingPredictionProvider.future),
        child: Center(
          child: predictionAsync.when(
            data: (prediction) {
              if (prediction.containsKey('error')) {
                return Text(prediction['error']);
              }
              return _buildPredictionView(prediction, theme, currencyFormat);
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionView(Map<String, dynamic> prediction,
      ShadThemeData theme, NumberFormat currencyFormat) {
    final predictedAmount = prediction['predicted_spending'];
    final month = prediction['prediction_month'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Forecast for $month',
            style: theme.textTheme.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text('Predicted Spending', style: theme.textTheme.muted),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(predictedAmount),
                    style: theme.textTheme.h2
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Based on ${prediction['based_on_months']} months of data',
              style: theme.textTheme.small),
          const SizedBox(height: 16),
          _buildHistoricalData(
              prediction['historical_data'], theme, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildHistoricalData(Map<String, dynamic> historicalData,
      ShadThemeData theme, NumberFormat currencyFormat) {
    final entries = historicalData.entries.toList();
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historical Monthly Spending', style: theme.textTheme.h4),
            const SizedBox(height: 16),
            ...entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: theme.textTheme.p),
                    Text(currencyFormat.format(entry.value),
                        style: theme.textTheme.p
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
