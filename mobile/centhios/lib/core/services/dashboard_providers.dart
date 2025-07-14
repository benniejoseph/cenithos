import 'package:centhios/data/models/budget_model.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/data/repositories/budgets_repository.dart';
import 'package:centhios/data/repositories/transactions_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    hide Transaction; // Hide the conflicting class
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the future of user's transactions
final transactionsFutureProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return [];
  }
  // This will automatically re-fetch when the repository provider changes or is invalidated.
  final repository = ref.watch(transactionsRepositoryProvider);
  return repository.getTransactions();
});

// Provides the future of user's budgets
final budgetsFutureProvider =
    FutureProvider.autoDispose<List<Budget>>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return [];
  }
  final repository = ref.watch(budgetsRepositoryProvider);
  return repository.getBudgets();
});

// A provider for the user object to avoid rebuilding when auth state changes but user is the same
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Provides the transactions repository instance
final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref);
});

// Provides the budgets repository instance
final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref);
});
