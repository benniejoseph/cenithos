# Development Plan: Cycle 8

## Objective

To execute a clear, actionable plan to resolve the mobile widget testing blocker.

## Strategy

The core strategy is to **remove the source of the conflict (`flutter_animate`)** from the widget tree under test. We will do this as a targeted removal and replacement, ensuring the UI does not significantly regress.

## Step-by-Step Plan

### **Phase 1: Removal and Verification**

1.  **Identify Conflicting Widget:** The primary conflict originates in `TransactionListItem`, which is used by `TransactionsPage`.
2.  **Remove Animation Code:**
    -   Locate the file: `mobile/centhios/lib/presentation/widgets/transaction_list_item.dart`.
    -   Remove the `.animate().fadeIn()` call from the root widget in the `build` method.
3.  **Run Tests:**
    -   Execute the `transactions_page_test.dart` suite: `flutter test test/widget/transactions_page_test.dart`.
    -   **Expected Outcome:** All tests in the suite should pass. This will verify that `flutter_animate` was the sole cause of the failures.

### **Phase 2: Animation Replacement (If Necessary)**

1.  **Assess UI Impact:** Once the animation is removed, manually run the app to observe the UI. The list items will now appear instantly, which may be visually jarring.
2.  **Select a Test-Friendly Alternative:**
    -   If a simple fade-in is sufficient, we can implement it using a standard `FadeTransition` controlled by a `StatefulWidget`'s `AnimationController`. This approach gives the test framework direct control over the animation lifecycle.
    -   We will create a new, simple, reusable `FadeInWrapper` widget for this purpose.
3.  **Implement Replacement:**
    -   Wrap the `TransactionListItem`'s content in the new `FadeInWrapper` widget.
4.  **Update and Run Tests:**
    -   Ensure the tests still pass with the new, controlled animation.

## Timeline

-   **Phase 1:** Should be completed swiftly to confirm the root cause.
-   **Phase 2:** Will be undertaken if the UI impact of removing the animation is deemed significant.

This phased approach ensures we confirm the problem's source before investing time in a replacement, minimizing risk and effort. 