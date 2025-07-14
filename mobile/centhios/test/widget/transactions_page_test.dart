import 'dart:async';

import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/data/repositories/transactions_repository.dart';
import 'package:centhios/presentation/pages/transactions_page.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../test_helpers.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class FakeTransactionFilters extends Fake implements TransactionFilters {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransactionFilters());
  });

  group('TransactionsPage', () {
    late MockTransactionsRepository mockTransactionsRepository;

    setUp(() {
      mockTransactionsRepository = MockTransactionsRepository();
    });

    testWidgets('shows loading indicator', (tester) async {
      fakeAsync((async) {
        final completer = Completer<List<Transaction>>();
        when(() => mockTransactionsRepository.getTransactions(any()))
            .thenAnswer((_) => completer.future);

        pumpPage(
          tester,
          const TransactionsPage(),
          overrides: [
            transactionsRepositoryProvider
                .overrideWithValue(mockTransactionsRepository),
          ],
        );

        // No pump needed, should be in loading state immediately
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete([]); // Complete the future
        async.flushTimers(); // Clear any pending timers
      });
    });

    testWidgets('shows empty message when there are no transactions',
        (tester) async {
      fakeAsync((async) {
        when(() => mockTransactionsRepository.getTransactions(any()))
            .thenAnswer((_) async => []);

        pumpPage(
          tester,
          const TransactionsPage(),
          overrides: [
            transactionsRepositoryProvider
                .overrideWithValue(mockTransactionsRepository),
          ],
        );

        async.flushMicrotasks(); // Process the future
        tester.pump(); // Rebuild with the new state

        expect(find.text('No transactions found'), findsOneWidget);
        async.flushTimers();
      });
    });

    testWidgets('displays a list of transactions when data is loaded',
        (tester) async {
      fakeAsync((async) {
        final transactions = [
          Transaction(
              id: '1',
              description: 'Groceries',
              amount: 50.0,
              date: DateTime.now(),
              type: 'expense',
              category: 'Food'),
          Transaction(
              id: '2',
              description: 'Salary',
              amount: 2000.0,
              date: DateTime.now(),
              type: 'income',
              category: 'Income'),
        ];
        when(() => mockTransactionsRepository.getTransactions(any()))
            .thenAnswer((_) async => transactions);

        pumpPage(
          tester,
          const TransactionsPage(),
          overrides: [
            transactionsRepositoryProvider
                .overrideWithValue(mockTransactionsRepository),
          ],
        );

        async.flushMicrotasks();
        tester.pump();

        expect(find.text('Groceries'), findsOneWidget);
        expect(find.text('Salary'), findsOneWidget);
        async.flushTimers();
      });
    });

    testWidgets('filters transactions when filter is applied', (tester) async {
      fakeAsync((async) {
        final allTransactions = [
          Transaction(
              id: '1',
              description: 'Groceries',
              amount: 50.0,
              date: DateTime.now(),
              type: 'expense',
              category: 'Food'),
          Transaction(
              id: '2',
              description: 'Salary',
              amount: 2000.0,
              date: DateTime.now(),
              type: 'income',
              category: 'Income'),
        ];
        final filteredTransactions = [allTransactions[0]];

        when(() => mockTransactionsRepository.getTransactions(any()))
            .thenAnswer((invocation) {
          final filters =
              invocation.positionalArguments.first as TransactionFilters?;
          if (filters != null && filters.category == 'Food') {
            return Future.value(filteredTransactions);
          }
          return Future.value(allTransactions);
        });

        pumpPage(
          tester,
          const TransactionsPage(),
          overrides: [
            transactionsRepositoryProvider
                .overrideWithValue(mockTransactionsRepository),
          ],
        );

        async.flushMicrotasks();
        tester.pump();

        // Tap the filter button
        tester.tap(find.byIcon(Icons.filter_list));
        tester
            .pumpAndSettle(); // pumpAndSettle is okay here as it's outside the direct future handling

        // Verify the filter sheet is shown
        expect(find.text('Filter Transactions'), findsOneWidget);

        // Select a category
        tester.tap(find.text('Food'));
        tester.pumpAndSettle();

        // Tap the apply button
        tester.tap(find.text('Apply'));
        tester.pumpAndSettle();

        async.flushMicrotasks();
        tester.pump();

        // Verify that the list is filtered
        expect(find.text('Groceries'), findsOneWidget);
        expect(find.text('Salary'), findsNothing);
        async.flushTimers();
      });
    });
  });
}
