import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int _maxRoomMessages = 200;
  static const int _cleanupWindow = 50;

  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  String? _userId;
  String? _username;
  String? _roomId;
  bool _isReady = false;
  int _unreadCount = 0;
  DateTime _lastSeen = DateTime.now();

  String? get roomId => _roomId;
  bool get isReady => _isReady;
  int get unreadCount => _unreadCount;

  void updateUser(String? userId, String? username) {
    if (_userId == userId) return;

    _userId = userId;
    _username = username;
    _reset();

    if (_userId != null) {
      _initialize();
    }
  }

  void _reset() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _roomId = null;
    _isReady = false;
    _unreadCount = 0;
    _lastSeen = DateTime.now();
    notifyListeners();
  }

  Future<void> _initialize() async {
    try {
      _roomId = await _ensureChatRoom(_userId!);
      _isReady = true;
      notifyListeners();
      _markChatSeen();
      _listenToRoom();
      await _publishOnlinePresence();
    } catch (e) {
      debugPrint('Chat provider initialization failed: $e');
      _roomId = 'global_chat_room_1';
      _isReady = true;
      notifyListeners();
      _listenToRoom();
    }
  }

  Future<String> _ensureChatRoom(String userId) async {
    final userRef = _db.collection('users').doc(userId);
    final userSnapshot = await userRef.get();
    final storedRoom = (userSnapshot.data() ?? {})['chatRoom']?.toString();
    if (storedRoom != null && storedRoom.isNotEmpty) {
      return storedRoom;
    }

    const int roomCapacity = 200;
    const int maxRooms = 10;
    const String roomPrefix = 'global_chat_room_';

    String selectedRoom = '';
    for (var i = 1; i <= maxRooms; i++) {
      final candidate = '$roomPrefix$i';
      final countSnapshot = await _db
          .collection('users')
          .where('chatRoom', isEqualTo: candidate)
          .get();

      if (countSnapshot.docs.length < roomCapacity) {
        selectedRoom = candidate;
        break;
      }
    }

    if (selectedRoom.isEmpty) {
      selectedRoom = 'global_chat_room_10';
    }

    await userRef.set({'chatRoom': selectedRoom}, SetOptions(merge: true));
    return selectedRoom;
  }

  void _listenToRoom() {
    if (_roomId == null) return;
    _messagesSubscription?.cancel();

    _messagesSubscription = _db
        .collection(_roomId!)
        .orderBy('createdAt', descending: true)
        .limit(_maxRoomMessages + _cleanupWindow)
        .snapshots()
        .listen((snapshot) {
      final newCount = snapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final senderId = data['senderId']?.toString();
        return createdAt != null &&
            createdAt.isAfter(_lastSeen) &&
            senderId != _userId;
      }).length;

      if (newCount != _unreadCount) {
        _unreadCount = newCount;
        notifyListeners();
      }

      _cleanupRoom(snapshot);
    }, onError: (error) {
      debugPrint('Chat message listener failed: $error');
    });
  }

  void markChatSeen() {
    _markChatSeen();
  }

  void _markChatSeen() {
    _lastSeen = DateTime.now();
    if (_unreadCount != 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> _publishOnlinePresence() async {
    if (_userId == null || _username == null) return;

    try {
      final userRef = _db.collection('users').doc(_userId);
      await userRef.update({'chatOnlineAt': FieldValue.serverTimestamp()});

      final userSnapshot = await userRef.get();
      final followers = List<String>.from(userSnapshot.data()?['followers'] ?? []);
      if (followers.isEmpty) return;

      final batch = _db.batch();
      for (final followerId in followers) {
        final notifRef = _db
            .collection('users')
            .doc(followerId)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'title': '$_username is online',
          'body': '$_username is now online in global chat.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to publish online presence: $e');
    }
  }

  Future<void> _cleanupRoom(QuerySnapshot snapshot) async {
    if (_roomId == null) return;
    if (snapshot.docs.length <= _maxRoomMessages) return;

    try {
      final batch = _db.batch();
      for (var i = _maxRoomMessages; i < snapshot.docs.length; i++) {
        batch.delete(snapshot.docs[i].reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to cleanup chat room: $e');
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
