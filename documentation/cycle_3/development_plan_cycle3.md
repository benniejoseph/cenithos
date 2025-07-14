# Development Plan - Cycle 3 (MVP)

**Agent:** L1A3: Development Task Planner  
**Timestamp:** 2025-07-01T13:20:00Z  
**Source Document:** `gap_analysis_report_cycle3.md`

---

## 1. Objective

To provide a detailed, task-level plan for implementing the MVP features. This plan will be used by the Layer 2 (Design) and Layer 3 (Implementation) agents.

## 2. Task Breakdown

### **Backend Development (for L3A1)**

*   **Firebase Configuration:**
    *   [ ] Expose the new services via the main Express app in `backend/functions/src/index.ts`, creating endpoints for `/goals` (GET, POST, PUT, DELETE) and `/budgets` (GET, POST).
*   **Goals Service:**
    *   [ ] **Task B1:** Implement full CRUD functionality in `backend/functions/src/services/goals.ts`.
        *   `create`: Add a new document to the `goals` collection.
        *   `find`: Retrieve all goals for a given `userId`.
        *   `update`: Modify an existing goal document.
        *   `delete`: Remove a goal document.
*   **Budgets Service:**
    *   [ ] **Task B2:** Implement `create` and `find` functionality in `backend/functions/src/services/budgets.ts`.

### **Mobile Development (for L3A2)**

*   **Data Layer:**
    *   [ ] **Task M1:** Create `mobile/lib/data/models/goal_model.dart`.
    *   [ ] **Task M2:** Create `mobile/lib/data/models/budget_model.dart`.
    *   [ ] **Task M3:** Create `mobile/lib/data/repositories/goals_repository.dart` to handle HTTP requests to the backend's `/goals` endpoints.
    *   [ ] **Task M4:** Create `mobile/lib/data/repositories/budgets_repository.dart` for the `/budgets` endpoints.
*   **Goals UI:**
    *   [ ] **Task M5:** Convert `mobile/lib/presentation/pages/goals_page.dart` to a `StatefulWidget`.
    *   [ ] **Task M6:** In `goals_page.dart`, use the `GoalsRepository` to fetch and display a list of goals.
    *   [ ] **Task M7:** Create a new widget (`create_goal_dialog.dart`) for the goal creation form.
    *   [ ] **Task M8:** Wire up the Floating Action Button on `goals_page.dart` to show the `CreateGoalDialog`.
*   **Budgets UI:**
    *   [ ] **Task M9:** Convert `mobile/lib/presentation/pages/budgets_page.dart` to a `StatefulWidget`.
    *   [ ] **Task M10:** In `budgets_page.dart`, use the `BudgetsRepository` to fetch and display a list of budgets.

### **AI Development (for L3A3)**

*   **Tooling:**
    *   [ ] **Task A1:** Create a new file: `ai/core/tools/financial_tools.py`.
    *   [ ] **Task A2:** In `financial_tools.py`, implement the following functions that call the backend API:
        *   `create_financial_goal(name, targetAmount, targetDate)`
        *   `get_financial_goals()`
        *   `add_to_goal(goalId, amount)`
*   **Orchestrator:**
    *   [ ] **Task A3:** Refactor `ai/core/orchestrator.py` to support tool registration and execution.
        *   The orchestrator should be able to register the new financial tools.
        *   When a query is routed to the `financial_assistant` agent, it should determine if a tool needs to be called and execute it.

## 3. Dependencies

*   Mobile development (L3A2) is dependent on the backend API endpoints being implemented and exposed by L3A1 first.
*   AI tool development (L3A3) is also dependent on the backend API endpoints from L3A1. 