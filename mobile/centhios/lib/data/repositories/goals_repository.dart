import 'dart:convert';
import 'package:centhios/core/config.dart';
import 'package:centhios/core/services/firebase_providers.dart';
import 'package:centhios/data/models/goal_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class GoalsRepository {
  final String _baseUrl = AppConfig.backendBaseUrl;
  final http.Client _client;
  final Ref _ref;

  GoalsRepository(this._ref) : _client = http.Client();

  Future<String?> _getAuthToken() async {
    return await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
  }

  Future<List<Goal>> getGoals() async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    final response = await _client.get(
      Uri.parse('$_baseUrl/goals'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Goal.fromMap(json, json['id'])).toList();
    } else {
      throw Exception('Failed to load goals: ${response.body}');
    }
  }

  Future<Goal> createGoal(Map<String, dynamic> goalData) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/goals'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(goalData),
    );

    if (response.statusCode == 201) {
      return Goal.fromMap(
          json.decode(response.body), json.decode(response.body)['id']);
    } else {
      throw Exception('Failed to create goal: ${response.body}');
    }
  }

  Future<Goal> updateGoal(String id, Map<String, dynamic> goalData) async {
    final token = await _getAuthToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/goals/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(goalData),
    );

    if (response.statusCode == 200) {
      return Goal.fromMap(
          json.decode(response.body), json.decode(response.body)['id']);
    } else {
      throw Exception('Failed to update goal: ${response.body}');
    }
  }

  Future<void> deleteGoal(String id) async {
    final token = await _getAuthToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/goals/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete goal: ${response.body}');
    }
  }
}

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref);
});
