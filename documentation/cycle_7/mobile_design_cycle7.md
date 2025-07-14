# Mobile Technical Design: Cycle 7

**Cycle Goal:** Resolve Mobile Testing Blockers & Introduce Real-Time AI Feedback.

## 1. Introduction

This document provides the specific technical design to resolve the critical mobile testing blockers. The root cause is a conflict between the timers used by the `flutter_animate` package and the `flutter_test` framework's event queue. The solution is to gain explicit control over the passage of time within our tests.

## 2. The Solution: `FakeAsync` and Explicit Time Control

We will use the `FakeAsync` class from the `fake_async` package (which is already a dependency of `flutter_test`) to wrap our test bodies. This class allows us to simulate the passage of time and control timers programmatically.

The core of the strategy is as follows:

1.  Wrap the entire body of a test widget that involves animations in `FakeAsync().run(...)`.
2.  After pumping the widget, use `fakeAsync.elapse(duration)` to advance the clock. This will trigger the timers used by `flutter_animate`.
3.  After advancing the clock, `pump` the widget tree again to render the results of the animation frame.

### 2.1. Example Implementation for the Loading Indicator Test

This pattern will be applied to the `transactions_page_test.dart`.

**File:** `mobile/centhios/test/widget/transactions_page_test.dart`

```dart
testWidgets('shows loading indicator and disposes timers correctly', (tester) async {
  await FakeAsync().run((fakeAsync) async {
    // Arrange: Mock the repository to return a future that never completes
    final completer = Completer<List<Transaction>>();
    when(() => mockTransactionsRepository.getTransactions(any()))
        .thenAnswer((_) => completer.future);

    // Act: Pump the page
    await pumpPage(
      tester,
      const TransactionsPage(),
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(mockTransactionsRepository),
      ],
    );

    // Assert: The loading indicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Elapse time to allow any pending animation timers to fire
    fakeAsync.elapse(const Duration(seconds: 5)); 
    // Pump the final frame to settle the UI
    await tester.pumpAndSettle(); 
  });
  // By exiting the FakeAsync block, it will verify that no timers are pending.
  // If a timer were still active, this test would fail here.
});
```

## 3. Design for AI Service and UI

### 3.1. `AIService`

A new service will be created to handle the streaming connection. It will use `http.Client` to make a request and expose a `Stream<String>` of the response body chunks.

**File:** `mobile/centhios/lib/core/services/ai_service.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  final Ref _ref;
  final String _baseUrl = '...'; // Your API base URL

  AIService(this._ref);

  Stream<String> getAIResponse(String query) async* {
    final client = http.Client();
    final request = http.Request('POST', Uri.parse('$_baseUrl/query'));
    request.headers['Content-Type'] = 'application/json';
    request.body = json.encode({'user_id': 'some-user', 'query': query});

    try {
      final response = await client.send(request);
      
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        yield chunk;
      }
    } finally {
      client.close();
    }
  }
}

final aiServiceProvider = Provider((ref) => AIService(ref));
```

### 3.2. `AIAssistantPage` UI Logic

The page will be converted to a `ConsumerStatefulWidget`.

-   **State:** The widget's state will include a list of messages and a boolean `_isTyping`.
-   **onSubmitted:** When the user submits a query, `_isTyping` is set to `true`. It then calls the `AIService` and listens to the returned stream.
-   **Stream Handling:** As new data chunks arrive, they are appended to the last message in the message list. When the stream is `done`, `_isTyping` is set to `false`.

This design provides a clear and robust solution for both the testing and AI streaming features. 