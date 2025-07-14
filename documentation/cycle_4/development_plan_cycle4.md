# Development Plan - Cycle 4

**Date:** 2025-07-01
**Author:** L1A3 (Development Task Planner)
**Based on:** `gap_analysis_report_cycle4.md`

---

## 1. Overview

This document provides a detailed, step-by-step plan for executing the development work in Cycle 4. The tasks are assigned to the responsible Layer 3 agents (Mobile, Backend, AI).

**Primary Goal:** Stabilize Mobile Testing.
**Secondary Goal:** Implement Transaction Management MVP.

---

## 2. Task Breakdown

### **Phase 1: Mobile Test Environment Stabilization (High Priority)**

This phase must be completed before starting Phase 2.

**Assigned to:** `L3A2: Mobile Agent`

- **Task M1: Research Firebase Mocking Solution.**
  - **Description:** The previous attempt to mock Firebase failed. Investigate the latest, community-accepted methods for mocking Firebase in Flutter tests for 2025. This may involve using packages like `firebase_auth_mocks`, `fake_cloud_firestore`, or a more robust manual platform channel mock.
  - **Deliverable:** A decision on the mocking strategy.

- **Task M2: Implement the Firebase Mock.**
  - **Description:** Implement the chosen mocking solution within `mobile/centhios/test/test_helpers.dart`. The helper must successfully initialize a fake Firebase app in the test environment.
  - **Deliverable:** Modified `test_helpers.dart`.

- **Task M3: Re-create Initial Test Suite.**
  - **Description:** Create a basic test suite to validate the mock implementation.
  - **Deliverables:**
    - `mobile/centhios/test/widget_test.dart`: A simple test that pumps the `App` widget and verifies it doesn't crash.
    - `mobile/centhios/test/widget/auth_flow_test.dart`: A new test to verify the initial navigation to the login page.

- **Task M4: Create Goals Page Test.**
  - **Description:** Re-create a widget test for the `GoalsPage` that uses the new mocking infrastructure to mock the `GoalsRepository` and test the UI in various states (loading, success, error).
  - **Deliverable:** `mobile/centhios/test/widget/goals_page_test.dart`.

### **Phase 2: Transaction Management MVP Implementation**

**Assigned to:** `L3A1: Backend Agent`

- **Task B1: Create Transaction Model & Service.**
  - **Description:** Create the data model and service for transactions. The service should handle `create` and `list` operations.
  - **Deliverables:**
    - `backend/functions/src/models/transaction.ts`
    - `backend/functions/src/services/transactions.ts`

- **Task B2: Expose Transaction API Endpoint.**
  - **Description:** Add the new `/transactions` route to the Express app and connect it to the `TransactionsService`.
  - **Deliverable:** Modified `backend/functions/src/index.ts`.

- **Task B3: Update Firestore Rules.**
  - **Description:** Add security rules for the new `transactions` collection, ensuring users can only access their own data.
  - **Deliverable:** Modified `backend/firestore.rules`.

**Assigned to:** `L3A2: Mobile Agent`

- **Task M5: Create Transaction Model & Repository.**
  - **Description:** Create the Dart model for transactions and a repository to communicate with the new backend endpoint.
  - **Deliverables:**
    - `mobile/centhios/lib/data/models/transaction_model.dart`
    - `mobile/centhios/lib/data/repositories/transactions_repository.dart`

- **Task M6: Build Transactions UI.**
  - **Description:** Build the UI for listing transactions and adding a new transaction.
  - **Deliverables:**
    - `mobile/centhios/lib/presentation/pages/transactions_page.dart`
    - `mobile/centhios/lib/presentation/widgets/add_transaction_dialog.dart`
    - `mobile/centhios/lib/presentation/widgets/transaction_list_item.dart`

- **Task M7: Integrate into Main App Shell.**
  - **Description:** Add a "Transactions" item to the main navigation shell to make the new page accessible.
  - **Deliverable:** Modified `mobile/centhios/lib/presentation/pages/main_shell.dart`.

**Assigned to:** `L3A3: AI Agent`

- **Task A1: Create `get_transactions` Tool.**
  - **Description:** Add a new tool to `financial_tools.py` that calls the backend's `/transactions` endpoint.
  - **Deliverable:** Modified `ai/core/tools/financial_tools.py`.

- **Task A2: Update Orchestrator.**
  - **Description:** Add logic to the `AgentOrchestrator` to recognize user intent related to viewing transactions and route the request to the new tool.
  - **Deliverable:** Modified `ai/core/orchestrator.py`.

---

## 3. Plan Approval

This plan is now submitted for review. Once approved, the Layer 2 agents will create detailed technical designs based on these tasks. 