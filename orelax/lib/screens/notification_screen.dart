import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = context.watch<AuthProvider>();
    _userId = authProvider.userId;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'staff_added':
        return Icons.people_alt_outlined;
      case 'event_approved':
        return Icons.event_available_outlined;
      case 'message_received':
        return Icons.message_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'staff_added':
        return const Color(0xFF0F7A3B);
      case 'event_approved':
        return const Color(0xFF16803C);
      case 'message_received':
        return const Color(0xFF0E9F6E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _sectionLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(date).inDays;

    if (difference == 0) return 'TODAY';
    if (difference == 1) return 'YESTERDAY';
    return DateFormat('EEE, MMM d').format(dateTime).toUpperCase();
  }

  String _relativeTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    final navRoute = context.read<NotificationProvider>().getNavigationRoute(notification);
    final route = navRoute['route'] as String;
    final arguments = navRoute['arguments'];

    if (arguments != null) {
      Navigator.pushNamed(context, route, arguments: arguments);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  String _subtitleForNotification(NotificationModel notification) {
    final metadata = notification.metadata;
    switch (notification.type) {
      case 'staff_added':
        return metadata?.staffName != null
            ? '${metadata!.staffName} • ${metadata.staffRole ?? ''}'
            : notification.body;
      case 'event_approved':
        return metadata?.eventTitle != null
            ? '${metadata!.eventTitle} • ${metadata.eventLocation ?? ''}'
            : notification.body;
      case 'message_received':
        return metadata?.senderName != null
            ? '${metadata!.senderName}: ${metadata.senderPreview ?? ''}'
            : notification.body;
      default:
        return notification.body;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Notification',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              if (notificationProvider.unreadCount == 0) {
                return const SizedBox(width: 16);
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B7A3D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notificationProvider.unreadCount} NEW',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final notifications = notificationProvider.notifications;
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final groupedNotifications = <String, List<NotificationModel>>{};
          for (final notification in notifications) {
            final section = _sectionLabel(notification.createdAt);
            groupedNotifications.putIfAbsent(section, () => []).add(notification);
          }

          final sections = groupedNotifications.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(0),
            itemCount: sections.length,
            itemBuilder: (context, sectionIndex) {
              final section = sections[sectionIndex];
              final sectionNotifications = section.value;
              final showMarkAll = _userId != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          section.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        if (showMarkAll)
                          TextButton(
                            onPressed: () => context
                                .read<NotificationProvider>()
                                .markAllAsRead(_userId!),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0B7A3D),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Mark all as read',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sectionNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = sectionNotifications[index];
                      final accentColor = _colorForType(notification.type);

                      return Dismissible(
                        key: ValueKey(notification.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red.shade400,
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          context
                              .read<NotificationProvider>()
                              .deleteNotification(notification.id);
                        },
                        child: _NotificationItemCard(
                          notification: notification,
                          accentColor: accentColor,
                          onTap: () {
                            if (!notification.isRead) {
                              context
                                  .read<NotificationProvider>()
                                  .markAsRead(notification.id);
                            }
                            // Navigate based on notification type
                            _handleNotificationTap(context, notification);
                          },
                          iconForType: _iconForType,
                          subtitleForNotification: _subtitleForNotification,
                          relativeTime: _relativeTime,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationItemCard extends StatefulWidget {
  final NotificationModel notification;
  final Color accentColor;
  final VoidCallback onTap;
  final Function(String) iconForType;
  final Function(NotificationModel) subtitleForNotification;
  final Function(DateTime) relativeTime;

  const _NotificationItemCard({
    required this.notification,
    required this.accentColor,
    required this.onTap,
    required this.iconForType,
    required this.subtitleForNotification,
    required this.relativeTime,
  });

  @override
  State<_NotificationItemCard> createState() => _NotificationItemCardState();
}

class _NotificationItemCardState extends State<_NotificationItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: _isHovered ? Colors.grey.shade50 : Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.iconForType(widget.notification.type),
                  color: widget.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: widget.notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.relativeTime(widget.notification.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitleForNotification(widget.notification),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
