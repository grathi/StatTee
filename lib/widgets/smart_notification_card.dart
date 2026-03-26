import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/smart_notification.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// SmartNotificationCard — reusable preview card for a SmartNotification
//
// Usage:
//   SmartNotificationCard(notification: notif)
//   SmartNotificationCard(notification: notif, compact: true)
// ---------------------------------------------------------------------------
class SmartNotificationCard extends StatelessWidget {
  final SmartNotification notification;

  /// When true, renders a condensed single-line version (for lists/feeds).
  final bool compact;

  /// Called when the card is tapped. Null = no tap feedback.
  final VoidCallback? onTap;

  const SmartNotificationCard({
    super.key,
    required this.notification,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return compact
        ? _CompactCard(notification: notification, onTap: onTap)
        : _FullCard(notification: notification, onTap: onTap);
  }
}

// ---------------------------------------------------------------------------
// Full card — used in preview sheets and notification history
// ---------------------------------------------------------------------------
class _FullCard extends StatelessWidget {
  final SmartNotification notification;
  final VoidCallback? onTap;

  const _FullCard({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final sw   = MediaQuery.of(context).size.width;
    final type = notification.type;
    final prio = notification.priority;

    final config = _CardConfig.from(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: config.gradient,
            stops: const [0.0, 0.55, 1.0],
          ),
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(36)),
          shadows: [
            BoxShadow(
              color: config.shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: EdgeInsets.all((sw * 0.052).clamp(16.0, 22.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Icon circle
                Container(
                  width: (sw * 0.1).clamp(36.0, 44.0),
                  height: (sw * 0.1).clamp(36.0, 44.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Icon(type.icon,
                      color: Colors.white,
                      size: (sw * 0.052).clamp(17.0, 22.0)),
                ),
                const SizedBox(width: 10),
                // Type label + priority badge
                Expanded(
                  child: Row(
                    children: [
                      Text(type.label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: (sw * 0.030).clamp(10.0, 13.0),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          )),
                      const Spacer(),
                      _PriorityBadge(priority: prio),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: (sw * 0.032).clamp(10.0, 14.0)),

            // Divider
            Container(
                height: 0.5,
                color: Colors.white.withValues(alpha: 0.2)),
            SizedBox(height: (sw * 0.030).clamp(10.0, 14.0)),

            // Title
            Text(notification.title,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: (sw * 0.044).clamp(15.0, 19.0),
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                )),
            SizedBox(height: (sw * 0.022).clamp(6.0, 10.0)),

            // Body
            Text(notification.body,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: (sw * 0.034).clamp(12.0, 15.0),
                  height: 1.5,
                )),

            // Metadata chips (optional — rendered only if metadata has
            // display-worthy keys)
            if (_hasDisplayMetadata) ...[
              SizedBox(height: (sw * 0.030).clamp(10.0, 14.0)),
              _MetadataRow(notification: notification, sw: sw),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasDisplayMetadata {
    final m = notification.metadata;
    return m.containsKey('daysSinceRound') ||
        m.containsKey('improvementStrokes') ||
        m.containsKey('holesPlayed');
  }
}

// ---------------------------------------------------------------------------
// Compact card — for lists (rounds feed, notification history)
// ---------------------------------------------------------------------------
class _CompactCard extends StatelessWidget {
  final SmartNotification notification;
  final VoidCallback? onTap;

  const _CompactCard({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final sw    = MediaQuery.of(context).size.width;
    final type  = notification.type;
    final config = _CardConfig.from(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: ShapeDecoration(
          color: c.cardBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(color: c.cardBorder),
          ),
          shadows: c.cardShadow,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.042).clamp(13.0, 18.0),
          vertical: (sw * 0.038).clamp(12.0, 16.0),
        ),
        child: Row(
          children: [
            // Gradient icon square
            Container(
              width: (sw * 0.11).clamp(38.0, 46.0),
              height: (sw * 0.11).clamp(38.0, 46.0),
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: config.gradient,
                ),
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Icon(type.icon,
                  color: Colors.white,
                  size: (sw * 0.052).clamp(17.0, 22.0)),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                      style: TextStyle(
                        color: c.primaryText,
                        fontSize: (sw * 0.036).clamp(12.0, 15.0),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(notification.body,
                      style: TextStyle(
                        color: c.secondaryText,
                        fontSize: (sw * 0.030).clamp(10.0, 13.0),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Priority dot + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _PriorityDot(priority: notification.priority),
                const SizedBox(height: 4),
                Text(_timeLabel(notification.generatedAt),
                    style: TextStyle(
                      color: c.tertiaryText,
                      fontSize: (sw * 0.026).clamp(9.0, 11.0),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ---------------------------------------------------------------------------
// _MetadataRow — chips showing key stats from notification metadata
// ---------------------------------------------------------------------------
class _MetadataRow extends StatelessWidget {
  final SmartNotification notification;
  final double sw;

  const _MetadataRow({required this.notification, required this.sw});

  @override
  Widget build(BuildContext context) {
    final m = notification.metadata;
    final chips = <Widget>[];

    if (m['daysSinceRound'] != null) {
      chips.add(_chip('${m['daysSinceRound']}d since last round', sw));
    }
    if (m['improvementStrokes'] != null) {
      final v = (m['improvementStrokes'] as num).abs().toStringAsFixed(1);
      chips.add(_chip('−$v strokes improved', sw));
    }
    if (m['holesPlayed'] != null) {
      chips.add(_chip('${m['holesPlayed']} holes completed', sw));
    }
    if (m['roundsAnalysed'] != null) {
      chips.add(_chip('${m['roundsAnalysed']} rounds analysed', sw));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _chip(String label, double sw) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(40),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
      child: Text(label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: (sw * 0.026).clamp(9.0, 11.0),
            fontWeight: FontWeight.w500,
          )),
    );
  }
}

// ---------------------------------------------------------------------------
// _PriorityBadge — inline badge for full card header
// ---------------------------------------------------------------------------
class _PriorityBadge extends StatelessWidget {
  final NotificationPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority == NotificationPriority.normal) return const SizedBox.shrink();

    final labels = {
      NotificationPriority.low:    ('LOW',    Colors.white38),
      NotificationPriority.high:   ('HIGH',   const Color(0xFFFFB74D)),
      NotificationPriority.urgent: ('URGENT', const Color(0xFFEF5350)),
    };

    final entry = labels[priority];
    if (entry == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: entry.$2.withValues(alpha: 0.2),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(40),
          side: BorderSide(color: entry.$2.withValues(alpha: 0.4)),
        ),
      ),
      child: Text(entry.$1,
          style: TextStyle(
            color: entry.$2,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          )),
    );
  }
}

// ---------------------------------------------------------------------------
// _PriorityDot — small coloured dot for compact card
// ---------------------------------------------------------------------------
class _PriorityDot extends StatelessWidget {
  final NotificationPriority priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: priority.accentColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CardConfig — gradient + shadow per notification type
// ---------------------------------------------------------------------------
class _CardConfig {
  final List<Color> gradient;
  final Color shadowColor;

  const _CardConfig({required this.gradient, required this.shadowColor});

  factory _CardConfig.from(SmartNotificationType type) {
    switch (type) {
      case SmartNotificationType.weaknessPractice:
        return const _CardConfig(
          gradient: [Color(0xFF1A3A08), Color(0xFF3D6E14), Color(0xFF4E8A18)],
          shadowColor: Color(0x3C4E8A18),
        );
      case SmartNotificationType.incompleteRound:
        return const _CardConfig(
          gradient: [Color(0xFF0D2B40), Color(0xFF1A4E72), Color(0xFF1565C0)],
          shadowColor: Color(0x3C1565C0),
        );
      case SmartNotificationType.performanceTrend:
        return const _CardConfig(
          gradient: [Color(0xFF2E1760), Color(0xFF4A2A99), Color(0xFF6A35C8)],
          shadowColor: Color(0x3C6A35C8),
        );
      case SmartNotificationType.teeTimeReminder:
        return const _CardConfig(
          gradient: [Color(0xFF3D1A08), Color(0xFF7A3010), Color(0xFFE65100)],
          shadowColor: Color(0x3CE65100),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// SmartNotificationFeed — ready-to-use scrollable list of notification cards
// ---------------------------------------------------------------------------
class SmartNotificationFeed extends StatelessWidget {
  final List<SmartNotification> notifications;
  final bool compact;
  final EdgeInsetsGeometry? padding;
  final void Function(SmartNotification)? onTap;

  const SmartNotificationFeed({
    super.key,
    required this.notifications,
    this.compact = true,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    if (notifications.isEmpty) {
      return _EmptyFeed();
    }

    return ListView.separated(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.055,
            vertical: sh * 0.016,
          ),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => SizedBox(height: sh * 0.012),
      itemBuilder: (_, i) => SmartNotificationCard(
        notification: notifications[i],
        compact: compact,
        onTap: onTap != null ? () => onTap!(notifications[i]) : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyFeed — placeholder when there are no notifications
// ---------------------------------------------------------------------------
class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c  = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: c.iconContainerBg,
              shape: BoxShape.circle,
              border: Border.all(color: c.iconContainerBorder),
            ),
            child: Icon(Icons.notifications_none_rounded,
                color: c.tertiaryText, size: 32),
          ),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: (sw * 0.042).clamp(15.0, 18.0),
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 6),
          Text('Play more rounds to unlock\nAI-personalised alerts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.secondaryText,
                fontSize: (sw * 0.030).clamp(11.0, 13.0),
                height: 1.5,
              )),
        ],
      ),
    );
  }
}
