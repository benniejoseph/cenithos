# Development Plan: Cycle 6

**Cycle Goal:** Stabilize Mobile Test Environment & Enhance AI for Conversational Context.

## 1. Introduction

This document outlines the development tasks required to achieve the goals of Cycle 6. The plan is divided into two main workstreams, one for the Mobile Engineer (L3A2) and one for the AI Engineer (L3A1), based on the findings from the `gap_analysis_report_cycle6.md`.

## 2. Workstream 1: Mobile Test Environment Stabilization

**Assigned Agent:** L3A2 Mobile Engineer

The primary goal of this workstream is to create a stable, reliable, and comprehensive testing suite for the mobile application.

-   **Task 1: Create a Test Harness `TestApp` Widget**
    -   **Description:** Create a reusable "test app" widget that correctly wraps test subjects with all necessary providers and themes, including `ProviderScope`, `ShadApp`, and `MaterialApp`. This will solve the `ShadTheme` context issue.
    -   **File:** `mobile/centhios/test/test_helpers.dart`

-   **Task 2: Fix `TransactionsPage` Tests**
    -   **Description:** Re-create the widget tests for the `TransactionsPage` using the new `TestApp` harness. Focus on correctly handling the asynchronous loading of transactions and verifying the initial state, data-loaded state, and empty state.
    -   **File:** `mobile/centhios/test/widget/transactions_page_test.dart`

-   **Task 3: Implement Transaction Filtering Test**
    -   **Description:** Add a stable test for the transaction filtering functionality. This test must successfully open the filter sheet, interact with the filter chips, and verify that the transaction list updates correctly.
    -   **File:** `mobile/centhios/test/widget/transactions_page_test.dart`

-   **Task 4: Add Test Coverage for All Pages**
    -   **Description:** Create basic "smoke" tests (which verify that the page renders without crashing) for all remaining pages in the application to establish baseline coverage.
    -   **Files:**
        -   `mobile/centhios/test/widget/home_page_test.dart`
        -   `mobile/centhios/test/widget/accounts_page_test.dart`
        -   `mobile/centhios/test/widget/analytics_page_test.dart`
        -   `mobile/centhios/test/widget/profile_page_test.dart`

## 3. Workstream 2: AI Conversational Context Enhancement

**Assigned Agent:** L3A1 AI Engineer

The primary goal of this workstream is to evolve the AI from a stateless command executor into a context-aware conversational assistant.

-   **Task 1: Enhance `ContextManager`**
    -   **Description:** Modify the `ContextManager` to store a transcript of the conversation (a list of user/assistant messages) instead of just the last interaction. Add a configurable limit to the conversation history (e.g., last 10 turns).
    -   **File:** `ai/core/context_manager.py`

-   **Task 2: Update `AgentOrchestrator` to be Stateful**
    -   **Description:** Refactor the `AgentOrchestrator.route_query` method. It should now fetch the conversation history from the `ContextManager` at the beginning of each call. The "mock LLM" logic will be updated to consider this history.
    -   **File:** `ai/core/orchestrator.py`

-   **Task 3: Implement Contextual Query Logic**
    -   **Description:** Add logic to the orchestrator to handle simple contextual follow-up queries. For example, if the previous turn was "show my transactions," a follow-up of "filter for food" should work. This will involve storing the results of the last tool call in the context.
    -   **File:** `ai/core/orchestrator.py`

-   **Task 4: Add New Integration Tests for Context**
    -   **Description:** Create new integration tests that specifically verify the AI's ability to handle multi-turn conversations. The tests should simulate a sequence of queries and assert that the AI responds correctly based on the conversation history.
    -   **File:** `ai/tests/test_integration.py`

## 4. Milestones

1.  **Milestone 1 (Mobile):** All tests for `TransactionsPage` are passing reliably.
2.  **Milestone 2 (AI):** The AI can successfully handle a two-turn contextual query.
3.  **Milestone 3 (Mobile):** Baseline test coverage for all pages is complete and all mobile tests pass.
4.  **Milestone 4 (Final):** All development tasks are complete, and the system is ready for Layer 4 verification. 