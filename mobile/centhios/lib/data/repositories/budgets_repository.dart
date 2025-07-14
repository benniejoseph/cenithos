import 'dart:convert';
import 'package:centhios/core/config.dart';
import 'package:centhios/core/services/firebase_providers.dart';
import 'package:centhios/data/models/budget_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class BudgetsRepository {
  final String _baseUrl = AppConfig.backendBaseUrl;
  final http.Client _client;
  final Ref _ref;

  BudgetsRepository(this._ref) : _client = http.Client();

  Future<String?> _getAuthToken() async {
    return await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
  }

  Future<List<Budget>> getBudgets() async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    final response = await _client.get(
      Uri.parse('$_baseUrl/budgets'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Budget.fromMap(json, json['id'])).toList();
    } else {
      throw Exception('Failed to load budgets: ${response.body}');
    }
  }

  Future<Budget> createBudget(Map<String, dynamic> budgetData) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/budgets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(budgetData),
    );

    if (response.statusCode == 201) {
      return Budget.fromMap(
          json.decode(response.body), json.decode(response.body)['id']);
    } else {
      throw Exception('Failed to create budget: ${response.body}');
    }
  }

  Future<Budget> updateBudget(
      String id, Map<String, dynamic> budgetData) async {
    final token = await _getAuthToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/budgets/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(budgetData),
    );

    if (response.statusCode == 200) {
      return Budget.fromMap(
          json.decode(response.body), json.decode(response.body)['id']);
    } else {
      throw Exception('Failed to update budget: ${response.body}');
    }
  }

  Future<void> deleteBudget(String id) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/budgets/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete budget: ${response.body}');
    }
  }
}

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref);
});
