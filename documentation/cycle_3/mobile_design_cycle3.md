# Mobile UI/UX MVP Design - Cycle 3

**Agent:** L2A2: Mobile UI/UX Architect  
**Timestamp:** 2025-07-01T13:25:00Z  
**Source Document:** `development_plan_cycle3.md`

---

## 1. Objective

To define the UI components, data models, and repository structure needed to implement the MVP features in the Flutter mobile application.

## 2. Data Models (in `mobile/lib/data/models/`)

### `goal_model.dart`

```dart
class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      name: json['name'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetDate: (json['targetDate'] as Timestamp).toDate(), // Assuming Firestore Timestamp
    );
  }
}
```

### `budget_model.dart`

```dart
class Budget {
  final String id;
  final String name;
  final String category;
  final double limitAmount;

  Budget({
    required this.id,
    required this.name,
    required this.category,
    required this.limitAmount,
  });

   factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      limitAmount: (json['limitAmount'] as num).toDouble(),
    );
  }
}
```

## 3. Repositories (in `mobile/lib/data/repositories/`)

### `goals_repository.dart`

*   **Class:** `GoalsRepository`
*   **Methods:**
    *   `Future<List<Goal>> getGoals()`: Fetches all goals for the user.
    *   `Future<Goal> createGoal(String name, double targetAmount, DateTime targetDate)`: Creates a new goal.
    *   `Future<void> addToGoal(String goalId, double amount)`: Updates a goal's `currentAmount`.

### `budgets_repository.dart`

*   **Class:** `BudgetsRepository`
*   **Methods:**
    *   `Future<List<Budget>> getBudgets()`: Fetches all budgets for the user.

## 4. UI Components and Pages

### `goals_page.dart`

*   **State:** Stateful (`StatefulWidget`).
*   **Logic:**
    *   On `initState`, call `GoalsRepository.getGoals()`.
    *   Maintain a `_isLoading` flag and a `List<Goal> _goals`.
*   **UI:**
    *   Display a `CircularProgressIndicator` if `_isLoading` is true.
    *   Display a `ListView.builder` to render `GoalListItem` widgets.
    *   The `FloatingActionButton` will open the `CreateGoalDialog`.

### `budgets_page.dart`

*   **State:** Stateful (`StatefulWidget`).
*   **Logic:** Similar to `GoalsPage`, but for budgets.
*   **UI:** Similar to `GoalsPage`, rendering `BudgetListItem` widgets.

### New Widgets (in `mobile/lib/presentation/widgets/`)

*   **`goal_list_item.dart`**: A widget to display a single goal's name, progress bar (`currentAmount` / `targetAmount`), and target date.
*   **`budget_list_item.dart`**: A widget to display a single budget's name, category, and limit.
*   **`create_goal_dialog.dart`**: A dialog containing a `Form` with `TextFormField` widgets for goal name, target amount, and a `DatePicker` for the target date. It will have a "Save" button to call `GoalsRepository.createGoal()`. 