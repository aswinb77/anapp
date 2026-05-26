import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final String content;
  final String type; // 'news', 'leak', 'trailer'
  final String? trailerUrl;
  final String authorName;
  final String? authorId;
  final DateTime createdAt;
  int likes;
  int comments;
  bool isLiked;
  List<String> commentsList;
  List<String> likesList;
  
  // New fields
  final bool isVerifiedNews;
  final String? sourceName;
  final String? sourceUrl;
  final String? imageUrl;
  final String status;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.trailerUrl,
    required this.authorName,
    this.authorId,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.commentsList = const [],
    this.likesList = const [],
    this.isVerifiedNews = false,
    this.sourceName,
    this.sourceUrl,
    this.imageUrl,
    this.status = 'visible',
  });

  factory Post.fromFirestore(DocumentSnapshot doc, String? currentUserId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final likesList = List<String>.from(data['likesList'] ?? []);
    final commentsList = List<String>.from(data['commentsList'] ?? []);
    return Post(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? data['text'] ?? data['body'] ?? '',
      type: data['type'] ?? 'news',
      trailerUrl: data['trailerUrl'],
      authorName: data['authorName'] ?? 'Unknown',
      authorId: data['authorId'] ?? data['userId'] ?? data['uid'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: likesList.length,
      comments: commentsList.length,
      isLiked: currentUserId != null && likesList.contains(currentUserId),
      commentsList: commentsList,
      likesList: likesList,
      isVerifiedNews: false,
      sourceName: null,
      sourceUrl: null,
      imageUrl: data['image_url'],
      status: data['status'] ?? 'visible',
    );
  }

  factory Post.fromNewsPost(DocumentSnapshot doc, String? currentUserId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final likesList = List<String>.from(data['likesList'] ?? []);
    final commentsList = List<String>.from(data['commentsList'] ?? []);
    
    return Post(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['body'] ?? '',
      type: 'news',
      authorName: 'Movie.cc',
      authorId: 'system',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: likesList.length,
      comments: commentsList.length,
      isLiked: currentUserId != null && likesList.contains(currentUserId),
      likesList: likesList,
      commentsList: commentsList,
      isVerifiedNews: true,
      sourceName: data['source_name'],
      sourceUrl: data['source_url'],
      imageUrl: data['image_url'],
      status: 'visible',
    );
  }
}
