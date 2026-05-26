import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../providers/favorites_provider.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final ValueChanged<Movie> onClick;
  final String? tag;
  final bool isGrid;
  final int? rank;

  const MovieCard({
    super.key,
    required this.movie,
    required this.onClick,
    this.tag,
    this.isGrid = false,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    // Support both TMDB shape (poster_path, id) and backend shape (poster_url, tmdbId)
    final rawPoster = movie.posterImage;
    final String bgImage;
    if (rawPoster == null || rawPoster.isEmpty) {
      bgImage = 'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&q=80&w=300';
    } else {
      bgImage = rawPoster;
    }

    final title = movie.displayTitle;
    final year = movie.displayYear;
    final voteAverage = movie.voteAverage != null
        ? movie.voteAverage!.toStringAsFixed(1)
        : 'N/A';
    final movieId = movie.id;

    return GestureDetector(
      onTap: () => onClick(movie),
      child: Container(
        width: isGrid ? null : 160,
        margin: EdgeInsets.only(right: isGrid ? 0 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(bgImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Play overlay logic
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.transparent, const Color(0xCC000000)], // 0.8 opacity black
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            if (rank != null && rank! <= 10)
              Positioned(
                bottom: -25,
                left: -10,
                child: Stack(
                  children: [
                    // Stroke
                    Text(
                      rank.toString(),
                      style: TextStyle(
                        fontSize: 130,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 4
                          ..color = Colors.white,
                      ),
                    ),
                    // Fill
                    Text(
                      rank.toString(),
                      style: const TextStyle(
                        fontSize: 130,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            if (tag != null)
              Positioned(
                top: 8,
                left: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.0),
                      ),
                      child: Text(
                        tag!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, child) {
                  final isFav = favoritesProvider.isFavorite(movieId);
                  return GestureDetector(
                    onTap: () => favoritesProvider.toggleFavorite(movie),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0x80000000), // 0.5 opacity black
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isFav ? Colors.pinkAccent : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5C518),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'IMDb',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        voteAverage,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const Spacer(),
                      const Icon(LucideIcons.calendar, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        year,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
