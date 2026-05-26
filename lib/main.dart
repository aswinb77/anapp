import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'providers/connectivity_provider.dart';
import 'providers/region_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/feed_screen.dart';
import 'screens/offline_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/chat_screen.dart';

// ── App colors ────────────────────────────────────────────────────────────────
abstract final class AppColors {
  static const background = Color(0xFF141414);
  static const navBar     = Color(0xFF1A1A1A);
  static const chipBg     = Color(0xFFE8E8E8);
  static const chipIcon   = Color(0xFF111111);
  static const iconIdle   = Color(0xFF555555);
  static const badge      = Color(0xFF52C97A); // Green notification badge
}

// ── Nav item model ────────────────────────────────────────────────────────────
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    this.showBadge = false,
  });

  final IconData icon;
  final String   label;
  final Widget   screen;
  final bool     showBadge;
}

// ── Entry point ───────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegionProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProxyProvider<UserProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, userProvider, notifier) => notifier!..watchUser(userProvider.userId),
        ),
        ChangeNotifierProxyProvider<UserProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, userProvider, chatProvider) => chatProvider!..updateUser(userProvider.userId, userProvider.username),
        ),
      ],
      child: const MovieccApp(),
    ),
  );
}

// ── Root app ──────────────────────────────────────────────────────────────────
class MovieccApp extends StatelessWidget {
  const MovieccApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'movie.cc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.redAccent,
          surface: AppColors.background,
        ),
        fontFamily: 'Inter',
      ),
      builder: (context, child) {
        final connectivity = context.watch<ConnectivityProvider>();
        if (connectivity.isOffline) {
          return NoInternetScreen(
            onRetry: connectivity.refresh,
          );
        }
        return child ?? const SizedBox.shrink();
      },
      home: const SplashScreen(),
    );
  }
}

// ── Main navigation ───────────────────────────────────────────────────────────
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Screens kept alive by IndexedStack — scroll positions preserved automatically.
  static const List<Widget> _screens = [
    DiscoverScreen(),
    FeedScreen(),
    ChatScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    if (index == 2) {
      context.read<ChatProvider>().markChatSeen();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final chatProvider = context.watch<ChatProvider>();
    
    final showFeedBadge = notificationProvider.unreadCount > 0 && _currentIndex != 1;
    final showChatBadge = chatProvider.unreadCount > 0 && _currentIndex != 2;

    final tabs = [
      const _NavItem(icon: LucideIcons.home,         label: 'Home',      screen: DiscoverScreen()),
      _NavItem(      icon: LucideIcons.users,         label: 'Community', screen: const FeedScreen(),      showBadge: showFeedBadge),
      _NavItem(      icon: LucideIcons.messageSquare, label: 'Chat',      screen: const ChatScreen(),      showBadge: showChatBadge),
      const _NavItem(icon: LucideIcons.heart,         label: 'Favorites', screen: FavoritesScreen()),
      const _NavItem(icon: LucideIcons.user,          label: 'Profile',   screen: ProfileScreen()),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: _MorphingNavBar(
          tabs: tabs,
          currentIndex: _currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}

// ── Morphing nav bar ──────────────────────────────────────────────────────────
class _MorphingNavBar extends StatelessWidget {
  const _MorphingNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> tabs;
  final int            currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.navBar,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(tabs.length, (i) {
            return _NavChip(
              item: tabs[i],
              isActive: i == currentIndex,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

// ── Individual nav chip ───────────────────────────────────────────────────────
class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool     isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.chipBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: _BadgeWrapper(
          showBadge: item.showBadge,
          child: Icon(
            item.icon,
            size: 20,
            color: isActive ? AppColors.chipIcon : AppColors.iconIdle,
          ),
        ),
      ),
    );
  }
}

// ── Red dot badge ─────────────────────────────────────────────────────────────
class _BadgeWrapper extends StatelessWidget {
  const _BadgeWrapper({required this.showBadge, required this.child});

  final bool   showBadge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.badge,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}