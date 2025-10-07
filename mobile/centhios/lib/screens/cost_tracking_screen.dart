/// 💰 Cost Tracking Screen - Google Cloud Platform Costs
/// 
/// Real-time tracking of:
/// - Gemini API costs
/// - Firestore storage costs
/// - Cloud Run compute costs
/// - Total GCP spending
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/centhios_api_service.dart';
import 'dart:async';

class CostTrackingScreen extends StatefulWidget {
  const CostTrackingScreen({Key? key}) : super(key: key);

  @override
  State<CostTrackingScreen> createState() => _CostTrackingScreenState();
}

class _CostTrackingScreenState extends State<CostTrackingScreen> {
  bool _isLoading = true;
  String? _error;
  
  Map<String, dynamic>? _costSummary;
  List<Map<String, dynamic>> _dailyCosts = [];
  List<Map<String, dynamic>> _categoryBreakdown = [];
  List<Map<String, dynamic>> _serviceBreakdown = [];
  Map<String, dynamic>? _monthlyEstimate;
  Map<String, dynamic>? _costAlerts;
  
  int _selectedDays = 30;
  final List<int> _dayOptions = [7, 14, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _loadCostData();
  }

  Future<void> _loadCostData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      // Load all cost data in parallel
      final results = await Future.wait([
        CenthiosAPIService.getCostSummary(userId: userId),
        CenthiosAPIService.getDailyCosts(days: _selectedDays, userId: userId),
        CenthiosAPIService.getCostByCategory(days: _selectedDays, userId: userId),
        CenthiosAPIService.getCostByService(days: _selectedDays, userId: userId),
        CenthiosAPIService.estimateMonthlyCost(userId: userId),
        CenthiosAPIService.getCostAlerts(userId: userId, thresholdUsd: 10.0),
      ]);

      setState(() {
        _costSummary = results[0] as Map<String, dynamic>;
        _dailyCosts = results[1] as List<Map<String, dynamic>>;
        _categoryBreakdown = results[2] as List<Map<String, dynamic>>;
        _serviceBreakdown = results[3] as List<Map<String, dynamic>>;
        _monthlyEstimate = results[4] as Map<String, dynamic>;
        _costAlerts = results[5] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Cost Tracking'),
        backgroundColor: const Color(0xFF1a1a1a),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCostData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading data:\n$_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCostData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCostData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cost Alerts
                        if (_costAlerts?['has_alerts'] == true) _buildAlerts(),
                        
                        // Summary Cards
                        _buildSummaryCards(),
                        
                        const SizedBox(height: 24),
                        
                        // Day Selector
                        _buildDaySelector(),
                        
                        const SizedBox(height: 16),
                        
                        // Daily Cost Chart
                        _buildDailyCostChart(),
                        
                        const SizedBox(height: 24),
                        
                        // Category Breakdown
                        _buildCategoryBreakdown(),
                        
                        const SizedBox(height: 24),
                        
                        // Service Breakdown
                        _buildServiceBreakdown(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildAlerts() {
    final alerts = _costAlerts?['alerts'] as List<dynamic>? ?? [];
    
    return Column(
      children: alerts.map((alert) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'ALERT',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert['message'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards() {
    final totalCost = _costSummary?['total_cost'] ?? 0.0;
    final estimatedMonthly = _monthlyEstimate?['estimated_monthly_cost'] ?? 0.0;
    final dailyAvg = _monthlyEstimate?['daily_average'] ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Cost',
            '\$${totalCost.toStringAsFixed(4)}',
            Icons.attach_money,
            const Color(0xFF00C6A7),
            'Last $_selectedDays days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Monthly Est.',
            '\$${estimatedMonthly.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.blue,
            'Based on ${_monthlyEstimate?['based_on_days'] ?? 0} days',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Row(
      children: [
        const Text(
          'Period:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _dayOptions.map((days) {
                final isSelected = days == _selectedDays;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$days days'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDays = days;
                        });
                        _loadCostData();
                      }
                    },
                    selectedColor: const Color(0xFF00C6A7),
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyCostChart() {
    if (_dailyCosts.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C6A7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Cost Trend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.01,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _selectedDays > 30 ? 10 : 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _dailyCosts.length) {
                          final date = _dailyCosts[value.toInt()]['date'] as String;
                          final day = date.split('-').last;
                          return Text(
                            day,
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_dailyCosts.length - 1).toDouble(),
                minY: 0,
                maxY: _dailyCosts.map((d) => d['total'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: _dailyCosts.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['total'] as double);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF00C6A7),
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00C6A7).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C6A7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost by Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._categoryBreakdown.map((category) {
            final name = category['category'] as String;
            final cost = category['cost'] as double;
            final percentage = category['percentage'] as double;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCategoryName(name),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '\$${cost.toStringAsFixed(4)} (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(color: Color(0xFF00C6A7), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C6A7)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceBreakdown() {
    if (_serviceBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C6A7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost by Service',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._serviceBreakdown.take(10).map((service) {
            final name = service['service'] as String;
            final cost = service['cost'] as double;
            final percentage = service['percentage'] as double;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '\$${cost.toStringAsFixed(4)}',
                    style: const TextStyle(color: Color(0xFF00C6A7), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatCategoryName(String name) {
    return name.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}

