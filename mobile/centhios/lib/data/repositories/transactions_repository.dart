import 'dart:convert';
import 'package:centhios/core/config.dart';
import 'package:centhios/core/services/firebase_providers.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

class TransactionsRepository {
  final String _baseUrl = AppConfig.backendBaseUrl;
  final http.Client _client;
  final Ref _ref;

  TransactionsRepository(this._ref) : _client = http.Client();

  Future<List<Transaction>> getTransactions(
      [TransactionFilters? filters]) async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();

    String url = '$_baseUrl/transactions';
    if (filters != null && !filters.isEmpty) {
      final params = filters.toQueryParams();
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url += '?$query';
    }

    final response = await _client.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transactions: ${response.body}');
    }
  }

  Future<void> createTransaction({
    required String description,
    required double amount,
    required String type,
    required String category,
    required DateTime date,
    String? vendor,
    String? bank,
  }) async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'description': description,
        'amount': amount,
        'type': type,
        'category': category,
        'date': date.toIso8601String(),
        'vendor': vendor,
        'bank': bank,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create transaction: ${response.body}');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/transactions/$transactionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete transaction: ${response.body}');
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/transactions/${transaction.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(transaction),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update transaction: ${response.body}');
    }
  }

  Future<void> sendCategoryFeedback({
    required String transactionId,
    required String description,
    required String oldCategory,
    required String newCategory,
  }) async {
    try {
      final token =
          await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/transactions/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'transactionId': transactionId,
          'description': description,
          'oldCategory': oldCategory,
          'newCategory': newCategory,
        }),
      );

      if (response.statusCode != 200) {
        // Failing to send feedback should not block the user.
        // Log the error for debugging, but don't throw an exception.
        print(
            'Failed to send category feedback. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      // Also catch network or other errors silently.
      print('Error sending category feedback: $e');
    }
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref);
});
