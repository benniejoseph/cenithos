import 'package:centhios/core/services/dashboard_providers.dart';
import 'package:centhios/core/theme/app_theme.dart';
import 'package:centhios/data/models/unified_transaction_model.dart';
import 'package:centhios/presentation/widgets/carousel_balance_card.dart';
import 'package:centhios/presentation/widgets/dashboard/financial_health_card.dart';
import 'package:centhios/presentation/widgets/dashboard/mobile_recent_transactions.dart';
import 'package:centhios/presentation/widgets/dashboard/enhanced_activity_chart.dart';
import 'package:centhios/presentation/widgets/dashboard/cashflow_sparkline_card.dart';
import 'package:centhios/presentation/widgets/dashboard/upcoming_bills_card.dart';
import 'package:centhios/presentation/widgets/dashboard/spending_heatmap.dart';
import 'package:centhios/presentation/widgets/dashboard/interactive_category_donut.dart';
import 'package:centhios/presentation/widgets/dashboard/trend_comparison_chart.dart';
import 'package:centhios/presentation/widgets/dashboard/budget_vs_actual_chart.dart';
import 'package:centhios/presentation/widgets/dashboard/spending_patterns_widget.dart';
import 'package:centhios/presentation/widgets/streak_widget.dart';
import 'package:centhios/presentation/pages/predictions_page.dart';
import 'package:centhios/presentation/pages/financial_health_page.dart';
import 'package:centhios/presentation/pages/achievements_page.dart';
import 'package:centhios/presentation/pages/challenges_hub_page.dart';
import 'package:flutter/material.dart';
import '../../features/voice_banking/voice_banking_screen.dart';
import '../../features/ar_receipt_scanner/ar_scanner_screen.dart';
import '../../screens/analytics_screen.dart';
import '../../screens/cost_tracking_screen.dart';
import '../../screens/scheduled_payments_screen.dart';
import '../../screens/cashback_screen.dart';
import '../../screens/savings_goals_screen.dart';
import '../../screens/loans_emi_screen.dart';
import '../../screens/notification_center_screen.dart';
import '../../core/services/notification_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
// import 'package:centhios/presentation/pages/ai_assistant_page.dart';

// Main Dashboard Page
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsFutureProvider);
    final budgetsAsync = ref.watch(budgetsFutureProvider);

    return Container(
      decoration: ComponentThemes.dashboardBackgroundDecoration(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dashboard', 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Notification bell icon
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () async {
                    // Initialize notifications if needed
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await notificationManager.initialize(user.uid);
                    }
                    
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationCenterScreen(),
                        ),
                      );
                    }
                  },
                ),
                // Unread count badge
                if (notificationManager.getUnreadCount() > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${notificationManager.getUnreadCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
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
                  // Balance Card
                  CarouselBalanceCard(
                    transactions: transactions,
                    onCustomDateRange: (dateRange) {
                      // Handle custom date range selection if needed
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Recent Transactions (Existing widget moved to top)
                  MobileRecentTransactions(transactions: transactions),
                  const SizedBox(height: 24),
                  
                  // AI Predictions Card
                  _buildPredictionsCard(context),
                  const SizedBox(height: 24),
                  
                  // Financial Activity Chart
                  EnhancedActivityChart(transactions: transactions),
                  const SizedBox(height: 24),
                  
                  // Spending Heatmap
                  SpendingHeatmap(transactions: transactions),
                  const SizedBox(height: 24),
                  
                  // Category Breakdown
                  InteractiveCategoryDonut(transactions: transactions),
                  const SizedBox(height: 24),
                  
                  // Trend Comparison
                  TrendComparisonChart(transactions: transactions),
                  const SizedBox(height: 24),
                  
                  // Budget vs Actual
                  BudgetVsActualChart(
                    transactions: transactions,
                    budgets: budgets,
                  ),
                  const SizedBox(height: 24),
                  // AI Features Section
                  _buildAIFeaturesSection(context),
                  const SizedBox(height: 24),
                  _buildGlassmorphicCard(
                    context: context,
                    child: CashflowSparklineCard(transactions: transactions),
                  ),
                  const SizedBox(height: 24),
                  _buildGlassmorphicCard(
                    context: context,
                    child: UpcomingBillsCard(transactions: transactions),
                  ),
                  const SizedBox(height: 24),
                  SpendingPatternsWidget(transactions: transactions),
                  const SizedBox(height: 100), // Space for floating nav bar
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
              child: Text('Error fetching budgets: $err',
                  style: Theme.of(context).textTheme.bodyMedium)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text('Error fetching transactions: $err',
                style: Theme.of(context).textTheme.bodyMedium)),
      ),
      ),
    );
  }

  Widget _buildGlassmorphicCard({required BuildContext context, required Widget child}) {
    return Container(
      decoration: ComponentThemes.glassmorphicDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: ComponentThemes.financialCardDecoration(context),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PredictionsPage()),
        );
      },
      child: Card(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Emerald gradient background
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
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C6A7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insights,
                          color: Color(0xFF00C6A7),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Predictions & Insights',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View forecasts, bills, subscriptions & budget',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPredictionStat(
                        context,
                        icon: Icons.trending_up,
                        label: 'Forecasts',
                        color: Colors.green,
                      ),
                      _buildPredictionStat(
                        context,
                        icon: Icons.account_balance_wallet,
                        label: 'Cash Flow',
                        color: Colors.blue,
                      ),
                      _buildPredictionStat(
                        context,
                        icon: Icons.receipt_long,
                        label: 'Bills',
                        color: Colors.orange,
                      ),
                      _buildPredictionStat(
                        context,
                        icon: Icons.subscriptions,
                        label: 'Subscriptions',
                        color: Colors.purple,
                      ),
                      _buildPredictionStat(
                        context,
                        icon: Icons.pie_chart,
                        label: 'Budget',
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScoreCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FinancialHealthPage()),
        );
      },
      child: Card(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Emerald gradient background shape (matching Balance card)
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
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C6A7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Color(0xFF00C6A7),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Financial Health Score',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your financial wellness',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreStat(
                        context,
                        icon: Icons.savings,
                        label: 'Savings',
                        color: Colors.green,
                      ),
                      _buildScoreStat(
                        context,
                        icon: Icons.shopping_cart,
                        label: 'Spending',
                        color: Colors.orange,
                      ),
                      _buildScoreStat(
                        context,
                        icon: Icons.credit_card,
                        label: 'Debt',
                        color: Colors.red,
                      ),
                      _buildScoreStat(
                        context,
                        icon: Icons.trending_up,
                        label: 'Growth',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AchievementsPage()),
        );
      },
      child: Card(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Emerald gradient background
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
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C6A7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Color(0xFF00C6A7),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Achievements',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Unlock financial milestones',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAchievementStat(
                        context,
                        icon: '🥉',
                        label: 'Bronze',
                      ),
                      _buildAchievementStat(
                        context,
                        icon: '🥈',
                        label: 'Silver',
                      ),
                      _buildAchievementStat(
                        context,
                        icon: '🥇',
                        label: 'Gold',
                      ),
                      _buildAchievementStat(
                        context,
                        icon: '💎',
                        label: 'Platinum',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementStat(
    BuildContext context, {
    required String icon,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengesCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChallengesHubPage()),
        );
      },
      child: Container(
        decoration: ComponentThemes.glassmorphicDecoration(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withOpacity(0.3),
                    Colors.teal.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Challenges',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start your savings journey',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildChallengeStat(
                        context,
                        icon: '📅',
                        label: '52-Week',
                      ),
                      _buildChallengeStat(
                        context,
                        icon: '🚫',
                        label: 'No-Spend',
                      ),
                      _buildChallengeStat(
                        context,
                        icon: '⬆️',
                        label: 'Round-Up',
                      ),
                      _buildChallengeStat(
                        context,
                        icon: '⚡',
                        label: 'Sprint',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeStat(
    BuildContext context, {
    required String icon,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // AI Features Section
  Widget _buildAIFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF00C6A7),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'AI-Powered Features',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.5)),
                ),
                child: const Text(
                  'Gemini 2.5 Pro',
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Voice Banking Card
        _buildAIFeatureCard(
          context,
          title: 'Voice Banking',
          subtitle: 'Talk to your AI assistant',
          icon: Icons.mic,
          gradient: const LinearGradient(
            colors: [Color(0xFF00BCD4), Color(0xFF009688)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VoiceBankingScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // AR Scanner Card
        _buildAIFeatureCard(
          context,
          title: 'Scan Receipt',
          subtitle: 'AR-powered instant extraction',
          icon: Icons.document_scanner,
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ARScannerScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Analytics Card
        _buildAIFeatureCard(
          context,
          title: 'AI Analytics',
          subtitle: 'Prophet forecasting & insights',
          icon: Icons.analytics,
          gradient: const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AnalyticsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Cost Tracking Card
        _buildAIFeatureCard(
          context,
          title: 'Cost Tracking',
          subtitle: 'Monitor GCP & AI costs',
          icon: Icons.account_balance_wallet,
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CostTrackingScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // SMS Intelligence Features Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb,
                color: Color(0xFF00C6A7),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'SMS Intelligence',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Scheduled Payments Card
        _buildAIFeatureCard(
          context,
          title: 'Scheduled Payments',
          subtitle: 'Track EMIs, bills & due dates',
          icon: Icons.schedule,
          gradient: const LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScheduledPaymentsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Cashback Tracker Card
        _buildAIFeatureCard(
          context,
          title: 'Cashback & Rewards',
          subtitle: 'Track your earnings from every source',
          icon: Icons.card_giftcard,
          gradient: const LinearGradient(
            colors: [Color(0xFFfeca57), Color(0xFFff9ff3)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CashbackScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // Smart Banking Features Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance,
                color: Color(0xFF00C6A7),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart Banking',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Savings Goals Card
        _buildAIFeatureCard(
          context,
          title: 'Savings Goals',
          subtitle: 'Create & track your financial goals',
          icon: Icons.savings,
          gradient: const LinearGradient(
            colors: [Color(0xFF00C6A7), Color(0xFF00A896)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavingsGoalsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Loans & EMI Card
        _buildAIFeatureCard(
          context,
          title: 'Loans & EMI',
          subtitle: 'Optimize prepayments & compare loans',
          icon: Icons.account_balance_wallet,
          gradient: const LinearGradient(
            colors: [Color(0xFFfa709a), Color(0xFFfee140)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoansEMIScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAIFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
