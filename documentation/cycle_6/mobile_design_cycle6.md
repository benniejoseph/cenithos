# Mobile Technical Design: Cycle 6

**Cycle Goal:** Stabilize Mobile Test Environment & Enhance AI for Conversational Context.

## 1. Introduction

This document provides the technical design for stabilizing the mobile testing environment. The primary challenge identified in Cycle 5 was the inconsistent and failing state of our widget tests, particularly those involving `FutureProvider` and `ShadTheme`. This design will establish a robust and reusable testing pattern to resolve these issues.

## 2. Core Problem: Test Environment Setup

The root cause of our testing failures is an improperly configured test environment that does not accurately replicate the real application's widget tree. Specifically:

1.  **Missing `ShadTheme`:** Widgets that use `ShadTheme.of(context)` fail because the `ShadApp` (which provides the theme) is not present in the test's widget tree.
2.  **Provider State Management:** Asynchronous providers (like `FutureProvider`) go through loading/data/error states. Our tests have struggled to correctly manage pumping the widget tree to account for these state transitions.

## 3. Proposed Solution: A Reusable Test Harness

To solve these problems, we will create a universal test harness widget, `TestApp`, that will be used in all widget tests.

### 3.1 `TestApp` Widget Definition

This widget will be responsible for wrapping the widget-under-test with all the necessary top-level providers and app shells.

**File:** `mobile/centhios/test/test_helpers.dart`

```dart
import 'package:centhios/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
```

### 3.2 `pumpPage` Test Helper

We will also create a helper function `pumpPage` to reduce boilerplate in our test files. This function will take the `WidgetTester` and the widget to be tested and wrap it in our `TestApp`.

```dart
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
```

## 4. Test Implementation Strategy

With the harness in place, we will implement our tests following a clear, consistent pattern.

### 4.1 Testing Asynchronous Providers

The key to testing widgets that use `FutureProvider` is to control the provider's state and pump the tree at each stage.

**Example for `TransactionsPage`:**

1.  **Initial State (Loading):**
    -   Override `transactionsRepositoryProvider` with a mock.
    -   Configure the mock's `getTransactions` to return a `Future` that never completes.
    -   Call `pumpPage`.
    -   Expect to find a `CircularProgressIndicator`.

2.  **Data State:**
    -   Configure the mock's `getTransactions` to return `Future.value([...])`.
    -   Call `pumpPage`.
    -   Call `tester.pumpAndSettle()`.
    -   Expect to find the transaction list items.

3.  **Empty State:**
    -   Configure the mock's `getTransactions` to return `Future.value([])`.
    -   Call `pumpPage`.
    -   Call `tester.pumpAndSettle()`.
    -   Expect to find the "No transactions yet." text.

### 4.2 Test File Structure

-   `mobile/centhios/test/test_helpers.dart`: Will contain `TestApp` and `pumpPage`.
-   `mobile/centhios/test/widget/transactions_page_test.dart`: Will be re-implemented using the new harness to test all states and filtering.
-   `mobile/centhios/test/widget/*_page_test.dart`: New files will be created for other pages to provide basic smoke test coverage.

## 5. Conclusion

This technical design provides a clear path to resolving our mobile testing issues. By creating a reusable test harness and following a consistent pattern for handling asynchronous UI, we can build a stable and reliable test suite that will improve code quality and developer confidence. 