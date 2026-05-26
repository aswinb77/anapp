import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/movie.dart';
import '../providers/feed_provider.dart';
import '../providers/user_provider.dart';
import '../providers/favorites_provider.dart';
import 'splash_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums & lightweight models
// ─────────────────────────────────────────────────────────────────────────────

enum League { bronze, silver, gold, platinum, diamond, legend }

/// Maps a raw genre string to a display colour.
/// Add more genres here as needed.
Color genreColor(String genre) => switch (genre.toLowerCase()) {
  'thriller'  => const Color(0xFF8B7FE8),
  'drama'     => const Color(0xFF5DCAA5),
  'sci-fi'    => const Color(0xFF7EAFD4),
  'comedy'    => const Color(0xFFEF9F27),
  'horror'    => const Color(0xFFE05C5C),
  'romance'   => const Color(0xFFE0719A),
  'action'    => const Color(0xFFE08C42),
  'animation' => const Color(0xFF6EC6E8),
  _           => const Color(0x73FFFFFF),
};

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF111111);
  static const _surface = Color(0xFF171717);
  static const _divider = Color(0xFF1E1E1E);

  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecond  = Color(0xCCFFFFFF);
  static const _textMuted   = Color(0x73FFFFFF);
  static const _textDim     = Color(0x40FFFFFF);

  static const _amber   = Color(0xFFEF9F27);
  static const _purple  = Color(0xFF8B7FE8);
  static const _blue    = Color(0xFF7EAFD4);

  // Post-type tag colours
  static const _colReview = _blue;
  static const _colList   = Color(0xFF5DCAA5);
  static const _colPoll   = _amber;

  // ── "More posts" toggle ───────────────────────────────────────────────────
  bool _showAllPosts = false;

  // ── League helpers ────────────────────────────────────────────────────────
  League _getLeague(int exp) {
    if (exp >= 10000) return League.legend;
    if (exp >= 5000) return League.diamond;
    if (exp >= 2000) return League.platinum;
    if (exp >= 1000) return League.gold;
    if (exp >= 200)  return League.silver;
    return League.bronze;
  }

  String   _leagueName(League l)   => ['Bronze','Silver','Gold','Platinum','Diamond','Legend'][l.index];
  IconData _leagueIcon(League l)   => [
    LucideIcons.shield, LucideIcons.shieldCheck,
    LucideIcons.star,   LucideIcons.gem,
    LucideIcons.award,  LucideIcons.crown,
  ][l.index];
  int _nextThreshold(League l) => [200, 1000, 2000, 5000, 10000, 10000][l.index];
  int _prevThreshold(League l) => [0,   200,  1000, 2000, 5000,  10000][l.index];

  // ── Derived data from cinemaVisits ────────────────────────────────────────

  /// Counts per genre, sorted descending.
  Map<String, int> _genreMap(List<Movie> favorites) {
    final map = <String, int>{};
    for (final movie in favorites) {
      for (final genre in movie.genres) {
        final normalized = genre.trim();
        if (normalized.isEmpty) continue;
        map[normalized] = (map[normalized] ?? 0) + 1;
      }
    }
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }




  // ── Tag colour helper ─────────────────────────────────────────────────────
  Color _tagColor(String type) => switch (type.toLowerCase()) {
    'list' => _colList,
    'poll' => _colPoll,
    _      => _colReview,
  };

  // ── Avatar picker ─────────────────────────────────────────────────────────
  final List<String> _avatars = [
    'assets/1.png','assets/2.png','assets/3.png','assets/4.png',
    'assets/5.png','assets/6.png','assets/7.png','assets/8.png','assets/10.png',
  ];

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose avatar',
              style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14, runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Provider.of<UserProvider>(ctx, listen: false).setAvatar(null);
                    Navigator.pop(ctx);
                  },
                  child: _avatarCircle(null, '?'),
                ),
                ..._avatars.map((a) => GestureDetector(
                  onTap: () {
                    Provider.of<UserProvider>(ctx, listen: false).setAvatar(a);
                    Navigator.pop(ctx);
                  },
                  child: _avatarCircle(a, null),
                )),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _avatarCircle(String? path, String? fallbackLabel) => CircleAvatar(
    radius: 28,
    backgroundColor: const Color(0xFF1E1E1E),
    backgroundImage: path != null ? AssetImage(path) : null,
    child: path == null
        ? Text(fallbackLabel ?? '?', style: TextStyle(fontSize: 20, color: _textMuted))
        : null,
  );

  // ── Delete confirmation ───────────────────────────────────────────────────
  void _confirmDelete(BuildContext ctx, FeedProvider fp, String postId) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete post', style: TextStyle(color: _textPrimary)),
        content: const Text(
          'This post will be permanently removed.',
          style: TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () { fp.deletePost(postId); Navigator.pop(dCtx); },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final favProvider  = Provider.of<FavoritesProvider>(context);

    // All real data derived from provider
    final favorites = favProvider.favorites;
    final userPosts = feedProvider.posts
        .where((p) => p.authorName == 'You' || p.authorName == userProvider.username || p.authorId == userProvider.userId)
        .toList();
        
    // Calculate EXP dynamically from likes (50 EXP per like)
    int exp = 0;
    for (final post in userPosts) {
      exp += (post.likes * 50);
    }

    final league    = _getLeague(exp);
    final genreMap  = _genreMap(favorites);

    // Joined date string
    final joinedAt  = userProvider.joinedAt;
    final joinedStr = joinedAt != null
        ? 'joined ${_formatMonth(joinedAt)}'
        : '';

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(userProvider),

          SliverToBoxAdapter(
            child: _buildHeroBanner(userProvider, league, genreMap, joinedStr),
          ),
          SliverToBoxAdapter(
            child: _buildStatsRibbon(userPosts.length, exp, favorites.length),
          ),
          SliverToBoxAdapter(
            child: _buildBody(
              context, feedProvider, userPosts,
              exp, league, favorites, genreMap,
            ),
          ),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(UserProvider userProvider) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _bg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, size: 20),
        color: _textMuted,
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'my profile',
        style: TextStyle(
          color: _textMuted, fontSize: 12,
          fontWeight: FontWeight.w500, letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.logOut, size: 20),
          color: Colors.redAccent,
          onPressed: () async {
            await userProvider.logout();
            if (mounted) {
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
              );
            }
          },
        ),
      ],
    );
  }



  // ── Hero banner ───────────────────────────────────────────────────────────
  // A vibrant, eye-catching hero banner replacing the basic version.
  Widget _buildHeroBanner(
    UserProvider userProvider,
    League league,
    Map<String, int> genreMap,
    String joinedStr,
  ) {
    final topGenres   = genreMap.keys.take(3).toList();
    final lockedCount = (genreMap.keys.length - 3).clamp(0, 99);
    final username = userProvider.username ?? 'You';
    final initial  = username.isNotEmpty ? username[0].toUpperCase() : 'Y';
    
    // Choose a dominant colour for the banner based on top genre
    final Color dominantColor = topGenres.isNotEmpty ? genreColor(topGenres.first) : _purple;

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: const Border(bottom: BorderSide(color: _divider, width: 0.5)),
      ),
      child: Stack(
        children: [
          // Vibrant background glow
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [dominantColor.withValues(alpha: 0.25), Colors.transparent],
                ),
                boxShadow: [
                  BoxShadow(color: dominantColor.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 20),
                ]
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing Avatar
                GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dominantColor.withValues(alpha: 0.4),
                          blurRadius: 20, spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _bg, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: const Color(0xFF1C1C1C),
                        backgroundImage: userProvider.selectedAvatar != null
                            ? AssetImage(userProvider.selectedAvatar!)
                            : null,
                        child: userProvider.selectedAvatar == null
                            ? Text(initial, style: TextStyle(fontSize: 28, color: _textMuted))
                            : null,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700, color: _textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${username.toLowerCase()}${joinedStr.isNotEmpty ? ' · $joinedStr' : ''}',
                        style: TextStyle(fontSize: 12, color: _textDim, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),

                      // Vibrant Taste Pills
                      if (topGenres.isNotEmpty)
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: [
                            ...topGenres.map((genre) {
                              final c = genreColor(genre);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [c.withValues(alpha: 0.2), c.withValues(alpha: 0.05)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: c.withValues(alpha: 0.4), width: 1),
                                ),
                                child: Text(
                                  genre.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9, color: c, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                                  ),
                                ),
                              );
                            }),
                            if (lockedCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF333333), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.plus, size: 10, color: _textDim),
                                    const SizedBox(width: 2),
                                    Text('$lockedCount', style: TextStyle(fontSize: 10, color: _textDim, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                          ],
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ribbon — all real numbers ──────────────────────────────────────
  Widget _buildStatsRibbon(
    int postCount,
    int exp,
    int favCount,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider, width: 0.5)),
      ),
      child: Row(
        children: [
          _StatCell(value: '$favCount',  label: 'favorites'),
          _StatCell(value: '$exp',       label: 'exp earned'),
          _StatCell(value: '$postCount', label: 'posts', divider: false),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(
    BuildContext context,
    FeedProvider feedProvider,
    List<dynamic> userPosts,
    int exp,
    League league,
    List<Movie> favorites,
    Map<String, int> genreMap,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cinephile identity — always shown (has its own empty state)
          _buildCinephileIdentityCard(league, exp, genreMap),
          const SizedBox(height: 9),
          // User's own posts
          _buildPostsSection(context, feedProvider, userPosts),
        ],
      ),
    );
  }


  // ── Cinephile identity card ───────────────────────────────────────────────
  // Genre bars computed from real scan data.
  // Empty state when no scans yet.
  Widget _buildCinephileIdentityCard(League league, int exp, Map<String, int> genreMap) {
    final nextExp  = _nextThreshold(league);
    final prevExp  = _prevThreshold(league);
    final progress = nextExp == prevExp
        ? 1.0
        : ((exp - prevExp) / (nextExp - prevExp)).clamp(0.0, 1.0);

    // Rank title scales with league
    final rankTitle = ['Newcomer', 'Cinephile', 'Auteur', 'Visionary', 'Maestro', 'Legend'][league.index];

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('CINEPHILE IDENTITY'),
          const SizedBox(height: 10),
          // Rank row
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B7FE8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: const Color(0xFF8B7FE8).withValues(alpha: 0.25), width: 0.5,
                  ),
                ),
                child: Icon(_leagueIcon(league), size: 17, color: const Color(0xFF8B7FE8)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rankTitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, color: _textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    _leagueName(league),
                    style: TextStyle(fontSize: 10, color: const Color(0xFF3A3A3A)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // XP bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1E1E1E),
              valueColor: const AlwaysStoppedAnimation(_textPrimary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$exp exp', style: TextStyle(fontSize: 9, color: _textDim)),
              Text(
                '$nextExp for ${_leagueName(League.values[(league.index + 1).clamp(0, 4)])}',
                style: TextStyle(fontSize: 9, color: _textDim),
              ),
            ],
          ),
          const SizedBox(height: 11),
                  ],
      ),
    );
  }


  // ── Posts section ─────────────────────────────────────────────────────────
  Widget _buildPostsSection(
    BuildContext context,
    FeedProvider feedProvider,
    List<dynamic> userPosts,
  ) {
    const pageSize  = 4;
    final visible   = _showAllPosts ? userPosts : userPosts.take(pageSize).toList();
    final remaining = (userPosts.length - pageSize).clamp(0, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your posts',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecond)),
            Text('${userPosts.length} posts',
                style: TextStyle(fontSize: 11, color: _textDim)),
          ],
        ),
        const SizedBox(height: 9),
        if (userPosts.isEmpty)
          _buildEmptyPostsState()
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.80,
            ),
            itemCount: visible.length,
            itemBuilder: (ctx, i) => _buildPostCard(ctx, feedProvider, visible[i])
                .animate()
                .fadeIn(duration: 250.ms, delay: (200 + i * 50).ms)
                .slideY(begin: 0.06),
          ),
          const SizedBox(height: 7),
          if (!_showAllPosts && remaining > 0)
            GestureDetector(
              onTap: () => setState(() => _showAllPosts = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: _divider, width: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.moreHorizontal, size: 13, color: _textDim),
                    const SizedBox(width: 5),
                    Text('$remaining more posts',
                        style: TextStyle(fontSize: 11, color: _textDim)),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildEmptyPostsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.ticket, color: _textDim, size: 32),
          const SizedBox(height: 10),
          Text('No posts yet',
              style: TextStyle(color: _textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Share your first movie take',
              style: TextStyle(fontSize: 12, color: _textDim)),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, FeedProvider fp, dynamic post) {
    final tagColor = _tagColor(post.type as String);
    final isPoll   = (post.type as String).toLowerCase() == 'poll';

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _divider, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2, color: tagColor.withValues(alpha: 0.5)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: tagColor.withValues(alpha: 0.22), width: 0.5),
                        ),
                        child: Text(
                          (post.type as String).toUpperCase(),
                          style: TextStyle(
                              fontSize: 8, color: tagColor,
                              fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDelete(context, fp, post.id as String),
                        child: Icon(LucideIcons.trash2, size: 13, color: _textDim),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.title as String,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: _textSecond, height: 1.35),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      post.content as String,
                      style: TextStyle(fontSize: 10, color: _textDim, height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Engagement row — real like/comment counts from post model
                  Row(
                    children: isPoll
                        ? [
                            Icon(LucideIcons.barChart2, size: 11, color: _textDim),
                            const SizedBox(width: 3),
                            Text('${post.likes ?? 0} votes',
                                style: TextStyle(fontSize: 9, color: _textDim)),
                          ]
                        : [
                            Icon(LucideIcons.heart, size: 11, color: _textDim),
                            const SizedBox(width: 3),
                            Text('${post.likes ?? 0}',
                                style: TextStyle(fontSize: 9, color: _textDim)),
                            const SizedBox(width: 8),
                            Icon(LucideIcons.messageCircle, size: 11, color: _textDim),
                            const SizedBox(width: 3),
                            Text('${post.comments ?? 0}',
                                style: TextStyle(fontSize: 9, color: _textDim)),
                          ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatMonth(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Reusable sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF171717),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFF222222), width: 0.5),
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 9, color: Color(0x38FFFFFF), letterSpacing: 0.8,
    ),
  );
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value, required this.label, this.divider = true,
  });
  final String value;
  final String label;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: divider
              ? const Border(right: BorderSide(color: Color(0xFF1E1E1E), width: 0.5))
              : null,
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: Color(0xFF333333), letterSpacing: 0.4)),
          ],
        ),
      ),
    );
  }
}