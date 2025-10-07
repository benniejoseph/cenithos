/// Notification Center Screen
/// 
/// Beautiful UI for viewing and managing all notifications

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:centhios/data/models/notification_model.dart';
import 'package:centhios/core/services/notification_manager.dart';
import 'package:centhios/services/centhios_api_service.dart' as api;

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<NotificationModel> _notifications = [];
  NotificationFilter _currentFilter = NotificationFilter.all;
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notifications = await notificationManager.fetchNotifications(
        user.uid,
        unreadOnly: _currentFilter == NotificationFilter.unread,
        priority: _currentFilter == NotificationFilter.critical
            ? 'critical'
            : _currentFilter == NotificationFilter.high
                ? 'high'
                : null,
      );

      // Apply additional filters
      List<NotificationModel> filtered = notifications;

      if (_currentFilter == NotificationFilter.today) {
        final today = DateTime.now();
        filtered = notifications.where((n) {
          return n.timestamp.year == today.year &&
              n.timestamp.month == today.month &&
              n.timestamp.day == today.day;
        }).toList();
      } else if (_currentFilter == NotificationFilter.thisWeek) {
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        filtered = notifications.where((n) => n.timestamp.isAfter(weekAgo)).toList();
      }

      setState(() {
        _notifications = filtered;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load notifications')),
        );
      }
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() => _isRefreshing = true);
    await _loadNotifications();
    setState(() => _isRefreshing = false);
  }

  Future<void> _markAllAsRead() async {
    await notificationManager.markAllAsRead();
    await _loadNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ All notifications marked as read')),
      );
    }
  }

  void _changeFilter(NotificationFilter filter) {
    setState(() => _currentFilter = filter);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notificationManager.getUnreadCount();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000), // Black
              Color(0xFF001A15), // Dark emerald
              Color(0xFF003D33), // Darker emerald
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar with gradient theme
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (unreadCount > 0)
                            Text(
                              '$unreadCount unread',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF00C6A7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton.icon(
                        onPressed: _markAllAsRead,
                        icon: const Icon(Icons.done_all, size: 18, color: Color(0xFF00C6A7)),
                        label: const Text(
                          'Mark all',
                          style: TextStyle(color: Color(0xFF00C6A7)),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Color(0xFF00C6A7)),
                      onPressed: () {
                        // TODO: Navigate to notification settings
                      },
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF00C6A7).withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: NotificationFilter.values.map((filter) {
                final isSelected = filter == _currentFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.displayName),
                    selected: isSelected,
                    onSelected: (_) => _changeFilter(filter),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    selectedColor: const Color(0xFF00C6A7).withOpacity(0.3),
                    side: BorderSide(
                      color: isSelected 
                          ? const Color(0xFF00C6A7)
                          : Colors.white.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00C6A7)
                          : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Notifications list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00C6A7),
                  ),
                )
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: const Color(0xFF00C6A7),
                      backgroundColor: Colors.black87,
                      onRefresh: _refreshNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          return _NotificationCard(
                            notification: _notifications[index],
                            onTap: () => _handleNotificationTap(_notifications[index]),
                            onDismiss: () => _handleDismiss(_notifications[index]),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    String icon;

    switch (_currentFilter) {
      case NotificationFilter.unread:
        message = 'No unread notifications';
        icon = '✅';
        break;
      case NotificationFilter.critical:
        message = 'No critical notifications';
        icon = '🔴';
        break;
      case NotificationFilter.today:
        message = 'No notifications today';
        icon = '📅';
        break;
      default:
        message = 'No notifications yet';
        icon = '🔔';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00C6A7).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00C6A7).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    await notificationManager.markAsRead(notification.id);
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });

    // Show detail sheet
    if (mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _NotificationDetailSheet(notification: notification),
      );
    }
  }

  Future<void> _handleDismiss(NotificationModel notification) async {
    // Remove from list
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });

    // Archive notification
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await api.CenthiosAPIService.updateNotification(
        notificationId: notification.id,
        userId: user.uid,
        isArchived: true,
      );
    } catch (e) {
      print('Error archiving notification: $e');
    }
  }
}

/// Notification Card Widget
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.red.shade900, Colors.red.shade700],
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead 
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFF00C6A7).withOpacity(0.5),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C6A7).withOpacity(notification.isRead ? 0.0 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority indicator & icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C6A7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00C6A7).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        notification.categoryIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (!notification.isRead)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00C6A7),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF00C6A7),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: const Color(0xFF00C6A7).withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF00C6A7).withOpacity(0.7),
                              ),
                            ),
                            if (notification.priority == 'critical' ||
                                notification.priority == 'high') ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(notification.priorityColor).withOpacity(0.2),
                                      Color(notification.priorityColor).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Color(notification.priorityColor).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  notification.priority.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(notification.priorityColor),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Icon(
                    Icons.chevron_right,
                    color: const Color(0xFF00C6A7).withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Notification Detail Sheet
class _NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF001A15), // Dark emerald
            Color(0xFF000000), // Black
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: const Color(0xFF00C6A7).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C6A7).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Icon & Priority
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C6A7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF00C6A7).withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C6A7).withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        notification.categoryIcon,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(notification.priorityColor).withOpacity(0.2),
                                Color(notification.priorityColor).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(notification.priorityColor).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            notification.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(notification.priorityColor),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: const Color(0xFF00C6A7).withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.timeAgo,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF00C6A7).withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Body
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.6,
                ),
              ),

              // Rich content (if available)
              if (notification.richContent != null) ...[
                const SizedBox(height: 24),
                _buildRichContent(notification.richContent!),
              ],

              // Actions
              if (notification.availableActions.isNotEmpty) ...[
                const SizedBox(height: 32),
                ..._buildActions(context, notification),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichContent(Map<String, dynamic> richContent) {
    final chips = richContent['chips'] as List?;
    final stats = richContent['stats'] as List?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips
          if (chips != null && chips.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map<Widget>((chip) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    chip.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Stats
          if (stats != null && stats.isNotEmpty) ...[
            if (chips != null && chips.isNotEmpty) const SizedBox(height: 12),
            ...stats.map<Widget>((stat) {
              final label = stat['label'] as String?;
              final value = stat['value'] as String?;
              final progress = stat['progress'] as double?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label ?? '',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        Text(
                          value ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, NotificationModel notification) {
    return notification.availableActions.map((action) {
      IconData icon;
      String label;
      Color? color;

      switch (action) {
        case 'view':
          icon = Icons.visibility;
          label = 'View Details';
          break;
        case 'mark_safe':
          icon = Icons.check_circle;
          label = 'Mark as Safe';
          color = Colors.green;
          break;
        case 'report_fraud':
          icon = Icons.report;
          label = 'Report Fraud';
          color = Colors.red;
          break;
        case 'edit_category':
          icon = Icons.edit;
          label = 'Edit Category';
          break;
        case 'pay_now':
          icon = Icons.payment;
          label = 'Pay Now';
          color = Colors.blue;
          break;
        default:
          icon = Icons.touch_app;
          label = action;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          onPressed: () {
            // Handle action
            Navigator.pop(context);
            // TODO: Implement action handlers
          },
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: color ?? Colors.grey[300]!),
          ),
        ),
      );
    }).toList();
  }
}


