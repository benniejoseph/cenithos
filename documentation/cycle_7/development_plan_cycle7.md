# Development Plan: Cycle 7

**Cycle Goal:** Resolve Mobile Testing Blockers & Introduce Real-Time AI Feedback.

## 1. Introduction

This document outlines the development tasks for Cycle 7. The work is divided into two main workstreams: one for the Mobile Engineer (L3A2) focusing on the critical testing issue, and one for the AI Engineer (L3A1) focusing on the new real-time feedback feature.

## 2. Workstream 1: Mobile Test Environment Stabilization (Critical Priority)

**Assigned Agent:** L3A2 Mobile Engineer

-   **Task 1: Research & Strategize**
    -   **Description:** Conduct focused research on testing Flutter widgets that use the `flutter_animate` package. Investigate `tester.runAsync()` and how `FakeAsync` can be used to manage timers. The goal is to find a reliable pattern to control the animation lifecycle and prevent timer leaks.
    -   **Deliverable:** A short summary of the findings and the chosen testing strategy.

-   **Task 2: Implement Stable Loading Test**
    -   **Description:** Based on the research, refactor the `shows loading indicator` test in `transactions_page_test.dart` to be 100% reliable. This will likely involve using `runAsync` and `pump` to manually advance fake timers.
    -   **File:** `mobile/centhios/test/widget/transactions_page_test.dart`

-   **Task 3: Re-implement Data & Empty State Tests**
    -   **Description:** Re-implement the tests for the data-loaded and empty states using the new stable patterns to ensure they also pass reliably.
    -   **File:** `mobile/centhios/test/widget/transactions_page_test.dart`

-   **Task 4: Implement Transaction Filtering Test**
    -   **Description:** Finally, implement the test for the transaction filtering functionality, ensuring it can robustly handle the opening of the bottom sheet and the subsequent UI updates.
    -   **File:** `mobile/centhios/test/widget/transactions_page_test.dart`

## 3. Workstream 2: Real-Time AI Feedback

**Assigned Agent:** L3A1 AI Engineer & L3A2 Mobile Engineer

This workstream involves coordinated changes between the backend and mobile app.

### AI Backend (L3A1)
-   **Task 5: Refactor Orchestrator for Streaming**
    -   **Description:** Convert the `AgentOrchestrator.route_query` method into an `async` generator function that `yield`s status updates and the final result as JSON-encoded strings.
    -   **File:** `ai/core/orchestrator.py`

-   **Task 6: Implement Streaming API Endpoint**
    -   **Description:** Change the `/query` endpoint in `main.py` to return a `StreamingResponse` that iterates over the data yielded by the refactored orchestrator.
    -   **File:** `ai/main.py`

### Mobile App (L3A2)
-   **Task 7: Create a Streaming HTTP Client**
    -   **Description:** Create a new service or repository that is responsible for making a request to the `/query` endpoint and managing the streaming connection to parse the incoming chunks of data.
    -   **File:** `mobile/centhios/lib/core/services/ai_service.dart`

-   **Task 8: Update AI Page UI for Real-Time Feedback**
    -   **Description:** Modify the `AIAssistantPage` to use the new streaming service. The page should display a "typing" indicator while the backend is processing and render the AI's response as the data streams in.
    -   **File:** `mobile/centhios/lib/presentation/pages/ai_assistant_page.dart`

## 4. Milestones

1.  **Milestone 1 (Mobile):** The loading test for `TransactionsPage` passes reliably.
2.  **Milestone 2 (AI):** The `/query` endpoint successfully streams JSON chunks.
3.  **Milestone 3 (Mobile):** All tests for `TransactionsPage` are passing reliably.
4.  **Milestone 4 (Integration):** The mobile app correctly displays a typing indicator and streams the AI's response.
5.  **Milestone 5 (Final):** All development tasks are complete and ready for Layer 4 verification. 