class Movie {
  final String id;
  final String? tmdbId;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? posterUrl;
  final String? backdropPath;
  final String? backdropUrl;
  final String? releaseDate;
  final String? firstAirDate;
  final double? voteAverage;
  final bool isTv;
  final List<String> genres;
  final Map<String, dynamic> raw;

  Movie({
    required this.id,
    required this.title,
    this.tmdbId,
    this.overview,
    this.posterPath,
    this.posterUrl,
    this.backdropPath,
    this.backdropUrl,
    this.releaseDate,
    this.firstAirDate,
    this.voteAverage,
    this.isTv = false,
    List<String>? genres,
    Map<String, dynamic>? raw,
  })  : genres = genres ?? const [],
        raw = raw != null ? Map<String, dynamic>.unmodifiable(raw) : const {};

  String get displayTitle => title;

  String get displayYear {
    final value = releaseDate ?? firstAirDate;
    if (value != null && value.length >= 4) {
      return value.substring(0, 4);
    }
    return 'Unknown';
  }

  String? get posterImage {
    if (posterUrl != null && posterUrl!.isNotEmpty) {
      return posterUrl;
    }
    if (posterPath != null && posterPath!.isNotEmpty) {
      return posterPath!.startsWith('http')
          ? posterPath
          : 'https://image.tmdb.org/t/p/w500$posterPath';
    }
    return null;
  }

  String? get backdropImage {
    if (backdropUrl != null && backdropUrl!.isNotEmpty) {
      return backdropUrl;
    }
    if (backdropPath != null && backdropPath!.isNotEmpty) {
      return backdropPath!.startsWith('http')
          ? backdropPath
          : 'https://image.tmdb.org/t/p/w780$backdropPath';
    }
    return null;
  }

  Movie copyWith({
    String? id,
    String? tmdbId,
    String? title,
    String? overview,
    String? posterPath,
    String? posterUrl,
    String? backdropPath,
    String? backdropUrl,
    String? releaseDate,
    String? firstAirDate,
    double? voteAverage,
    bool? isTv,
    List<String>? genres,
    Map<String, dynamic>? raw,
  }) {
    return Movie(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropPath: backdropPath ?? this.backdropPath,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      firstAirDate: firstAirDate ?? this.firstAirDate,
      voteAverage: voteAverage ?? this.voteAverage,
      isTv: isTv ?? this.isTv,
      genres: genres ?? this.genres,
      raw: raw ?? this.raw,
    );
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    result.addAll(raw);
    result['id'] = id;
    if (tmdbId != null) result['tmdbId'] = tmdbId;
    result['title'] = title;
    if (overview != null) result['overview'] = overview;
    if (posterPath != null) result['poster_path'] = posterPath;
    if (posterUrl != null) result['poster_url'] = posterUrl;
    if (backdropPath != null) result['backdrop_path'] = backdropPath;
    if (backdropUrl != null) result['backdrop_url'] = backdropUrl;
    if (releaseDate != null) result['release_date'] = releaseDate;
    if (firstAirDate != null) result['first_air_date'] = firstAirDate;
    if (voteAverage != null) result['vote_average'] = voteAverage;
    result['isTv'] = isTv;
    if (genres.isNotEmpty) {
      result['genres'] = genres.map((name) => {'name': name}).toList();
    }
    return result;
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    final idValue = raw['id'] ?? raw['tmdbId'] ?? raw['movieId'];
    final posterPath = _stringOrNull(raw['poster_path']);
    final posterUrl = _stringOrNull(raw['poster_url']);
    final backdropPath = _stringOrNull(raw['backdrop_path']);
    final backdropUrl = _stringOrNull(raw['backdrop_url']);
    final firstAirDate = _stringOrNull(raw['first_air_date']);
    final releaseDate = _stringOrNull(raw['release_date']);
    final title = _stringOrNull(raw['title']) ?? _stringOrNull(raw['name']) ?? 'Unknown';
    final voteAverage = _parseDouble(raw['vote_average']);
    final isTv = raw['isTv'] == true || raw['media_type'] == 'tv' || raw['media_type'] == 'series' || firstAirDate != null;
    final genres = _extractGenreNames(raw['genres']);

    return Movie(
      id: idValue?.toString() ?? '',
      tmdbId: _stringOrNull(raw['tmdbId']) ?? (raw['tmdb_id'] != null ? raw['tmdb_id'].toString() : null),
      title: title,
      overview: _stringOrNull(raw['overview']),
      posterPath: posterPath,
      posterUrl: posterUrl,
      backdropPath: backdropPath,
      backdropUrl: backdropUrl,
      releaseDate: releaseDate,
      firstAirDate: firstAirDate,
      voteAverage: voteAverage,
      isTv: isTv,
      genres: genres,
      raw: raw,
    );
  }

  static List<Movie> listFromResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      final results = response['results'];
      if (results is List) {
        return results.map((item) => Movie.fromJson(_mapFromDynamic(item))).toList();
      }
    } else if (response is List) {
      return response.map((item) => Movie.fromJson(_mapFromDynamic(item))).toList();
    }
    return <Movie>[];
  }

  static List<String> _extractGenreNames(dynamic genresRaw) {
    if (genresRaw is List) {
      return genresRaw
          .where((genre) => genre != null)
          .map((genre) {
            if (genre is Map<String, dynamic>) {
              return _stringOrNull(genre['name']);
            }
            return genre?.toString();
          })
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static Map<String, dynamic> _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
