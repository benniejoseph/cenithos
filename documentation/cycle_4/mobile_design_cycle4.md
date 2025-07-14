# Mobile Technical Design - Cycle 4

**Date:** 2025-07-01
**Author:** L2A2 (Mobile Architect)
**Based on:** `development_plan_cycle4.md`

---

## 1. Phase 1: Test Environment Stabilization

### 1.1. Mocking Strategy

- **Decision:** We will use the `fake_cloud_firestore` package in combination with `firebase_auth_mocks`. This combination provides a high-fidelity, in-memory fake of the two most critical Firebase services, avoiding the brittleness of manual platform channel mocks.
- **Dependencies to add:**
  - `dev_dependencies:`
    - `fake_cloud_firestore: ^2.5.1`
    - `firebase_auth_mocks: ^0.13.0`
    - `build_runner: ^2.4.9`
    - `mockito: ^5.4.4`

### 1.2. Test Helper Implementation

**File:** `mobile/centhios/test/test_helpers.dart`

- This file will contain a `setupMockFirebase` function. This function will:
  1.  Call `TestWidgetsFlutterBinding.ensureInitialized()`.
  2.  Instantiate `MockFirebaseAuth` and `FakeFirebaseFirestore`.
  3.  Provide these instances to the application's service locator or dependency injection system for use in tests.

### 1.3. Test Suite Structure

1.  **`widget_test.dart`**: Basic smoke test to ensure the main `App` widget can be pumped without crashing.
2.  **`auth_flow_test.dart`**: A test to verify the app correctly navigates to `LoginPage` when the user is not authenticated via `MockFirebaseAuth`.
3.  **`goals_page_test.dart`**: A comprehensive widget test for the `GoalsPage`, using `mockito` to create a `MockGoalsRepository` that returns canned data. This decouples the UI test from the repository implementation.

---

## 2. Phase 2: Transaction Management UI

### 2.1. Data Model

**File:** `mobile/centhios/lib/data/models/transaction_model.dart`

```dart
class Transaction {
  final String id;
  final String description;
  final double amount;
  final String type; // 'income' or 'expense'
  final DateTime date;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Implementation
  }
}
```

### 2.2. Repository

**File:** `mobile/centhios/lib/data/repositories/transactions_repository.dart`

- `class TransactionsRepository` will have two methods:
  - `Future<List<Transaction>> getTransactions()`: Makes a GET request to the `/transactions` backend endpoint.
  - `Future<void> createTransaction(Map<String, dynamic> data)`: Makes a POST request to the `/transactions` endpoint.

### 2.3. State Management

- The `riverpod` package will be used for state management.
- A `FutureProvider` will be created to fetch the transactions via the `TransactionsRepository`.
- A `StateNotifierProvider` will be used to manage the state of the `AddTransaction` form.

### 2.4. UI Components

- **`transactions_page.dart`**: The main page that uses a `ConsumerWidget` to watch the `transactionsProvider` and display a `ListView` of `TransactionListItem` widgets or a loading/error state.
- **`transaction_list_item.dart`**: A stateless widget to display a single transaction's details.
- **`add_transaction_dialog.dart`**: A stateful widget (or `ConsumerStatefulWidget`) containing a form with fields for description, amount, type, and date. It will use the `transactionsRepository` to submit the new transaction.
- **`main_shell.dart`**: An icon and label for "Transactions" will be added to the bottom navigation bar. 