import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:centhios/data/models/debt_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  return DebtsRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class DebtsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DebtsRepository(this._firestore, this._auth);

  Future<List<Debt>> getDebts() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final snapshot = await _firestore
        .collection('debts')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Debt.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Debt> createDebt(Debt debt) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final docRef = await _firestore.collection('debts').add(
          debt.copyWith(userId: user.uid).toMap(),
        );
    final snapshot = await docRef.get();
    return Debt.fromMap(snapshot.data()!, snapshot.id);
  }

  Future<void> updateDebt(Debt debt) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await _firestore.collection('debts').doc(debt.id).update(debt.toMap());
  }

  Future<void> deleteDebt(String debtId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await _firestore.collection('debts').doc(debtId).delete();
  }
}
