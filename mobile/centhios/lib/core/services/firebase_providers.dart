import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centhios/core/services/sms_reader_service.dart';
import 'package:centhios/core/services/transaction_importer_service.dart';
import 'package:centhios/data/repositories/transactions_repository.dart';

// Provider for the Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Provider for the Firebase Firestore instance
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final smsReaderServiceProvider = Provider<SmsReaderService>((ref) {
  return SmsReaderService();
});

final transactionImporterServiceProvider =
    Provider<TransactionImporterService>((ref) {
  final smsReader = ref.watch(smsReaderServiceProvider);
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);
  return TransactionImporterService(
    smsReaderService: smsReader,
    transactionsRepository: transactionsRepo,
  );
});
