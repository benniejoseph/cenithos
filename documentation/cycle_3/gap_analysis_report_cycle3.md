# Gap Analysis Report - Cycle 3 (MVP)

**Agent:** L1A2: Gap Analysis Agent  
**Timestamp:** 2025-07-01T13:15:00Z  
**Source Document:** `mvp_vision_summary.md`  
**Codebase State:** Post-Cycle 2 (Placeholders & PoC)

---

## 1. Objective

To identify the specific gaps between the current placeholder implementation and the required functionality for the MVP, as defined in the vision summary. This report details the necessary additions and modifications.

## 2. Identified Gaps by Feature

### Feature 1: Financial Goal Management

*   **`backend/functions/src/services/goals.ts`**
    *   **Gap:** The current `GoalsService` contains placeholder methods (`create`, `find`, `update`). It lacks full CRUD logic and does not implement `delete`.
    *   **Required:** Implement the actual Firestore queries for all CRUD operations. Add a `delete` method.
*   **`mobile/centhios/lib/presentation/pages/goals_page.dart`**
    *   **Gap:** The page is a static placeholder with a non-functional Floating Action Button.
    *   **Required:**
        *   Convert to a `StatefulWidget` to manage state (e.g., loading, list of goals).
        *   Implement logic to call a `GoalsRepository` (which needs to be created) to fetch goals from the backend.
        *   Display goals in a `ListView`.
        *   Create a new widget for a "Create Goal" form/dialog.
        *   Implement navigation to a goal detail view.
*   **Data Layer (New)**
    *   **Gap:** No repository or data model layer exists in the mobile app to handle communication with the backend.
    *   **Required:** Create `Goal` model class in Dart. Create a `GoalsRepository` to abstract the API calls.

### Feature 2: Budget Viewing

*   **`backend/functions/src/services/budgets.ts`**
    *   **Gap:** The `BudgetsService` only has `create` and `find` stubs.
    *   **Required:** Implement the logic for the `create` and `find` methods to interact with Firestore.
*   **`mobile/centhios/lib/presentation/pages/budgets_page.dart`**
    *   **Gap:** The page is a static placeholder.
    *   **Required:**
        *   Convert to a `StatefulWidget`.
        *   Implement logic to call a `BudgetsRepository` (to be created) to fetch budgets.
        *   Display budgets in a `ListView`.
*   **Data Layer (New)**
    *   **Gap:** No repository or data model for budgets exists in the mobile app.
    *   **Required:** Create `Budget` model class in Dart. Create a `BudgetsRepository`.

### Feature 3: AI Service Enhancement

*   **`ai/core/orchestrator.py`**
    *   **Gap:** The orchestrator uses simple keyword matching and has no concept of "tools" or external functions.
    *   **Required:** Refactor the `route_query` method to support a tool-use paradigm, where the selected agent can call registered functions.
*   **`ai/core/tools` (Directory)**
    *   **Gap:** No tools for interacting with the backend services exist.
    *   **Required:**
        *   Create a new file, `financial_tools.py`.
        *   Implement functions (`create_financial_goal`, `get_financial_goals`, `add_to_goal`) that make HTTP requests to the (yet to be exposed) backend API endpoints.

## 3. Summary of Required Work

The analysis shows that significant work is needed to build out the application logic in both the backend and mobile apps. The core task is to replace all placeholder stubs with functional code that performs real operations and to create a data access layer in the mobile app. The AI service requires a conceptual shift to support tool-based function calls. 