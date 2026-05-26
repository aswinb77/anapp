import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/movie.dart';

class HeroCarousel extends StatefulWidget {
  final Future<List<Movie>> Function() fetchFunc;
  final ValueChanged<Movie> onMovieClick;
  final bool isTv;

  const HeroCarousel({
    super.key,
    required this.fetchFunc,
    required this.onMovieClick,
    required this.isTv,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  List<Movie> items = [];
  bool isLoading = true;
  String? errorMessage;
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

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
          items = data
              .where((item) => item.backdropImage != null || item.posterImage != null)
              .take(6)
              .toList();
          isLoading = false;
        });
        _startAutoSlide();
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

  void _startAutoSlide() {
    if (items.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % items.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 250,
        child: Shimmer.fromColors(
          baseColor: Colors.white12,
          highlightColor: Colors.white24,
          child: Container(color: Colors.white),
        ),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 30),
              const SizedBox(height: 8),
              const Text('Failed to load hero items', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 8),
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

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final backdropUrl = item.backdropImage ?? item.posterImage ?? '';
              final title = item.displayTitle;

              return GestureDetector(
                onTap: () => widget.onMovieClick(item.copyWith(isTv: widget.isTv)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      backdropUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF141414).withOpacity(0.8),
                            const Color(0xFF141414),
                          ],
                          stops: const [0.5, 0.9, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 16,
                      right: 16,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.redAccent : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
