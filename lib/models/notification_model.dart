class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type;
  final String severity;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.type = 'general',
    this.severity = 'info',
    this.isRead = false,
  });
}
