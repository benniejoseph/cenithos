# Mobile Design: Cycle 8

## Objective

To provide a precise technical design for resolving the mobile testing blocker, as outlined in the Cycle 8 Development Plan.

## Phase 1: Animation Removal

The immediate design change is to remove the conflicting animation from `TransactionListItem`.

-   **File:** `mobile/centhios/lib/presentation/widgets/transaction_list_item.dart`
-   **Target:** The `ShadCard` widget within the `build` method.
-   **Change:** Remove the `.animate().fadeIn(delay: 200.ms)` extension method call from the widget.

### **Before:**
```dart
@override
Widget build(BuildContext context) {
  // ... other code
  return ShadCard(
    // ... card properties
  ).animate().fadeIn(delay: 200.ms);
}
```

### **After:**
```dart
@override
Widget build(BuildContext context) {
  // ... other code
  return ShadCard(
    // ... card properties
  );
}
```

This change is surgical and directly addresses the root cause identified in the gap analysis.

## Phase 2: Test-Friendly Animation (Contingency)

If the UI impact of removing the animation is too severe, we will implement a simple, testable fade-in transition.

-   **New Widget:** `FadeInWrapper`
    -   This will be a `StatefulWidget` that internally manages an `AnimationController`.
    -   It will wrap its child in a `FadeTransition`.
    -   The controller will be configured with a short duration and will be started in `initState`.

-   **Implementation:**
    ```dart
    // In transaction_list_item.dart
    return FadeInWrapper(
      child: ShadCard(
        // ... card properties
      ),
    );
    ```

This design ensures that any new animation is built using the standard Flutter animation framework, which is fully controllable and inspectable by the `flutter_test` environment, preventing a recurrence of the problem. 