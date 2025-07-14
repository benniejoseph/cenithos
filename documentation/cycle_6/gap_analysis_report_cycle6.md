# Gap Analysis Report: Cycle 6

**Cycle Goal:** Stabilize Mobile Test Environment & Enhance AI for Conversational Context.

## 1. Introduction

This report analyzes the gap between the current state of our mobile testing and AI interaction and the vision outlined in the `product_vision_summary_cycle6.md`. The goal is to identify the specific shortcomings that must be addressed to achieve our Cycle 6 objectives of **Reliability and Intelligence**.

## 2. Mobile Testing Environment

### Current State
-   **Test Existence:** Widget tests exist for some older features, but the most recent and critical tests for transaction management are failing and have been removed.
-   **Test Reliability:** The existing tests are brittle. They fail inconsistently, particularly when dealing with asynchronous operations (like fetching data) and UI components from the `shadcn_ui` library, which requires a `ShadTheme`.
-   **Root Cause:** The root cause of the failures appears to be a combination of improper test setup for themed widgets and incorrect handling of the widget lifecycle during asynchronous state changes in the test environment.
-   **Coverage:** Automated test coverage for the main application features is effectively near zero due to the unreliability of the test suite.

### Desired State
-   **Reliable Suite:** A fully stable test suite where all tests pass consistently.
-   **Comprehensive Coverage:** All pages and critical user flows are covered by widget and integration tests.
-   **CI/CD Integration:** Tests are run automatically on every pull request, providing a reliable quality gate.
-   **Best Practices:** The test suite follows established best practices for testing Flutter applications, including the proper setup for providers, themes, and asynchronous logic.

### Identified Gaps
1.  **Theme/Context Propagation:** There is a fundamental gap in how the `ShadTheme` is provided to widgets under test. Our current test setup does not correctly mimic the application's widget tree.
2.  **Asynchronous UI Testing:** There is a knowledge and implementation gap in how to correctly test widgets that rely on `FutureProvider` or `StreamProvider` and undergo several build phases (e.g., loading, data, error). The use of `pumpAndSettle` has been insufficient.
3.  **Test Structure:** The previous tests were monolithic. A gap exists in structuring tests to be more granular and isolated, making them easier to debug.

## 3. AI Conversational Context

### Current State
-   **Stateless Operation:** The `AgentOrchestrator` is entirely stateless. Each query is treated as a completely new interaction, with no memory of previous turns.
-   **Keyword-Based Routing:** The orchestrator uses simple, hardcoded keyword matching to route queries to tools. This is brittle and does not allow for follow-up questions.
-   **No Clarification:** The AI cannot ask clarifying questions. If a query is ambiguous, it either fails or provides a generic fallback response.
-   **Tool Use:** Tools are called with arguments parsed directly from the single, current query. The AI cannot use information from a previous tool call to inform the next one.

### Desired State
-   **Stateful Conversation:** The AI maintains a history of the current conversation, including user messages and AI responses.
-   **Contextual Understanding:** The AI can use conversational history to understand pronouns and ambiguous references (e.g., "filter *those* transactions").
-   **Proactive Clarification:** The AI can identify when a query is ambiguous and ask the user for more information before proceeding.
-   **Chained Tool Use:** The AI can perform a sequence of operations based on a conversation. For example, it can fetch transactions and then, in a subsequent turn, apply a filter to the results it is holding in memory.

### Identified Gaps
1.  **Context Persistence:** There is no mechanism for storing or retrieving conversation history within the `AgentOrchestrator`. The `ContextManager` only stores the last query/response pair, not a full history.
2.  **State Management Logic:** The core routing logic in `route_query` is not designed to look at or incorporate past context. A significant logic gap exists in how the "LLM" makes decisions.
3.  **LLM Simulation:** The current keyword-based simulation is too simple to support contextual conversations. The gap is the lack of a simulated "state" or "memory" that an actual LLM would possess.

## 4. Conclusion

The analysis reveals foundational gaps in both the mobile testing framework and the AI's core logic. To achieve the goals of Cycle 6, work must focus on bridging these gaps by establishing proper test architecture and implementing a stateful, context-aware conversational engine for the AI. 