import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  // YOUR server — TMDB key is gone from this file forever
  static const String baseUrl =
      'https://asia-south1-movie-2e707.cloudfunctions.net';

  static Future<dynamic> _get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/$path'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  static List<Movie> _parseMovieList(dynamic payload) {
    return Movie.listFromResponse(payload);
  }

  static Future<List<Movie>> fetchTrendingMovies({String? lang}) async {
    final l = lang ?? 'ml';
    final response = await _get('getTrending?lang=$l');
    return _parseMovieList(response);
  }

  static Future<List<Movie>> fetchPopularMovies({String? lang}) async {
    final l = lang ?? 'ml';
    final response = await _get('getPopular?lang=$l');
    return _parseMovieList(response);
  }

  static Future<List<Movie>> fetchNowPlayingMovies({String? lang}) async {
    final l = lang ?? 'ml';
    final response = await _get('getNowPlaying?lang=$l');
    return _parseMovieList(response);
  }

  static Future<List<Movie>> fetchUpcomingMovies({String? lang}) async {
    final l = lang ?? 'ml';
    final response = await _get('getUpcoming?lang=$l');
    return _parseMovieList(response);
  }

  static Future<Map<String, dynamic>?> fetchMovieDetailsFull(String id) async {
    final response = await _get('getMovie?id=$id');
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  static Future<List<Movie>> searchMovies(String query) async {
    final q = Uri.encodeComponent(query);
    final response = await _get('searchMovies?q=$q');
    return _parseMovieList(response);
  }

  static Future<bool> voteMovie(String id) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/voteMovie'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'id': id}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return true;
      }
      throw ApiException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to vote: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserStatus(String uid) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/getUserStatus?uid=$uid'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(res.body));
      }
    } catch (e) {
      // ignore
    }
    return {'can_post': true, 'restricted': false}; // default allow if check fails
  }
}
