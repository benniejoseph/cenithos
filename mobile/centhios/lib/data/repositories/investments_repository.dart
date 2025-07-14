import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:centhios/data/models/investment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final investmentsRepositoryProvider = Provider<InvestmentsRepository>((ref) {
  return InvestmentsRepository(
      FirebaseFirestore.instance, FirebaseAuth.instance);
});

class InvestmentsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  InvestmentsRepository(this._firestore, this._auth);

  Future<List<Investment>> getInvestments() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final snapshot = await _firestore
        .collection('investments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Investment.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Investment> createInvestment(Investment investment) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final docRef = await _firestore.collection('investments').add(
          investment.copyWith(userId: user.uid).toMap(),
        );
    final snapshot = await docRef.get();
    return Investment.fromMap(snapshot.data()!, snapshot.id);
  }

  Future<void> updateInvestment(Investment investment) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await _firestore
        .collection('investments')
        .doc(investment.id)
        .update(investment.toMap());
  }

  Future<void> deleteInvestment(String investmentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await _firestore.collection('investments').doc(investmentId).delete();
  }
}
