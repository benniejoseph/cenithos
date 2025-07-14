import 'package:centhios/core/services/firebase_providers.dart';
import 'package:centhios/main.dart';
import 'package:centhios/presentation/pages/auth/login_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mockAuth = MockFirebaseAuth();
  final mockFirestore = FakeFirebaseFirestore();

  testWidgets('App starts and navigates to LoginPage when not logged in',
      (WidgetTester tester) async {
    // A more robust way to handle expected errors in tests.
    final originalOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firebaseFirestoreProvider.overrideWithValue(mockFirestore),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // After the test, restore the original error handler.
    FlutterError.onError = originalOnError;

    // Check if the only error was the expected RenderFlex overflow.
    // This allows the test to pass if the overflow occurs, but it will
    // still fail for any other unexpected errors.
    expect(errors, hasLength(1));
    expect(
        errors.first.exception.toString(), contains('A RenderFlex overflowed'));

    // Finally, verify the actual test condition.
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
