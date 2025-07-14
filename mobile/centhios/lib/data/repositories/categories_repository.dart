import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:centhios/core/services/firebase_providers.dart';
import 'package:centhios/core/config.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref);
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final categoriesRepository = ref.watch(categoriesRepositoryProvider);
  return categoriesRepository.getCategories();
});

class CategoriesRepository {
  final Ref _ref;

  CategoriesRepository(this._ref);

  Future<List<String>> getCategories() async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    if (token == null) {
      print('[CategoriesRepository] ERROR: User not authenticated. Token is null.');
      throw Exception('User not authenticated.');
    }

    final url = Uri.parse('${AppConfig.backendBaseUrl}/categories');
    print('[CategoriesRepository] INFO: Fetching categories from $url');
    print('[CategoriesRepository] INFO: Auth Token: Bearer $token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[CategoriesRepository] INFO: Response Status Code: ${response.statusCode}');
      print('[CategoriesRepository] INFO: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception(
            'Failed to load categories. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('[CategoriesRepository] CRITICAL: Exception during network call: $e');
      rethrow;
    }
  }

  Future<List<String>> createCategory(String name) async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    if (token == null) throw Exception('User not authenticated.');

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<String>();
    } else {
      throw Exception('Failed to create category');
    }
  }

  Future<List<String>> deleteCategory(String name) async {
    final token =
        await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    if (token == null) throw Exception('User not authenticated.');

    final response = await http.delete(
      Uri.parse('${AppConfig.backendBaseUrl}/categories/$name'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<String>();
    } else {
      throw Exception('Failed to delete category');
    }
  }
}
