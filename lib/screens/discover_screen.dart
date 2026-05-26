import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../providers/user_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../widgets/media_carousel.dart';
import '../widgets/marquee_section.dart';
import '../widgets/movie_card.dart';
import '../widgets/hero_carousel.dart';
import 'movie_details_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Movie>? searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.isNotEmpty) {
      setState(() => _isSearching = true);
      _debounce = Timer(const Duration(milliseconds: 400), () async {
        try {
          final results = await ApiService.searchMovies(query);
          if (mounted) {
            setState(() {
              searchResults = results;
              _isSearching = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              searchResults = [];
              _isSearching = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Search failed: Please check your connection')),
            );
          }
        }
      });
    } else {
      setState(() {
        searchResults = null;
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchResults = null;
      _isSearching = false;
    });
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
    final userProvider = context.watch<UserProvider>();
    final favProvider  = context.watch<FavoritesProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: const Color(0xFF141414),
            floating: true,
            snap: true,
            centerTitle: false,
            title: Row(
              children: [
                const Text(
                  'movie.cc',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.mapPin, size: 12, color: Colors.redAccent),
                      SizedBox(width: 4),
                      Text('Kerala', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Favorites badge
              GestureDetector(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.favorite_border, color: Colors.white70),
                      ),
                      if (favProvider.favorites.isNotEmpty)
                        Positioned(
                          right: 4, top: 4,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.pinkAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${favProvider.favorites.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // User avatar
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.7),
                  backgroundImage: userProvider.selectedAvatar != null
                      ? AssetImage(userProvider.selectedAvatar!)
                      : null,
                  child: userProvider.selectedAvatar == null
                      ? Text(
                          (userProvider.username != null && userProvider.username!.isNotEmpty)
                              ? userProvider.username![0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: Colors.white12),
            ),
          ),

          // ── Hero text + search bar ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Movies at\nyour fingertips.',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Discover the best of Malayalam Cinema.',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 18),
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search, color: Colors.white38, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Search movies…',
                              hintStyle: TextStyle(color: Colors.white30),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: _clearSearch,
                            child: const Icon(LucideIcons.x, color: Colors.white38, size: 18),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          if (_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: Colors.white12,
                      highlightColor: Colors.white24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else if (searchResults != null)
            // Search results grid
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        const Text(
                          'Results',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${searchResults!.length}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (searchResults!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No results found', style: TextStyle(color: Colors.white38)),
                      ),
                    )
                  else
                    GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: searchResults!.length,
                      itemBuilder: (context, index) {
                        final item = searchResults![index];
                        return MovieCard(movie: item, onClick: _openDetails, isGrid: true);
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            )
          else
            // Native scrolling for the carousels
            SliverList(
              delegate: SliverChildListDelegate([
                HeroCarousel(
                  fetchFunc: () => ApiService.fetchTrendingMovies(lang: 'ml'),
                  onMovieClick: _openDetails,
                  isTv: false,
                  key: const ValueKey('hero_ml'),
                ),
                MarqueeSection(
                  fetchFunc: () => ApiService.fetchNowPlayingMovies(lang: 'ml'),
                  onMovieClick: _openDetails,
                  isTv: false,
                  key: const ValueKey('now_ml'),
                ),
                MediaCarouselSection(
                  title: '🔥 Trending',
                  fetchFunc: () => ApiService.fetchTrendingMovies(lang: 'ml'),
                  onMovieClick: _openDetails,
                  isTv: false,
                  tag: 'Trending',
                  key: const ValueKey('trend_ml'),
                ),
                MediaCarouselSection(
                  title: '🌟 Popular',
                  fetchFunc: () => ApiService.fetchPopularMovies(lang: 'ml'),
                  onMovieClick: _openDetails,
                  isTv: false,
                  tag: 'Hot',
                  key: const ValueKey('pop_ml'),
                ),
                MediaCarouselSection(
                  title: '🗓️ Upcoming',
                  fetchFunc: () => ApiService.fetchUpcomingMovies(lang: 'ml'),
                  onMovieClick: _openDetails,
                  isTv: false,
                  tag: 'Upcoming',
                  key: const ValueKey('up_ml'),
                ),
                const SizedBox(height: 100), // padding at bottom for nav bar
              ]),
            ),
        ],
      ),
    );
  }
}
