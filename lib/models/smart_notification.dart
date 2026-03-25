import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Notification type enum
// ---------------------------------------------------------------------------
enum SmartNotificationType {
  weaknessPractice,
  incompleteRound,
  performanceTrend,
  teeTimeReminder,
}

extension SmartNotificationTypeX on SmartNotificationType {
  String get key {
    switch (this) {
      case SmartNotificationType.weaknessPractice:  return 'weaknessPractice';
      case SmartNotificationType.incompleteRound:   return 'incompleteRound';
      case SmartNotificationType.performanceTrend:  return 'performanceTrend';
      case SmartNotificationType.teeTimeReminder:   return 'teeTimeReminder';
    }
  }

  String get label {
    switch (this) {
      case SmartNotificationType.weaknessPractice:  return 'Practice Reminder';
      case SmartNotificationType.incompleteRound:   return 'Resume Round';
      case SmartNotificationType.performanceTrend:  return 'Performance Insight';
      case SmartNotificationType.teeTimeReminder:   return 'Tee Time';
    }
  }

  IconData get icon {
    switch (this) {
      case SmartNotificationType.weaknessPractice:  return Icons.fitness_center_rounded;
      case SmartNotificationType.incompleteRound:   return Icons.sports_golf_rounded;
      case SmartNotificationType.performanceTrend:  return Icons.trending_up_rounded;
      case SmartNotificationType.teeTimeReminder:   return Icons.schedule_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// Priority enum
// ---------------------------------------------------------------------------
enum NotificationPriority { low, normal, high, urgent }

extension NotificationPriorityX on NotificationPriority {
  String get label => name;

  Color get accentColor {
    switch (this) {
      case NotificationPriority.low:    return const Color(0xFF1565C0);
      case NotificationPriority.normal: return const Color(0xFF5A9E1F);
      case NotificationPriority.high:   return const Color(0xFFE65100);
      case NotificationPriority.urgent: return const Color(0xFFB71C1C);
    }
  }
}

// ---------------------------------------------------------------------------
// SmartNotification — output payload
// ---------------------------------------------------------------------------
class SmartNotification {
  final SmartNotificationType type;
  final String title;
  final String body;
  final NotificationPriority priority;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  const SmartNotification({
    required this.type,
    required this.title,
    required this.body,
    required this.priority,
    required this.generatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'type':        type.key,
        'title':       title,
        'body':        body,
        'priority':    priority.label,
        'generatedAt': generatedAt.toIso8601String(),
        'metadata':    metadata,
      };

  factory SmartNotification.fromJson(Map<String, dynamic> json) {
    return SmartNotification(
      type: SmartNotificationType.values.firstWhere(
        (e) => e.key == json['type'],
        orElse: () => SmartNotificationType.performanceTrend,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.label == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() => 'SmartNotification(${type.key}, "$title", ${priority.label})';
}
