import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../providers/region_provider.dart';
import '../providers/feed_provider.dart';
import '../utils/trailer_helper.dart';
import 'feed_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  Map<String, dynamic>? details;
  bool isLoading = true;
  String? errorMessage;
  String? trailerKey;
  bool hasVoted = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await ApiService.fetchMovieDetailsFull(widget.movie.id);

      if (mounted) {
        setState(() {
          if (data != null) {
            details = Map<String, dynamic>.from(data);
            details!['isTv'] = false;

            // Find trailer key
            if (details!['videos'] != null && details!['videos']['results'] != null) {
              final videos = details!['videos']['results'] as List;
              for (var vid in videos) {
                if (vid['type'] == 'Trailer' && vid['site'] == 'YouTube') {
                  trailerKey = vid['key'];
                  break;
                }
              }
            }
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  void _showTrailer() {
    if (trailerKey == null) return;
    TrailerHelper.showTrailer(context, trailerKey!);
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final bgImage = movie.backdropImage ?? movie.posterImage ?? 'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&q=80&w=1280';

    final title = movie.displayTitle;
    final year = movie.displayYear;
    final voteAverage = movie.voteAverage != null ? movie.voteAverage!.toStringAsFixed(1) : 'N/A';
    final rtScore = movie.voteAverage != null ? (movie.voteAverage! * 10).round() : 'N/A';

    final feedProvider = Provider.of<FeedProvider>(context);
    final communityPosts = feedProvider.posts.where((post) {
      final query = title.toLowerCase();
      return post.title.toLowerCase().contains(query) || post.content.toLowerCase().contains(query);
    }).toList();
    
    // Sort by most likes to show most relevant
    communityPosts.sort((a, b) => b.likes.compareTo(a.likes));
    
    // Only show posts explicitly about this film
    final displayPosts = communityPosts.take(3).toList();

    final region = Provider.of<RegionProvider>(context).region;
    List<dynamic> flatrate = [];
    List<dynamic> buyRent = [];
    if (details != null && details!['watch/providers'] != null && details!['watch/providers']['results'] != null) {
      final providers = details!['watch/providers']['results'][region];
      if (providers != null) {
        if (providers['flatrate'] != null) flatrate = providers['flatrate'];
        if (providers['buy'] != null) buyRent.addAll(providers['buy']);
        if (providers['rent'] != null) buyRent.addAll(providers['rent']);
      }
    }

    bool inTheaters = false;
    if (movie.releaseDate != null && (details == null || details!['isTv'] != true)) {
      final releaseDateParsed = DateTime.tryParse(movie.releaseDate!);
      if (releaseDateParsed != null) {
        final diffDays = DateTime.now().difference(releaseDateParsed).inDays;
        if (diffDays <= 60 && diffDays >= 0) {
          inTheaters = true;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141414), // Dark background matching React app
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(bgImage, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, const Color(0xFF141414)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  if (trailerKey != null)
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(LucideIcons.play),
                        label: const Text('Play Trailer'),
                        onPressed: _showTrailer,
                      ),
                    )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFFF5C518),
                        child: Text('IMDb $voteAverage', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: Colors.red[800],
                        child: Text('🍅 $rtScore%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(LucideIcons.calendar, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(year, style: const TextStyle(color: Colors.white70)),
                      if (details != null && details!['isTv'] == true && details!['number_of_episodes'] != null) ...[
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.tv, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${details!['number_of_episodes']} Eps', style: const TextStyle(color: Colors.white70)),
                      ],
                      const Spacer(),
                      // VOTE BUTTON
                      GestureDetector(
                        onTap: () async {
                          if (hasVoted) return;
                          setState(() => hasVoted = true);
                          await ApiService.voteMovie(movie.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vote counted! This movie will trend faster.'), backgroundColor: Colors.green),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: hasVoted ? Colors.pinkAccent.withValues(alpha: 0.2) : Colors.pinkAccent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.pinkAccent),
                          ),
                          child: Row(
                            children: [
                              Icon(hasVoted ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(hasVoted ? 'Voted' : 'Vote to Trend', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.white))
                  else if (errorMessage != null)
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white54, size: 40),
                          const SizedBox(height: 8),
                          const Text('Failed to load movie details.', style: TextStyle(color: Colors.white54)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                                errorMessage = null;
                              });
                              _fetchDetails();
                            },
                            child: const Text('Retry', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (details!['genres'] != null)
                      Wrap(
                        spacing: 8,
                        children: (details!['genres'] as List).map<Widget>((g) {
                          return Chip(
                            label: Text(g['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: Colors.white24,
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    if (flatrate.isNotEmpty || buyRent.isNotEmpty || inTheaters) ...[
                      Text('Where to Watch ($region)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (inTheaters)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)),
                              child: Row(children: const [Icon(LucideIcons.ticket, color: Colors.white, size: 16), SizedBox(width: 4), Text('In Theaters', style: TextStyle(color: Colors.white))]),
                            ),
                          ...flatrate.take(4).map((provider) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network('https://image.tmdb.org/t/p/w200${provider['logo_path']}', width: 40, height: 40),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      movie.overview ?? 'No overview available.',
                      style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (details!['credits'] != null && details!['credits']['cast'] != null && (details!['credits']['cast'] as List).isNotEmpty) ...[
                      const Text('Top Cast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (details!['credits']['cast'] as List).take(5).length,
                          itemBuilder: (context, index) {
                            final actor = details!['credits']['cast'][index];
                            return Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundImage: actor['profile_path'] != null
                                        ? NetworkImage('https://image.tmdb.org/t/p/w200${actor['profile_path']}')
                                        : null,
                                    backgroundColor: Colors.white24,
                                    child: actor['profile_path'] == null ? const Icon(LucideIcons.user, color: Colors.white) : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    actor['name'],
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    ]
                  ],
                  const SizedBox(height: 32),
                  const Text('Community Discussions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  ...displayPosts.map((post) {
                    return GestureDetector(
                      onTap: () {
                        // Close movie details modal
                        Navigator.pop(context);
                        // Navigate to full community feed
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedScreen()));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white24,
                                  child: Text(post.authorName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                                const SizedBox(width: 8),
                                Text(post.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                const Spacer(),
                                Text(post.type.toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(post.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(post.content, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (displayPosts.isEmpty)
                     const Text('No community discussions yet. Be the first to post!', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
