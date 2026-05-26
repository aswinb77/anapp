import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class FeedProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FeedProvider() {
    // Don't auto-fetch on construction
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> fetchPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    _subscription?.cancel();
    
    try {
      final newsSnap = await _db.collection('news_posts')
          .orderBy('created_at', descending: true)
          .limit(30)
          .get();

      final userSnap = await _db.collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      final items = <Post>[
        ...newsSnap.docs.map((doc) => Post.fromNewsPost(doc, currentUserId)),
        ...userSnap.docs.map((doc) => Post.fromFirestore(doc, currentUserId))
            .where((p) => p.status != 'removed' && p.status != 'under_review'),
      ];

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _posts = items;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Firestore error fetching posts: $e');
      _error = 'Could not load posts. Check your connection.';
      _posts = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPost(Post post) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot add post: user not authenticated');
        return;
      }
      final username = currentUser.displayName ?? post.authorName;
      final userId = currentUser.uid;

      await _db.collection('posts').add({
        'title': post.title,
        'content': post.content,
        'type': post.type,
        'trailerUrl': post.trailerUrl,
        'authorName': username,
        'authorId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'likesList': [],
        'commentsList': [],
      });
      
      // Notify followers via In-App Notifications
      await _notifyFollowers(userId, username, post.title);

    } on FirebaseException catch (e) {
      debugPrint('Firestore error adding post: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('Error adding post: $e');
    }
  }

  Future<void> _notifyFollowers(String myUserId, String myName, String postTitle) async {
    try {
      final doc = await _db.collection('users').doc(myUserId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final followers = List<String>.from(data['followers'] ?? []);
        
        if (followers.isNotEmpty) {
          final batch = _db.batch();
          for (final followerId in followers) {
            final notifRef = _db.collection('users').doc(followerId).collection('notifications').doc();
            batch.set(notifRef, {
              'title': 'New Post from $myName',
              'body': postTitle.isNotEmpty ? postTitle : 'Check out my new update!',
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }
      }
    } catch (e) {
      debugPrint('Failed to send follower notifications: $e');
    }
  }

  void deletePost(String postId) async {
    try {
      await _db.collection('posts').doc(postId).delete();
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  Future<void> toggleLike(String postId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final collectionName = post.authorId == 'system' ? 'news_posts' : 'posts';
      final docRef = _db.collection(collectionName).doc(postId);

      if (post.isLiked) {
        post.likes--;
        post.isLiked = false;
        post.likesList.remove(userId);
        notifyListeners();
        await docRef.update({
          'likesList': FieldValue.arrayRemove([userId])
        });
      } else {
        post.likes++;
        post.isLiked = true;
        post.likesList.add(userId);
        notifyListeners();
        await docRef.update({
          'likesList': FieldValue.arrayUnion([userId])
        });
      }
    }
  }

  Future<void> addComment(String postId, String comment) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final currentList = List<String>.from(_posts[postIndex].commentsList);
      currentList.add(comment);
      _posts[postIndex].commentsList = currentList;
      _posts[postIndex].comments = currentList.length;
      notifyListeners();

      try {
        final collectionName = _posts[postIndex].authorId == 'system' ? 'news_posts' : 'posts';
        await _db.collection(collectionName).doc(postId).update({
          'commentsList': FieldValue.arrayUnion([comment])
        });
      } catch (e) {
        currentList.removeLast();
        _posts[postIndex].commentsList = currentList;
        _posts[postIndex].comments = currentList.length;
        notifyListeners();
      }
    }
  }
}
