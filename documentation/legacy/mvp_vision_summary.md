# MVP Vision Summary - Cycle 3

**Agent:** L1A1: Product Vision Analyst  
**Timestamp:** 2025-07-01T13:10:00Z  
**Source Document:** `release_notes.md` (Cycle 2)

---

## 1. Objective

To define the Minimum Viable Product (MVP) scope for Cycle 3, building directly upon the proofs-of-concept and placeholder architecture established in Cycle 2. The goal is to transition from stubs to the first end-to-end, functional implementation of the "Goals" and "Budgets" features.

## 2. Core MVP Features

The MVP will focus on the following key functionalities:

### Feature 1: Financial Goal Management (End-to-End)

*   **Backend:**
    *   Implement the full CRUD (Create, Read, Update, Delete) logic in `GoalsService`.
    *   Define and enforce a non-trivial Firestore data model for a `goal` (e.g., `name`, `targetAmount`, `currentAmount`, `targetDate`).
*   **Mobile:**
    *   Transform the `GoalsPage` placeholder into a functional screen.
    *   Display a list of goals fetched from the backend.
    *   Implement a form (e.g., in a modal or separate page) to create a new goal.
    *   Allow users to tap on a goal to see a detail view (read-only for MVP).
    *   Implement a mechanism to add funds to a goal, updating `currentAmount`.

### Feature 2: Budget Viewing

*   **Backend:**
    *   Implement the `create` and `find` logic in `BudgetsService`.
    *   Define a simple Firestore data model for a `budget` (e.g., `name`, `category`, `limitAmount`).
*   **Mobile:**
    *   Transform the `BudgetsPage` placeholder into a functional screen.
    *   Display a list of budgets fetched from the backend.
    *   Creation and updating of budgets will be deferred post-MVP.

### Feature 3: AI Service Enhancement

*   **AI Core:**
    *   The AI agent needs to be made aware of the new capabilities.
    *   Define and implement tools/functions for the AI to interact with the `GoalsService`, specifically:
        *   `create_financial_goal(name, targetAmount, targetDate)`
        *   `get_financial_goals()`
        *   `add_to_goal(goalId, amount)`

## 3. Out of Scope for this MVP Cycle

To maintain focus, the following will be excluded:

*   Detailed budget management (updates, deletion, transaction linking).
*   Advanced UI/UX on the mobile app (e.g., animations, complex state management).
*   The "Spatial Finance" 3D interface will remain a PoC and will not be integrated with live data in this cycle.
*   Push notifications or alerts for goals/budgets.

This summary will guide the subsequent agents in the planning, design, and implementation phases of Cycle 3. 