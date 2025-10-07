/// 🚀 CenthiosV2 API Service - Complete Integration
/// 
/// This service provides access to all features:
/// - SMS Parsing (Gemini AI)
/// - Voice Banking (Gemini 2.5 Pro)
/// - Receipt Scanning (Gemini Vision)
/// - Cost Tracking (Google Cloud Platform)
/// - Smart Banking Features
library;

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class CenthiosAPIService {
  /// Backend URL
  static const String BASE_URL = 'https://centhios-ai-528127801498.us-central1.run.app';
  
  // ========================================================================
  // HEALTH CHECK
  // ========================================================================
  
  /// Check backend health and available capabilities
  static Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse('$BASE_URL/'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
      /* Returns:
      {
        "status": "healthy",
        "version": "2.0.0",
        "capabilities": {
          "gemini": true,
          "speech": true,
          "vision": true,
          "prophet": true
        }
      }
      */
    }
    
    throw Exception('Backend unavailable');
  }
  
  // ========================================================================
  // VOICE BANKING
  // ========================================================================
  
  /// Process text-based voice command
  /// 
  /// Parameters:
  /// - [text]: User's command text
  /// - [userId]: User ID from Firebase Auth
  /// - [familyMember]: 'dad', 'mom', or 'child' (for voice profiles)
  static Future<VoiceCommandResponse> voiceCommand({
    required String text,
    required String userId,
    String familyMember = 'dad',
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/voice/command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'user_id': userId,
        'family_member': familyMember,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return VoiceCommandResponse.fromJson(data);
    }
    
    throw Exception('Voice command failed: ${response.body}');
  }
  
  /// Process audio file (future feature)
  /// 
  /// Parameters:
  /// - [audioFile]: Audio file from microphone
  /// - [userId]: User ID
  /// - [familyMember]: Voice profile
  static Future<VoiceCommandResponse> voiceAudio({
    required File audioFile,
    required String userId,
    String familyMember = 'dad',
  }) async {
    final audioBytes = await audioFile.readAsBytes();
    final audioBase64 = base64Encode(audioBytes);
    
    final response = await http.post(
      Uri.parse('$BASE_URL/api/voice/audio'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'audio_base64': audioBase64,
        'user_id': userId,
        'family_member': familyMember,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return VoiceCommandResponse.fromJson(data);
    } else if (response.statusCode == 501) {
      throw Exception('Audio processing not yet implemented');
    }
    
    throw Exception('Voice audio failed: ${response.body}');
  }
  
  // ========================================================================
  // RECEIPT SCANNING
  // ========================================================================
  
  /// Scan receipt from image
  /// 
  /// Parameters:
  /// - [imageFile]: Image file from camera
  /// - [documentHint]: 'receipt', 'bank_statement', or 'credit_card'
  static Future<ReceiptScanResponse> scanReceiptImage({
    required File imageFile,
    String documentHint = 'receipt',
  }) async {
    final imageBytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);
    
    final response = await http.post(
      Uri.parse('$BASE_URL/api/receipts/extract'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image_base64': imageBase64,
        'document_hint': documentHint,
        'use_gemini_vision': true,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ReceiptScanResponse.fromJson(data);
    }
    
    throw Exception('Receipt scan failed: ${response.body}');
  }
  
  /// Extract receipt from OCR text (fallback)
  /// 
  /// Parameters:
  /// - [ocrText]: Text extracted by ML Kit
  static Future<ReceiptScanResponse> extractFromOCR({
    required String ocrText,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/receipts/extract'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ocr_text': ocrText,
        'use_gemini_vision': true,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ReceiptScanResponse.fromJson(data);
    }
    
    throw Exception('Receipt extraction failed: ${response.body}');
  }
  
  // ========================================================================
  // NOTIFICATIONS - AI-Powered Notification System
  // ========================================================================
  
  /// Register FCM token for push notifications
  static Future<Map<String, dynamic>> registerFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/v1/notifications/fcm/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'fcm_token': fcmToken,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to register FCM token: ${response.body}');
  }
  
  /// Get notifications for user
  static Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
    String? category,
    String? priority,
    String? since,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'unread_only': unreadOnly.toString(),
    };
    
    if (category != null) queryParams['category'] = category;
    if (priority != null) queryParams['priority'] = priority;
    if (since != null) queryParams['since'] = since;
    
    final uri = Uri.parse('$BASE_URL/api/v1/notifications/user/$userId')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    
    return [];
  }
  
  /// Update notification status
  static Future<Map<String, dynamic>> updateNotification({
    required String notificationId,
    required String userId,
    bool? isRead,
    bool? isArchived,
    String? actionTaken,
  }) async {
    final uri = Uri.parse('$BASE_URL/api/v1/notifications/$notificationId')
        .replace(queryParameters: {'user_id': userId});
    
    final body = <String, dynamic>{};
    if (isRead != null) body['is_read'] = isRead;
    if (isArchived != null) body['is_archived'] = isArchived;
    if (actionTaken != null) body['action_taken'] = actionTaken;
    
    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to update notification: ${response.body}');
  }
  
  /// Mark all notifications as read
  static Future<Map<String, dynamic>> markAllNotificationsRead({
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/v1/notifications/mark-all-read'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to mark all as read: ${response.body}');
  }
  
  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats({
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/v1/notifications/stats/$userId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to get notification stats: ${response.body}');
  }
  
  /// Get notification preferences
  static Future<Map<String, dynamic>> getNotificationPreferences({
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/v1/notifications/preferences/$userId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to get preferences: ${response.body}');
  }
  
  /// Update notification preferences
  static Future<Map<String, dynamic>> updateNotificationPreferences({
    required String userId,
    bool? notificationsEnabled,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    double? highValueThreshold,
    Map<String, bool>? categoryPreferences,
    bool? showInsights,
    bool? showRecommendations,
    bool? learnOptimalTimes,
  }) async {
    final body = <String, dynamic>{};
    
    if (notificationsEnabled != null) body['notifications_enabled'] = notificationsEnabled;
    if (quietHoursEnabled != null) body['quiet_hours_enabled'] = quietHoursEnabled;
    if (quietHoursStart != null) body['quiet_hours_start'] = quietHoursStart;
    if (quietHoursEnd != null) body['quiet_hours_end'] = quietHoursEnd;
    if (highValueThreshold != null) body['high_value_threshold'] = highValueThreshold;
    if (categoryPreferences != null) body['category_preferences'] = categoryPreferences;
    if (showInsights != null) body['show_insights'] = showInsights;
    if (showRecommendations != null) body['show_recommendations'] = showRecommendations;
    if (learnOptimalTimes != null) body['learn_optimal_times'] = learnOptimalTimes;
    
    final response = await http.patch(
      Uri.parse('$BASE_URL/api/v1/notifications/preferences/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to update preferences: ${response.body}');
  }

  // ========================================================================
  // COST TRACKING (Google Cloud Platform)
  // ========================================================================
  
  /// Get cost summary for a time period
  /// 
  /// Parameters:
  /// - [userId]: User ID (optional, omit for project-wide costs)
  /// - [startDate]: Start date (ISO format)
  /// - [endDate]: End date (ISO format)
  /// - [includeLiveData]: Whether to fetch live billing data from GCP
  static Future<Map<String, dynamic>> getCostSummary({
    String? userId,
    String? startDate,
    String? endDate,
    bool includeLiveData = false,
  }) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['user_id'] = userId;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    queryParams['include_live_data'] = includeLiveData.toString();
    
    final uri = Uri.parse('$BASE_URL/api/v1/costs/summary').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to get cost summary: ${response.body}');
  }
  
  /// Get daily costs for charts
  /// 
  /// Parameters:
  /// - [days]: Number of days (default 30)
  /// - [userId]: User ID (optional)
  static Future<List<Map<String, dynamic>>> getDailyCosts({
    int days = 30,
    String? userId,
  }) async {
    final queryParams = {'days': days.toString()};
    if (userId != null) queryParams['user_id'] = userId;
    
    final uri = Uri.parse('$BASE_URL/api/v1/costs/daily').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
    
    return [];
  }
  
  /// Estimate monthly cost based on recent usage
  /// 
  /// Parameters:
  /// - [userId]: User ID (optional)
  static Future<Map<String, dynamic>> estimateMonthlyCost({String? userId}) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['user_id'] = userId;
    
    final uri = Uri.parse('$BASE_URL/api/v1/costs/estimate-monthly').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to estimate monthly cost: ${response.body}');
  }
  
  /// Get cost breakdown by category (AI, Storage, Compute, etc.)
  /// 
  /// Parameters:
  /// - [days]: Number of days (default 30)
  /// - [userId]: User ID (optional)
  static Future<List<Map<String, dynamic>>> getCostByCategory({
    int days = 30,
    String? userId,
  }) async {
    final queryParams = {'days': days.toString()};
    if (userId != null) queryParams['user_id'] = userId;
    
    final uri = Uri.parse('$BASE_URL/api/v1/costs/breakdown/category').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['categories'] ?? []);
    }
    
    return [];
  }
  
  /// Get cost breakdown by service
  /// 
  /// Parameters:
  /// - [days]: Number of days (default 30)
  /// - [userId]: User ID (optional)
  static Future<List<Map<String, dynamic>>> getCostByService({
    int days = 30,
    String? userId,
  }) async {
    final queryParams = {'days': days.toString()};
    if (userId != null) queryParams['user_id'] = userId;
    
    final uri = Uri.parse('$BASE_URL/api/v1/costs/breakdown/service').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['services'] ?? []);
    }
    
    return [];
  }
  
  /// Get Gemini API pricing information
  static Future<Map<String, dynamic>> getGeminiPricing() async {
    final response = await http.get(Uri.parse('$BASE_URL/api/v1/costs/gemini/pricing'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to get Gemini pricing: ${response.body}');
  }
  
  /// Get cost alerts if spending exceeds threshold
  /// 
  /// Parameters:
  /// - [userId]: User ID (optional)
  /// - [thresholdUsd]: Alert threshold in USD (default 10.0)
  static Future<Map<String, dynamic>> getCostAlerts({
    String? userId,
    double thresholdUsd = 10.0,
  }) async {
    final queryParams = {'threshold_usd': thresholdUsd.toString()};
    if (userId != null) queryParams['user_id'] = userId;
    
    final uri = Uri.parse('$BASE_URL/api/v1/costs/alerts').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to get cost alerts: ${response.body}');
  }
  
  // ========================================================================
  // SPENDING ANALYTICS
  // ========================================================================
  
  /// Analyze spending with Prophet forecasting
  /// 
  /// Parameters:
  /// - [userId]: User ID
  /// - [transactions]: List of transactions
  /// - [trainModel]: Whether to train Prophet model (slower but more accurate)
  static Future<SpendingInsights> analyzeSpending({
    required String userId,
    required List<Map<String, dynamic>> transactions,
    bool trainModel = true,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/insights/spending'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'transactions': transactions,
        'train_model': trainModel,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SpendingInsights.fromJson(data);
    }
    
    throw Exception('Spending analysis failed: ${response.body}');
  }
  
  /// Get cached spending insights (faster)
  /// 
  /// Parameters:
  /// - [userId]: User ID
  static Future<SpendingInsights> getCachedInsights({
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/insights/spending/$userId'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SpendingInsights.fromJson(data);
    }
    
    throw Exception('Failed to get insights: ${response.body}');
  }

  // ========================================================================
  // NEW FEATURES - PHASES 1-2 (SMS Intelligence & Smart Banking)
  // ========================================================================

  /// Get scheduled payments (Phase 1 - SMS Intelligence)
  static Future<Map<String, dynamic>> getScheduledPayments(String userId) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/v1/intelligence/scheduled-payments?user_id=$userId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to load scheduled payments');
  }

  /// Get cashback & rewards tracker (Phase 1 - SMS Intelligence)
  static Future<Map<String, dynamic>> getCashback(String userId) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/v1/intelligence/cashback?user_id=$userId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to load cashback data');
  }

  /// Get savings goals (Phase 2 - Smart Banking)
  static Future<Map<String, dynamic>> getSavingsGoals(String userId) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/v1/smart-banking/goals?user_id=$userId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to load savings goals');
  }

  /// Create a new savings goal
  static Future<Map<String, dynamic>> createSavingsGoal({
    required String userId,
    required String name,
    required double targetAmount,
    required String deadline,
    String category = 'general',
    double initialAmount = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/v1/smart-banking/goals'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'name': name,
        'target_amount': targetAmount,
        'deadline': deadline,
        'category': category,
        'initial_amount': initialAmount,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to create savings goal');
  }

  /// Add contribution to a goal
  static Future<Map<String, dynamic>> addGoalContribution({
    required String goalId,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/v1/smart-banking/goals/$goalId/contribute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to add contribution');
  }

  /// Get investment portfolio (Phase 2 - Smart Banking)
  static Future<Map<String, dynamic>> getPortfolio(String userId) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/v1/smart-banking/portfolio?user_id=$userId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to load portfolio');
  }

  /// Get loans & EMI details (Phase 2 - Smart Banking)
  static Future<Map<String, dynamic>> getLoans(String userId) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/v1/smart-banking/loans?user_id=$userId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to load loans');
  }

  /// Calculate loan prepayment benefit
  static Future<Map<String, dynamic>> calculatePrepayment({
    required String loanId,
    required double prepaymentAmount,
    bool reduceTenure = true,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/v1/smart-banking/loans/prepayment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'loan_id': loanId,
        'prepayment_amount': prepaymentAmount,
        'reduce_tenure': reduceTenure,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to calculate prepayment');
  }

  /// Compare loan offers
  static Future<Map<String, dynamic>> compareLoans({
    required List<Map<String, dynamic>> loanOffers,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/v1/smart-banking/loans/compare'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'loan_offers': loanOffers,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception('Failed to compare loans');
  }
}

// ============================================================================
// RESPONSE MODELS
// ============================================================================

/// Voice command response
class VoiceCommandResponse {
  final String responseText;
  final String? responseAudioUrl;
  final String intent;
  final double confidence;
  final String model;
  final String familyMember;
  
  VoiceCommandResponse({
    required this.responseText,
    this.responseAudioUrl,
    required this.intent,
    required this.confidence,
    required this.model,
    required this.familyMember,
  });
  
  factory VoiceCommandResponse.fromJson(Map<String, dynamic> json) {
    return VoiceCommandResponse(
      responseText: json['response_text'] ?? '',
      responseAudioUrl: json['response_audio_url'],
      intent: json['intent'] ?? 'general',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      model: json['model'] ?? 'gemini-2.5-pro',
      familyMember: json['family_member'] ?? 'dad',
    );
  }
}

/// Receipt scan response
class ReceiptScanResponse {
  final String documentType;
  final double confidence;
  final Map<String, dynamic> extractedData;
  final List<String> visualInsights;
  final List<String> warnings;
  
  ReceiptScanResponse({
    required this.documentType,
    required this.confidence,
    required this.extractedData,
    this.visualInsights = const [],
    this.warnings = const [],
  });
  
  factory ReceiptScanResponse.fromJson(Map<String, dynamic> json) {
    return ReceiptScanResponse(
      documentType: json['document_type'] ?? 'receipt',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      extractedData: json['extracted_data'] ?? {},
      visualInsights: List<String>.from(json['visual_insights'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
  
  // Helper getters
  String? get merchantName => extractedData['merchant_name'];
  String? get date => extractedData['date'];
  double? get totalAmount => (extractedData['total_amount'] as num?)?.toDouble();
  List<dynamic>? get items => extractedData['items'];
}


/// Spending insights response
class SpendingInsights {
  final Map<String, dynamic> summary;
  final Map<String, dynamic> trend;
  final List<Map<String, dynamic>> forecast;
  final List<Map<String, dynamic>> anomalies;
  
  SpendingInsights({
    required this.summary,
    required this.trend,
    this.forecast = const [],
    this.anomalies = const [],
  });
  
  factory SpendingInsights.fromJson(Map<String, dynamic> json) {
    return SpendingInsights(
      summary: json['summary'] ?? {},
      trend: json['trend'] ?? {},
      forecast: List<Map<String, dynamic>>.from(json['forecast_next_7_days'] ?? []),
      anomalies: List<Map<String, dynamic>>.from(json['anomalies'] ?? []),
    );
  }
  
  // Helper getters
  double get totalSpending => (summary['total_spending'] as num?)?.toDouble() ?? 0.0;
  double get dailyAverage => (summary['daily_average'] as num?)?.toDouble() ?? 0.0;
  double get monthlyAverage => (summary['monthly_average'] as num?)?.toDouble() ?? 0.0;
  String get trendDirection => trend['direction'] ?? 'stable';
  double get trendChangePercentage => (trend['change_percentage'] as num?)?.toDouble() ?? 0.0;
  bool get hasAnomalies => anomalies.isNotEmpty;
}
