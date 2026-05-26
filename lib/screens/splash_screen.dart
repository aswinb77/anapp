import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';

import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/favorites_provider.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Always show splash for at least 2s for branding
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // checkAuth has a hard 5s timeout so it never hangs forever
      await userProvider.checkAuth().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Timeout or error — treat as unauthenticated
    }

    if (!mounted) return;

    if (userProvider.isAuthenticated) {
      // Kick off data loading AFTER we know the user is signed in
      Provider.of<FeedProvider>(context, listen: false).fetchPosts();
      Provider.of<FavoritesProvider>(context, listen: false).reload();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigation(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'movie.cc',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1.5,
              ),
            )
            .animate()
            .fade(duration: 800.ms)
            .scale(delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 16),
            
            const Text(
              'Discover. Share. Watch.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.redAccent,
                letterSpacing: 2,
              ),
            )
            .animate()
            .fade(delay: 1000.ms, duration: 800.ms)
            .slideY(begin: 0.5, end: 0, delay: 1000.ms, duration: 800.ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
