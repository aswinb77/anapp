import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    
    // Mark as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.markAllAsRead();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF141414),
      ),
      backgroundColor: const Color(0xFF141414),
      body: provider.notifications.isEmpty
          ? const Center(child: Text('No notifications', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notif = provider.notifications[index];
                final isModerationWarning = notif.type == 'moderation_warning';
                final severity = notif.severity;

                final bgColor = isModerationWarning
                    ? (severity == 'ban' || severity == 'restricted'
                        ? Colors.red.shade900.withValues(alpha: 0.3)
                        : severity == 'serious'
                            ? Colors.orange.shade900.withValues(alpha: 0.3)
                            : Colors.amber.shade900.withValues(alpha: 0.3))
                    : Colors.transparent;

                final iconData = isModerationWarning
                    ? Icons.warning_amber_rounded
                    : Icons.notifications;

                final iconColor = isModerationWarning
                    ? (severity == 'ban' || severity == 'restricted'
                        ? Colors.redAccent
                        : severity == 'serious'
                            ? Colors.orangeAccent
                            : Colors.amberAccent)
                    : (notif.isRead ? Colors.white54 : Colors.redAccent);

                return Container(
                  color: bgColor,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notif.isRead && !isModerationWarning ? Colors.white12 : iconColor.withValues(alpha: 0.2),
                      child: Icon(iconData, color: iconColor),
                    ),
                    title: Text(notif.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(notif.message, style: const TextStyle(color: Colors.white70)),
                    trailing: Text(
                      _getTimeAgo(notif.createdAt),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
