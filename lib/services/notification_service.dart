import 'package:flutter/material.dart';

class SafenetNotification {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onAction;
  final String? actionLabel;

  SafenetNotification({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.onAction,
    this.actionLabel,
  });
}

class NotificationService {
  static final List<SafenetNotification> notifications = [];
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  static final ValueNotifier<List<SafenetNotification>> notificationsNotifier =
      ValueNotifier<List<SafenetNotification>>([]);

  static void addNotification({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onAction,
    String? actionLabel,
    String? customTime,
  }) {
    notifications.insert(
      0,
      SafenetNotification(
        title: title,
        description: description,
        time: customTime ?? _formatCurrentTime(),
        icon: icon,
        iconColor: iconColor,
        onAction: onAction,
        actionLabel: actionLabel,
      ),
    );
    unreadCount.value += 1;
    notificationsNotifier.value = List.from(notifications);
  }

  static void clearNotifications() {
    notifications.clear();
    unreadCount.value = 0;
    notificationsNotifier.value = [];
  }

  static String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}
