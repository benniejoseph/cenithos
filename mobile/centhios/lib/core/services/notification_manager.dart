/// Notification Manager
/// 
/// Handles FCM integration, notification display, and local storage

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:centhios/data/models/notification_model.dart';
import 'package:centhios/services/centhios_api_service.dart' as api;

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background notification received: ${message.messageId}');
  // Handle background message
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _currentUserId;
  List<NotificationModel> _cachedNotifications = [];

  // Notification channels
  static const String _channelId = 'financial_alerts';
  static const String _channelName = 'Financial Alerts';
  static const String _channelDescription = 'Important financial notifications';

  /// Initialize notification system
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) {
      print('✅ Notification manager already initialized');
      return;
    }

    _currentUserId = userId;

    try {
      // 1. Request permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('❌ Notification permissions denied');
        return;
      }

      // 2. Initialize local notifications
      await _initializeLocalNotifications();

      // 3. Get FCM token and register with backend
      final fcmToken = await _fcm.getToken();
      if (fcmToken != null) {
        print('📱 FCM Token obtained: ${fcmToken.substring(0, 20)}...');
        await _registerToken(userId, fcmToken);
      }

      // 4. Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 5. Handle notification that opened the app (if any)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // 6. Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        print('📱 FCM Token refreshed');
        _registerToken(userId, newToken);
      });

      _isInitialized = true;
      print('✅ Notification manager initialized');
    } catch (e) {
      print('❌ Error initializing notification manager: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    print('✅ Local notifications initialized');
  }

  /// Register FCM token with backend
  Future<void> _registerToken(String userId, String fcmToken) async {
    try {
      await api.CenthiosAPIService.registerFCMToken(
        userId: userId,
        fcmToken: fcmToken,
      );
      print('✅ FCM token registered with backend');
    } catch (e) {
      print('❌ Error registering FCM token: $e');
    }
  }

  /// Handle foreground message (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground notification received: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      // Show as local notification
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }

    // Refresh notification list
    if (_currentUserId != null) {
      fetchNotifications(_currentUserId!);
    }
  }

  /// Handle notification tap (from system tray or background)
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped: ${message.data}');

    final notificationId = message.data['notification_id'] as String?;
    final transactionId = message.data['transaction_id'] as String?;

    // TODO: Navigate to appropriate screen
    // This would typically use a navigator key to push to notification detail
    // or transaction detail screen

    if (notificationId != null) {
      // Mark as read
      markAsRead(notificationId);
    }
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final notificationId = data['notification_id'] as String?;

        if (notificationId != null) {
          markAsRead(notificationId);
        }
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Fetch notifications from backend
  Future<List<NotificationModel>> fetchNotifications(
    String userId, {
    bool unreadOnly = false,
    String? category,
    String? priority,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final data = await api.CenthiosAPIService.getUserNotifications(
        userId: userId,
        limit: limit,
        offset: offset,
        unreadOnly: unreadOnly,
        category: category,
        priority: priority,
      );

      _cachedNotifications = data
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      // Save to local storage
      await _saveNotificationsToLocal(_cachedNotifications);

      print('✅ Fetched ${_cachedNotifications.length} notifications');

      return _cachedNotifications;
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      // Return cached notifications on error
      return _cachedNotifications.isNotEmpty
          ? _cachedNotifications
          : await _loadNotificationsFromLocal();
    }
  }

  /// Get cached notifications (instant, no network call)
  List<NotificationModel> getCachedNotifications() {
    return List.from(_cachedNotifications);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_currentUserId == null) return;

    try {
      await api.CenthiosAPIService.updateNotification(
        notificationId: notificationId,
        userId: _currentUserId!,
        isRead: true,
      );

      // Update local cache
      final index = _cachedNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _cachedNotifications[index] = _cachedNotifications[index].copyWith(isRead: true);
        await _saveNotificationsToLocal(_cachedNotifications);
      }

      print('✅ Marked notification as read');
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      await api.CenthiosAPIService.markAllNotificationsRead(
        userId: _currentUserId!,
      );

      // Update local cache
      _cachedNotifications = _cachedNotifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      await _saveNotificationsToLocal(_cachedNotifications);

      print('✅ Marked all notifications as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// Get unread count
  int getUnreadCount() {
    return _cachedNotifications.where((n) => !n.isRead).length;
  }

  /// Get notification statistics
  Future<NotificationStats> getStats() async {
    if (_currentUserId == null) {
      return const NotificationStats(
        totalNotifications: 0,
        unreadCount: 0,
        byCategory: {},
        byPriority: {},
        recentCount: 0,
      );
    }

    try {
      final data = await api.CenthiosAPIService.getNotificationStats(
        userId: _currentUserId!,
      );
      return NotificationStats.fromJson(data);
    } catch (e) {
      print('❌ Error getting stats: $e');
      return const NotificationStats(
        totalNotifications: 0,
        unreadCount: 0,
        byCategory: {},
        byPriority: {},
        recentCount: 0,
      );
    }
  }

  /// Save notifications to local storage
  Future<void> _saveNotificationsToLocal(
    List<NotificationModel> notifications,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList('cached_notifications', jsonList);
    } catch (e) {
      print('❌ Error saving to local storage: $e');
    }
  }

  /// Load notifications from local storage
  Future<List<NotificationModel>> _loadNotificationsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('cached_notifications') ?? [];
      return jsonList
          .map((json) => NotificationModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('❌ Error loading from local storage: $e');
      return [];
    }
  }

  /// Clear all cached notifications
  Future<void> clearCache() async {
    _cachedNotifications.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_notifications');
  }

  /// Dispose (cleanup)
  void dispose() {
    _cachedNotifications.clear();
    _isInitialized = false;
    _currentUserId = null;
  }
}

/// Global notification manager instance
final notificationManager = NotificationManager();

