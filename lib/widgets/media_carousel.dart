import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/movie.dart';
import 'movie_card.dart';

class MediaCarouselSection extends StatefulWidget {
  final String title;
  final Future<List<Movie>> Function() fetchFunc;
  final ValueChanged<Movie> onMovieClick;
  final bool isTv;
  final String tag;

  const MediaCarouselSection({
    super.key,
    required this.title,
    required this.fetchFunc,
    required this.onMovieClick,
    required this.isTv,
    required this.tag,
  });

  @override
  State<MediaCarouselSection> createState() => _MediaCarouselSectionState();
}

class _MediaCarouselSectionState extends State<MediaCarouselSection> {
  List<Movie> items = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await widget.fetchFunc();
      if (mounted) {
        setState(() {
          items = data;
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Shimmer.fromColors(
              baseColor: Colors.white12,
              highlightColor: Colors.white24,
              child: Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.white12,
                    highlightColor: Colors.white24,
                    child: Container(
                      width: 140,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white54, size: 24),
                    const SizedBox(height: 8),
                    const Text('Failed to load', style: TextStyle(color: Colors.white54)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          errorMessage = null;
                        });
                        _loadData();
                      },
                      child: const Text('Retry', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final movie = items[index].copyWith(isTv: widget.isTv);
              
              int? displayRank;
              if (widget.title.contains('Trending') || widget.title.contains('Popular')) {
                displayRank = index + 1;
              }

              return MovieCard(
                movie: movie,
                onClick: widget.onMovieClick,
                tag: widget.tag,
                rank: displayRank,
              );
            },
          ),
        ),
      ],
    );
  }
}
