/// Notification Model
/// 
/// Represents a financial notification with all its properties

class NotificationModel {
  final String id;
  final String userId;
  final String category;
  final String priority;
  final String title;
  final String body;
  final Map<String, dynamic>? richContent;
  final DateTime timestamp;
  final double importanceScore;
  final double relevanceScore;
  final bool isRead;
  final bool isArchived;
  final List<String> availableActions;
  final String? relatedTransactionId;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.priority,
    required this.title,
    required this.body,
    this.richContent,
    required this.timestamp,
    required this.importanceScore,
    required this.relevanceScore,
    this.isRead = false,
    this.isArchived = false,
    this.availableActions = const [],
    this.relatedTransactionId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      richContent: json['rich_content'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      importanceScore: (json['importance_score'] as num).toDouble(),
      relevanceScore: (json['relevance_score'] as num).toDouble(),
      isRead: json['is_read'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      availableActions: (json['available_actions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      relatedTransactionId: json['related_transaction_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'priority': priority,
      'title': title,
      'body': body,
      'rich_content': richContent,
      'timestamp': timestamp.toIso8601String(),
      'importance_score': importanceScore,
      'relevance_score': relevanceScore,
      'is_read': isRead,
      'is_archived': isArchived,
      'available_actions': availableActions,
      'related_transaction_id': relatedTransactionId,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? category,
    String? priority,
    String? title,
    String? body,
    Map<String, dynamic>? richContent,
    DateTime? timestamp,
    double? importanceScore,
    double? relevanceScore,
    bool? isRead,
    bool? isArchived,
    List<String>? availableActions,
    String? relatedTransactionId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      body: body ?? this.body,
      richContent: richContent ?? this.richContent,
      timestamp: timestamp ?? this.timestamp,
      importanceScore: importanceScore ?? this.importanceScore,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      availableActions: availableActions ?? this.availableActions,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
    );
  }

  /// Get category icon
  String get categoryIcon {
    switch (category) {
      case 'smart_transaction':
        return '💳';
      case 'fraud_detection':
        return '🚨';
      case 'budget_alert':
        return '📊';
      case 'spending_insight':
        return '💡';
      case 'bill_reminder':
        return '📅';
      case 'emi_loan':
        return '🏦';
      case 'goal_progress':
        return '🎯';
      case 'savings_opportunity':
        return '💰';
      case 'income_tracking':
        return '📈';
      case 'cashflow_prediction':
        return '🔮';
      case 'ai_insight':
        return '🎓';
      case 'proactive_recommendation':
        return '✨';
      default:
        return '🔔';
    }
  }

  /// Get priority color
  int get priorityColor {
    switch (priority) {
      case 'critical':
        return 0xFFE53935; // Red
      case 'high':
        return 0xFFFF6F00; // Orange
      case 'medium':
        return 0xFFFBC02D; // Yellow
      case 'low':
        return 0xFF1E88E5; // Blue
      case 'info':
        return 0xFF43A047; // Green
      default:
        return 0xFF757575; // Grey
    }
  }

  /// Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if notification is recent (< 24 hours)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inHours < 24;
  }
}

/// Notification Statistics Model
class NotificationStats {
  final int totalNotifications;
  final int unreadCount;
  final Map<String, int> byCategory;
  final Map<String, int> byPriority;
  final int recentCount;

  const NotificationStats({
    required this.totalNotifications,
    required this.unreadCount,
    required this.byCategory,
    required this.byPriority,
    required this.recentCount,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalNotifications: json['total_notifications'] as int,
      unreadCount: json['unread_count'] as int,
      byCategory: Map<String, int>.from(json['by_category'] as Map),
      byPriority: Map<String, int>.from(json['by_priority'] as Map),
      recentCount: json['recent_count'] as int,
    );
  }
}

/// Notification Filter
enum NotificationFilter {
  all,
  unread,
  critical,
  high,
  today,
  thisWeek,
}

extension NotificationFilterExtension on NotificationFilter {
  String get displayName {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.unread:
        return 'Unread';
      case NotificationFilter.critical:
        return 'Critical';
      case NotificationFilter.high:
        return 'High';
      case NotificationFilter.today:
        return 'Today';
      case NotificationFilter.thisWeek:
        return 'This Week';
    }
  }
}

