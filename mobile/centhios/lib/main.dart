import 'dart:ui';

import 'package:centhios/app_theme.dart';
import 'package:centhios/presentation/pages/budgets_page.dart';
import 'package:centhios/presentation/pages/dashboard_page.dart';
import 'package:centhios/presentation/pages/goals_page.dart';
import 'package:centhios/presentation/pages/investments_page.dart';
import 'package:centhios/presentation/pages/profile_page.dart';
import 'package:centhios/presentation/pages/settings_page.dart';
import 'package:centhios/presentation/pages/sms_import_page.dart';
import 'package:centhios/presentation/pages/transactions_page.dart';
import 'package:centhios/presentation/widgets/aurora_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centhios/firebase_options.dart';
import 'package:centhios/core/services/sms_import_service.dart';
import 'package:centhios/data/repositories/categories_repository.dart';
import 'package:dot_curved_bottom_nav/dot_curved_bottom_nav.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

// --- Background Task ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // We need to initialize services here again for the background isolate
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Create a new container to access providers in the background
    final container = ProviderContainer();

    try {
      print("--- Background SMS Sync Started ---");
      final permission = await Permission.sms.status;
      if (!permission.isGranted) {
        print("SMS permission not granted. Skipping background sync.");
        return Future.value(false);
      }

      final smsService = container.read(smsImportServiceProvider);
      final categories = await container.read(categoriesRepositoryProvider).getCategories();

      // For the background task, we only care about recent messages.
      // We define a date range for the last 4 hours to avoid processing the entire inbox.
      final now = DateTime.now();
      final dateRange = DateTimeRange(
        start: now.subtract(const Duration(hours: 4)),
        end: now,
      );

      final transactions = await smsService.analyzeSms(
        dateRange: dateRange,
        categories: categories,
      );

      if (transactions.isNotEmpty) {
        // Since the service now fetches its own messages, we need a way
        // to avoid re-importing the same transactions. The backend handles
        // this with the `ref_id`, so we just need to call save.
        await smsService.saveTransactions(transactions);
        print(
            "--- Successfully saved ${transactions.length} new transactions in background ---");
      } else {
        print("--- No new transactions found in background SMS sync ---");
      }

      return Future.value(true);
    } catch (e) {
      print("Error during background SMS sync: $e");
      return Future.value(false); // Indicate failure
    } finally {
      container.dispose(); // Clean up the container
    }
  });
}

const smsSyncTask = "smsSyncTask";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize and schedule the background task
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    smsSyncTask,
    "smsSync",
    frequency: const Duration(hours: 3),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Centhios',
      theme: AppTheme.theme,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardPage(),
    TransactionsPage(),
    BudgetsPage(),
    GoalsPage(),
    InvestmentsPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AuroraBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 0, left: 10, right: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: DotCurvedBottomNav(
                  indicatorColor: AppTheme.primary,
                  backgroundColor: Colors.black,
                  animationDuration: const Duration(milliseconds: 300),
                  animationCurve: Curves.ease,
                  selectedIndex: _selectedIndex,
                  indicatorSize: 5,
                  borderRadius: 30,
                  height: 65,
                  onTap: _onItemTapped,
                  items: [
                    Icon(
                      Icons.dashboard_rounded,
                      color:
                          _selectedIndex == 0 ? AppTheme.primary : Colors.grey,
                    ),
                    Icon(
                      Icons.swap_horiz,
                      color:
                          _selectedIndex == 1 ? AppTheme.primary : Colors.grey,
                    ),
                    Icon(
                      Icons.pie_chart_rounded,
                      color:
                          _selectedIndex == 2 ? AppTheme.primary : Colors.grey,
                    ),
                    Icon(
                      Icons.flag_rounded,
                      color:
                          _selectedIndex == 3 ? AppTheme.primary : Colors.grey,
                    ),
                    Icon(
                      Icons.show_chart,
                      color:
                          _selectedIndex == 4 ? AppTheme.primary : Colors.grey,
                    ),
                    Icon(
                      Icons.settings_rounded,
                      color:
                          _selectedIndex == 5 ? AppTheme.primary : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
