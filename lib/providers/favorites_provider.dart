import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Movie> _favorites = [];

  List<Movie> get favorites => _favorites;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FavoritesProvider() {
    // Load from local prefs first (instant, no network) — sync from Firestore
    // only when the user explicitly calls reload() after login.
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favsString = prefs.getString('favorites');
    if (favsString != null) {
      final decoded = json.decode(favsString);
      if (decoded is List) {
        _favorites = decoded
            .map((item) => Movie.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        notifyListeners();
      }
    }
  }

  Future<void> reload() => _loadFavorites();

  Future<void> _loadFavorites() async {
    final userId = _auth.currentUser?.uid;

    if (userId != null) {
      try {
        final snapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .get()
            .timeout(const Duration(seconds: 10));

        final loaded = snapshot.docs
            .map((doc) => doc.data()['movieDetails'])
            .where((d) => d != null)
            .map((raw) => Movie.fromJson(Map<String, dynamic>.from(raw as Map)))
            .toList();

        // Sort client-side by addedAt if available, else leave as is
        _favorites = loaded;
        notifyListeners();
        return;
      } on FirebaseException catch (e) {
        debugPrint('Firestore favorites error: ${e.code} - ${e.message}');
      } catch (e) {
        debugPrint('Failed to load favorites from Firestore: $e');
      }
    }

    await _loadLocal();
  }

  Future<void> _saveFavoritesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites', json.encode(_favorites.map((movie) => movie.toJson()).toList()));
  }

  bool isFavorite(String id) {
    return _favorites.any((movie) => movie.id == id || movie.tmdbId == id);
  }

  Future<void> toggleFavorite(Movie movie) async {
    final userId = _auth.currentUser?.uid;
    final bool isAdding = !isFavorite(movie.id);

    if (isAdding) {
      _favorites.insert(0, movie);
    } else {
      _favorites.removeWhere((item) => item.id == movie.id || (item.tmdbId != null && item.tmdbId == movie.id) || (movie.tmdbId != null && item.id == movie.tmdbId));
    }
    notifyListeners();

    if (userId != null) {
      try {
        final normalized = movie.toJson();
        normalized['id'] ??= normalized['tmdbId'];

        final docRef = _db
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(normalized['id'].toString());

        if (isAdding) {
          await docRef.set({
            'movieDetails': normalized,
            'addedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await docRef.delete();
        }
      } on FirebaseException catch (e) {
        debugPrint('Firestore favorites sync error: ${e.code} - ${e.message}');
        await _saveFavoritesLocal();
      } catch (e) {
        debugPrint('Favorites sync error: $e');
        await _saveFavoritesLocal();
      }
    } else {
      await _saveFavoritesLocal();
    }
  }
}
