import 'package:centhios/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  final Widget child;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: ShadApp(
        theme: CenthiosTheme.darkTheme,
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    TestApp(
      overrides: overrides,
      child: child,
    ),
  );
}
