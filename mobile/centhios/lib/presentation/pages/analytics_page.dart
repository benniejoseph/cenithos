import 'package:centhios/core/config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late Future<List<dynamic>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _getTransactions();
  }

  Future<List<dynamic>> _getTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final url =
        '${AppConfig.firebaseFunctionsBaseUrl}/getTransactions?uid=${user.uid}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load transactions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  Map<String, double> _calculateCategoryTotals(List<dynamic> transactions) {
    final Map<String, double> categoryTotals = {};
    for (var transaction in transactions) {
      if (transaction['type'] == 'expense') {
        final category = transaction['category'] as String;
        final amount = (transaction['amount'] as num).toDouble();
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }
    return categoryTotals;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: FutureBuilder<List<dynamic>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No expense data to display.'));
          }

          final categoryTotals = _calculateCategoryTotals(snapshot.data!);

          if (categoryTotals.isEmpty) {
            return const Center(child: Text('No expense data to display.'));
          }

          final List<Color> chartColors = [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.destructive,
            theme.colorScheme.accent,
            Colors.blue,
            Colors.orange,
            Colors.purple,
            Colors.pink,
          ];

          int colorIndex = 0;
          final pieChartSections = categoryTotals.entries.map((entry) {
            final color = chartColors[colorIndex % chartColors.length];
            colorIndex++;
            return PieChartSectionData(
              color: color,
              value: entry.value,
              title: '₹${entry.value.toStringAsFixed(0)}',
              radius: 100,
              titleStyle: theme.textTheme.small
                  .copyWith(color: theme.colorScheme.primaryForeground),
            );
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ShadCard(
                title: Text('Expense Breakdown', style: theme.textTheme.h3),
                child: Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          sections: pieChartSections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: categoryTotals.keys.map((name) {
                        final color = chartColors[
                            categoryTotals.keys.toList().indexOf(name) %
                                chartColors.length];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 16, height: 16, color: color),
                            const SizedBox(width: 4),
                            Text(name, style: theme.textTheme.p),
                          ],
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
