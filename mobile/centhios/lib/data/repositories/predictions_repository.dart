import 'dart:convert';
import 'package:http/http.dart' as http;

class PredictionsRepository {
  final String _baseUrl =
      "http://127.0.0.1:8000"; // Assuming the AI service is running locally

  Future<Map<String, dynamic>> getSpendingPrediction(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/predict-spending/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load spending prediction');
    }
  }
}
