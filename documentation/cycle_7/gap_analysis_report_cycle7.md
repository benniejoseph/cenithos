# Gap Analysis Report: Cycle 7

**Cycle Goal:** Resolve Mobile Testing Blockers & Introduce Real-Time AI Feedback.

## 1. Introduction

This report analyzes the gap between the current state of our mobile testing and AI interaction and the vision outlined in the `product_vision_summary_cycle7.md`.

## 2. Mobile Testing Environment

### Current State
-   **Root Cause:** The exact root cause of the `Timer` leak is unknown, but it is strongly correlated with the use of the `flutter_animate` package within a `flutter_test` environment. The default test binding (`AutomatedTestWidgetsFlutterBinding`) does not seem to correctly manage the lifecycle of the animations' tickers.
-   **Test Reliability:** Tests that involve asynchronous providers that trigger animated loading indicators are 100% unreliable. They either fail to find widgets that should be present after a state change or leave timers pending, causing the test runner to fail the test.
-   **Current Strategy:** The established test harness (`TestApp`) successfully solves the `ShadTheme` dependency issue, but it does not address the core asynchronous/animation problem.

### Desired State
-   **Deterministic Tests:** Tests are 100% deterministic and free of race conditions or timer leaks.
-   **Complete Coverage:** The `TransactionsPage`, our most complex page, has complete and stable test coverage for its loading, data, empty, and filtering states.
-   **Clear Patterns:** A clear, documented pattern exists for any developer on the team to write new, stable widget tests for features involving asynchronous operations and animations.

### Identified Gaps
1.  **Asynchronous Mismatch:** The primary gap is the fundamental mismatch between how `flutter_animate` manages its animation controllers and how the Flutter test framework's fake clock and event queue operate. The framework is not aware of the animations' pending frames when a test completes.
2.  **Lack of Control:** There is a control gap. The current test implementation does not give the test author explicit control over the animation lifecycle. We cannot easily "fast-forward" or "complete" the animations within the test body.
3.  **Alternative Knowledge:** There is a knowledge gap regarding alternative, more "test-friendly" approaches to UI animation in Flutter that may be better suited for our testing environment.

## 3. Real-Time AI Feedback

### Current State
-   **Request-Response Model:** The AI interaction is a standard, blocking HTTP request-response cycle. The mobile app sends a `/query` request and waits for the full JSON response before rendering anything.
-   **Static UI:** While the backend is processing the query (which can take several seconds), the mobile UI is completely static. There is no feedback to the user that anything is happening.
-   **API Structure:** The FastAPI backend is built with standard `def` functions that return a single `JSONResponse`. This structure does not support streaming.

### Desired State
-   **Streaming Model:** The interaction is a streaming connection. The mobile app receives a series of events from the backend as the AI processes the request.
-   **Dynamic UI:** The UI is dynamic and responsive. It immediately shows a "typing" indicator and then updates the response text as new chunks of data arrive from the backend.
-   **API Structure:** The backend API uses a generator function (`async def` with `yield`) and returns a `StreamingResponse` that can send multiple chunks of data over a single connection.

### Identified Gaps
1.  **Backend Architecture:** The primary gap is in the backend architecture. The `AgentOrchestrator` and the FastAPI endpoint are not designed for streaming. A significant refactoring is needed to convert them to a generator-based approach.
2.  **Mobile HTTP Client:** The mobile app's current HTTP client (`package:http`) is designed for simple request-response and does not have a straightforward way to handle streaming responses. A new approach or a different library will be needed.
3.  **UI State Management:** The state management on the AI chat page is designed to handle a single, final response. A logic gap exists in how to manage and render a response that is built up over time from multiple streamed events.

## 4. Conclusion

The analysis reveals two distinct but critical gaps. The mobile testing gap is a technical blocker that impedes quality assurance. The AI feedback gap is a user experience issue that makes the product feel less polished and intelligent. Closing these gaps will require a deep dive into Flutter's testing framework and a significant architectural change to the AI's communication protocol. 