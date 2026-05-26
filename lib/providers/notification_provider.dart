import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<AppNotification> _notifications = [];
  StreamSubscription<QuerySnapshot>? _subscription;
  String? _userId;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void watchUser(String? userId) {
    if (_userId == userId) return;
    _subscription?.cancel();
    _userId = userId;
    _notifications.clear();
    notifyListeners();

    if (_userId != null) {
      _subscribeToNotifications();
    }
  }

  void _subscribeToNotifications() {
    if (_userId == null) return;

    _subscription = _db
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _notifications
        ..clear()
        ..addAll(snapshot.docs.map((doc) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          return AppNotification(
            id: doc.id,
            title: data['title']?.toString() ?? 'Update',
            message: data['message']?.toString() ?? data['body']?.toString() ?? '',
            createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
            type: data['type']?.toString() ?? 'general',
            severity: data['severity']?.toString() ?? 'info',
            isRead: data['isRead'] == true || data['read'] == true,
          );
        }));
      notifyListeners();
    }, onError: (error) {
      debugPrint('Notification subscription failed: $error');
    });
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    final unreadDocs = _notifications.where((n) => !n.isRead).toList();
    if (unreadDocs.isEmpty) return;

    try {
      final batch = _db.batch();
      final coll = _db.collection('users').doc(_userId).collection('notifications');
      for (final notif in unreadDocs) {
        batch.update(coll.doc(notif.id), {'isRead': true});
      }
      await batch.commit();
      for (final notif in unreadDocs) {
        notif.isRead = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to mark notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
