import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';

class MarqueeSection extends StatefulWidget {
  final Future<List<Movie>> Function() fetchFunc;
  final ValueChanged<Movie> onMovieClick;
  final bool isTv;

  const MarqueeSection({
    super.key,
    required this.fetchFunc,
    required this.onMovieClick,
    required this.isTv,
  });

  @override
  State<MarqueeSection> createState() => _MarqueeSectionState();
}

class _MarqueeSectionState extends State<MarqueeSection> {
  List<Movie> items = [];
  bool isLoading = true;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoScroll();
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

  void _startAutoScroll() {
    if (items.isEmpty) return;
    const duration = Duration(milliseconds: 30);
    _timer = Timer.periodic(duration, (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        const double delta = 1.0; // scroll speed

        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentScroll + delta);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 24),
              const SizedBox(height: 8),
              const Text('Failed to load marquee', style: TextStyle(color: Colors.white54)),
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
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayItems = [...items, ...items, ...items, ...items, ...items];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            'Now in Theaters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              final imageUrl = item.backdropImage ?? item.posterImage;
              if (imageUrl == null || imageUrl.isEmpty) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () => widget.onMovieClick(item.copyWith(isTv: widget.isTv)),
                child: Container(
                  width: 110,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 16.0 : 0,
                    right: 12.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
