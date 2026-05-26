import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../providers/favorites_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/movie_card.dart';
import 'movie_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload from backend every time this tab is opened, once per session change
    if (!_fetched) {
      _fetched = true;
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId != null) {
        Provider.of<FavoritesProvider>(context, listen: false).reload();
      }
    }
  }

  void _openDetails(Movie movie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: MovieDetailsScreen(movie: movie),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          final favorites = favoritesProvider.favorites;

          return RefreshIndicator(
            color: Colors.pinkAccent,
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: () async {
              favoritesProvider.reload();
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFF141414),
                  title: Row(
                  children: [
                    const Text(
                      'My Favorites',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (favorites.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${favorites.length}',
                          style: const TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                floating: true,
                actions: [
                  if (favorites.isNotEmpty)
                    IconButton(
                      onPressed: () => favoritesProvider.reload(),
                      icon: const Icon(LucideIcons.refreshCw, color: Colors.white54, size: 18),
                    ),
                ],
              ),
              if (favorites.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.favorite_border, size: 36, color: Colors.pinkAccent),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No favorites yet',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap ♥ on any movie to save it here.',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = favorites[index];
                        return Stack(
                          children: [
                            MovieCard(
                              movie: movie,
                              onClick: _openDetails,
                              isGrid: true,
                            ),
                          ],
                        );
                      },
                      childCount: favorites.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                  ),
                ),
            ],
          ),
          );
        },
      ),
    );
  }
}
