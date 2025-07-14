import 'dart:convert';
import 'package:centhios/core/config.dart';
import 'package:centhios/core/services/sms_reader_service.dart';
import 'package:centhios/data/models/transaction_model.dart';
import 'package:centhios/data/repositories/transactions_repository.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:http/http.dart' as http;

class TransactionImporterService {
  final SmsReaderService _smsReaderService;
  final TransactionsRepository _transactionsRepository;

  TransactionImporterService({
    required SmsReaderService smsReaderService,
    required TransactionsRepository transactionsRepository,
  })  : _smsReaderService = smsReaderService,
        _transactionsRepository = transactionsRepository;

  Future<int> importFromSms() async {
    // 1. Get SMS messages
    final List<SmsMessage> smsMessages = await _smsReaderService.getAllSms();
    final messageBodies = smsMessages.map((m) => m.body ?? '').toList();

    // 2. Call AI backend to parse transactions
    final url = Uri.parse('${AppConfig.aiBaseUrl}/parse-sms');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messages': messageBodies}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to parse SMS messages: ${response.body}');
    }

    final decodedBody = jsonDecode(response.body);
    final transactionsData =
        List<Map<String, dynamic>>.from(decodedBody['transactions']);

    if (transactionsData.isEmpty) {
      return 0;
    }

    // 3. Call AI to categorize transactions
    final categorizedData = await _categorizeTransactions(transactionsData);

    // 4. Convert to Transaction models and merge categories
    for (final data in transactionsData) {
      final categoryInfo = categorizedData.firstWhere(
        (cat) => cat['id'] == data['id'],
        orElse: () => {'category': 'Other'},
      );
      // Directly call createTransaction with the data, no need to create a local model
      await _transactionsRepository.createTransaction(
        description: data['merchant'] ?? 'Unknown',
        vendor: data['vendor'],
        bank: data['bank'],
        amount: (data['amount'] as num).toDouble(),
        type: data['type'] ?? 'expense',
        category: categoryInfo['category'] ?? 'Other',
        date: DateTime.tryParse(data['date']) ?? DateTime.now(),
      );
    }

    return transactionsData.length;
  }

  Future<List<Map<String, dynamic>>> _categorizeTransactions(
      List<Map<String, dynamic>> transactions) async {
    // We need to give each transaction a temporary ID for matching
    for (var i = 0; i < transactions.length; i++) {
      transactions[i]['id'] = i.toString();
    }

    final url = Uri.parse('${AppConfig.aiBaseUrl}/categorize-transactions');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'transactions': transactions,
        'categories': TransactionCategories.all, // Using predefined categories
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to categorize transactions: ${response.body}');
    }

    final decodedBody = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(decodedBody['transactions']);
  }
}
