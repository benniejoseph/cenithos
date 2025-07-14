import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'package:centhios/core/config.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/core/services/firebase_providers.dart';
import 'package:centhios/data/repositories/categories_repository.dart';

final smsImportServiceProvider = Provider((ref) => SmsImportService(ref));

class SmsImportService {
  final Ref _ref;
  final SmsQuery _smsQuery = SmsQuery();

  SmsImportService(this._ref);

  Future<List<Transaction>> analyzeSms({
    DateTimeRange? dateRange,
    required List<String> categories,
  }) async {
    // Get the currently authenticated user's ID
    final userId = _ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null) {
      throw Exception("User not authenticated. Cannot parse SMS.");
    }
    
    final messages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
      sort: true,
    );

    List<SmsMessage> filteredMessages = messages;
    if (dateRange != null) {
      // Add a day to the end date to make the range inclusive of the entire end day.
      final inclusiveEndDate = dateRange.end.add(const Duration(days: 1));
      
      print("[SmsImportService] INFO: Filtering ${messages.length} SMS from ${dateRange.start} to $inclusiveEndDate");

      filteredMessages = messages.where((sms) {
        if (sms.date == null) return false;
        // The new logic is inclusive of the start date and exclusive of the day after the end date.
        return !sms.date!.isBefore(dateRange.start) && sms.date!.isBefore(inclusiveEndDate);
      }).toList();

      print("[SmsImportService] INFO: Found ${filteredMessages.length} messages after date filtering.");
    }

    final messageBodies = filteredMessages.map((sms) => sms.body ?? '').toList();

    if (messageBodies.isEmpty) {
      return [];
    }
    
    final token = await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.aiBaseUrl}/parse-sms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId, // Pass the user ID to the backend
          'messages': messageBodies,
          'context': {
            'categories': categories,
            'current_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            if (dateRange != null)
              'start_date': DateFormat('yyyy-MM-dd').format(dateRange.start),
            if (dateRange != null)
              'end_date': DateFormat('yyyy-MM-dd').format(dateRange.end),
          }
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> transactions = data['transactions'] ?? [];
        return transactions.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to analyze SMS: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to analyze SMS: $e');
    }
  }

  Future<({int created, int duplicates, int errors})> saveTransactions(
      List<Transaction> transactions) async {
    final token = await _ref.read(firebaseAuthProvider).currentUser?.getIdToken();
    final userId = _ref.read(firebaseAuthProvider).currentUser?.uid;
    if (token == null || userId == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/transactions/import'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'transactions': transactions,
      }),
    );
    
    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return (
        created: (data['created'] ?? 0) as int,
        duplicates: (data['duplicates'] ?? 0) as int,
        errors: (data['errors'] ?? 0) as int,
      );
    } else {
      throw Exception('Failed to save transactions: ${response.body}');
    }
  }
} 