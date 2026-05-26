import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/feed_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';
import 'publish_screen.dart';
import 'notifications_screen.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../utils/trailer_helper.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0A0B);
  static const surface     = Color(0xFF111318);
  static const divider     = Color(0xFF1F1F22);
  static const inputFill   = Color(0xFF1A1A1D);

  static const textPrimary = Color(0xFFE8EAED);
  static const textSub     = Color(0xFF7A8A9A);
  static const textMuted   = Color(0xFF3D4F62);
  static const textSecond  = Color(0xFFD0D4DA);

  // accent — steel blue (matches chat screen)
  static const Color accent     = Color(0xFF7eafd4);
  static const Color accentDark = Color(0xFF1e3d5c);

  // badge fills / text
  static const badgeNewsBg    = Color(0xFF1A2530);
  static const badgeNewsText  = Color(0xFF5A8AAA);
  static const badgeTrlrBg   = Color(0xFF1A2035);
  static const badgeTrlrText = Color(0xFF5A6AAA);
  static const badgeLeakBg   = Color(0xFF251E14);
  static const badgeLeakText = Color(0xFF8A7040);

  // trailer button
  static const trailerBorder = Color(0xFF2A3D52);
  static const trailerText   = Color(0xFF7AAAC8);

  // like active
  static const likeActive    = Color(0xFFC0506A);

  // bottom sheet
  static const sheetBg      = Color(0xFF111113);
  static const handleColor   = Color(0xFF2A2A2E);
}
// ──────────────────────────────────────────────────────────────────────────

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedProvider         = Provider.of<FeedProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        color: _C.accent,
        backgroundColor: _C.surface,
        onRefresh: () async {
          feedProvider.fetchPosts();
        },
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _C.bg,
            surfaceTintColor: Colors.transparent,
            floating: true,
            centerTitle: false,
            elevation: 0,
            title: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'movie',
                    style: TextStyle(
                      color: _C.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: '.',
                    style: TextStyle(
                      color: _C.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: 'cc',
                    style: TextStyle(
                      color: _C.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: _C.divider),
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bell, color: _C.textMuted, size: 19),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _C.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.bg, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (feedProvider.posts.isEmpty && feedProvider.isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const _PostSkeleton(),
                childCount: 3,
              ),
            )
          else if (feedProvider.posts.isEmpty && !feedProvider.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Text('No posts yet.', style: TextStyle(color: _C.textMuted)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post   = feedProvider.posts[index];
                  final isLast = index == feedProvider.posts.length - 1;
                  return _PostItem(post: post, provider: feedProvider, isLast: isLast);
                },
                childCount: feedProvider.posts.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublishScreen()),
            );
            return;
          }

          final status = await ApiService.getUserStatus(uid);

          if (status['restricted'] == true) {
            if (!context.mounted) return;
            showDialog(context: context, builder: (_) => AlertDialog(
              backgroundColor: _C.surface,
              title: const Text('Account Restricted', style: TextStyle(color: _C.textPrimary)),
              content: const Text(
                'Your account has been restricted due to repeated sharing of '
                'misleading content. Please contact support to appeal.',
                style: TextStyle(color: _C.textSub),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: _C.accent)))],
            ));
            return;
          }

          if (status['can_post'] == false) {
            if (!context.mounted) return;
            showDialog(context: context, builder: (_) => AlertDialog(
              backgroundColor: _C.surface,
              title: const Text('Posting Suspended', style: TextStyle(color: _C.textPrimary)),
              content: const Text(
                'Your posting privilege has been suspended due to sharing '
                'unverified content. You can still view and use other features.',
                style: TextStyle(color: _C.textSub),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: _C.accent)))],
            ));
            return;
          }

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PublishScreen()),
          );
        },
        backgroundColor: _C.accentDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Icon(LucideIcons.plus, color: _C.accent, size: 20),
      ),
    );
  }
}

// ── Post Item ────────────────────────────────────────────────────────────────

class _PostItem extends StatelessWidget {
  final dynamic      post;
  final FeedProvider provider;
  final bool         isLast;

  const _PostItem({
    required this.post,
    required this.provider,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final isMe = post.authorName == userProvider.username || post.authorName == 'You' || post.authorId == userProvider.userId;
                      final effectiveAvatar = post.authorId == 'system' 
                          ? 'assets/admin.png' 
                          : (isMe ? userProvider.selectedAvatar : null);
                      return _Avatar(name: post.authorName, avatarAsset: effectiveAvatar);
                    },
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            color: _C.textSecond,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '· ${_timeAgo(post.createdAt)}',
                          style: const TextStyle(
                            color: _C.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                             if (post.authorId == null || userProvider.userId == post.authorId || userProvider.userId == null || post.authorId == 'system') {
                               return const SizedBox();
                             }
                             final isFollowing = userProvider.following.contains(post.authorId);
                             return GestureDetector(
                               onTap: () {
                                 HapticFeedback.lightImpact();
                                 userProvider.toggleFollow(post.authorId);
                               },
                               child: Text(
                                 isFollowing ? 'Unfollow' : 'Follow',
                                 style: TextStyle(
                                   color: isFollowing ? _C.textMuted : _C.accent,
                                   fontSize: 12,
                                   fontWeight: FontWeight.w600,
                                 )
                               )
                             );
                          }
                        ),
                      ],
                    ),
                  ),
                  if (post.isVerifiedNews) _buildVerifiedBadge() else _TypeBadge(type: post.type),
                ],
              ),
              const SizedBox(height: 10),

              // ── Title ────────────────────────────────────────────────────
              Text(
                post.title,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 4),

              // ── Body ─────────────────────────────────────────────────────
              Text(
                post.content,
                style: const TextStyle(
                  color: _C.textSub,
                  fontSize: 12,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (post.isVerifiedNews && post.sourceName != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Source: ${post.sourceName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],

              // ── Trailer button ────────────────────────────────────────────
              if (post.type == 'trailer' && post.trailerUrl != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    final videoId =
                        YoutubePlayerController.convertUrlToId(post.trailerUrl!);
                    if (videoId != null) TrailerHelper.showTrailer(context, videoId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.bg.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _C.trailerBorder, width: 0.5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.playCircle, size: 13, color: _C.accent),
                        SizedBox(width: 6),
                        Text(
                          'Watch trailer',
                          style: TextStyle(
                            color: _C.trailerText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // ── Actions ──────────────────────────────────────────────────
              Row(
                children: [
                  // Like
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      provider.toggleLike(post.id);
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 10, 4),
                      child: Row(
                        children: [
                          _AnimatedLikeIcon(isLiked: post.isLiked),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: post.isLiked ? _C.likeActive : _C.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),

                  // Comment
                  InkWell(
                    onTap: () => _showCommentsSheet(context, post, provider),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.messageCircle, color: _C.textMuted, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments}',
                            style: const TextStyle(
                              color: _C.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Share
                  InkWell(
                    onTap: () {},
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.share2, color: _C.textMuted, size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) Container(height: 0.5, color: _C.divider),
      ],
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays  > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 12, color: Colors.green.shade400),
          const SizedBox(width: 4),
          Text(
            'Verified News',
            style: TextStyle(fontSize: 11, color: Colors.green.shade400,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, dynamic post, FeedProvider provider) {
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _C.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _C.handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(height: 0.5, color: _C.divider),

                // Comment list
                Expanded(
                  child: Consumer<FeedProvider>(
                    builder: (context, feedProv, _) {
                      final updated = feedProv.posts.firstWhere((p) => p.id == post.id);
                      if (updated.commentsList.isEmpty) {
                        return const Center(
                          child: Text(
                            'No comments yet.',
                            style: TextStyle(color: _C.textMuted, fontSize: 13),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: updated.commentsList.length,
                        separatorBuilder: (_, __) =>
                            Container(height: 0.5, color: _C.divider),
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                radius: 13,
                                backgroundColor: _C.surface,
                                child: Icon(LucideIcons.user,
                                    color: _C.textMuted, size: 13),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  updated.commentsList[i],
                                  style: const TextStyle(
                                    color: _C.textSub,
                                    fontSize: 13,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Container(height: 0.5, color: _C.divider),

                // Input row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          style: const TextStyle(
                            color: _C.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a comment…',
                            hintStyle: const TextStyle(
                              color: _C.textMuted,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: _C.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          if (commentCtrl.text.isNotEmpty) {
                            provider.addComment(post.id, commentCtrl.text);
                            commentCtrl.clear();
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: _C.accentDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.send,
                              color: _C.accent, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarAsset;
  const _Avatar({required this.name, this.avatarAsset});

  // Cool-toned, low-saturation avatar palette
  static const _fills = [
    Color(0xFF1A2530),
    Color(0xFF1A1E30),
    Color(0xFF1E2535),
    Color(0xFF251E14),
    Color(0xFF1A2520),
  ];
  static const _texts = [
    Color(0xFF5A8AAA),
    Color(0xFF5A6AAA),
    Color(0xFF6A7AAA),
    Color(0xFF8A7040),
    Color(0xFF5A8A7A),
  ];

  @override
  Widget build(BuildContext context) {
    if (avatarAsset != null && avatarAsset!.isNotEmpty) {
      return CircleAvatar(
        radius: 15,
        backgroundColor: _C.surface,
        backgroundImage: AssetImage(avatarAsset!),
      );
    }
    final idx   = name.isNotEmpty ? name.codeUnitAt(0) % _fills.length : 0;
    return CircleAvatar(
      radius: 15,
      backgroundColor: _fills[idx],
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: _texts[idx],
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    switch (type) {
      case 'leak':
        bg = _C.badgeLeakBg;
        fg = _C.badgeLeakText;
        break;
      case 'trailer':
        bg = _C.badgeTrlrBg;
        fg = _C.badgeTrlrText;
        break;
      default: // news / review / discussion
        bg = _C.badgeNewsBg;
        fg = _C.badgeNewsText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Animated like icon ────────────────────────────────────────────────────────

class _AnimatedLikeIcon extends StatefulWidget {
  final bool isLiked;
  const _AnimatedLikeIcon({required this.isLiked});

  @override
  State<_AnimatedLikeIcon> createState() => _AnimatedLikeIconState();
}

class _AnimatedLikeIconState extends State<_AnimatedLikeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _burst;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 520), vsync: this);

    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.35)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.35, end: 0.9)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.9, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 50),
    ]).animate(_ctrl);

    _burst = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_AnimatedLikeIcon old) {
    super.didUpdateWidget(old);
    if (widget.isLiked != old.isLiked) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width: 26,
        height: 26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isLiked)
              CustomPaint(
                  size: const Size(26, 26),
                  painter: _ParticlePainter(_burst.value)),
            Transform.scale(
              scale: _scale.value,
              child: Icon(
                widget.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 16,
                color: widget.isLiked ? _C.likeActive : _C.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Particle painter ──────────────────────────────────────────────────────────
// Uses cool-toned particles to match the palette

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  static const _colors = [
    Color(0xFFC0506A),
    Color(0xFF7EAFD4),
    Color(0xFF5A8AAA),
    Color(0xFF8A7AC8),
    Color(0xFF5DCAA5),
    Color(0xFF7AAAC8),
    Color(0xFFAA7090),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const count  = 10;
    for (int i = 0; i < count; i++) {
      final angle   = (i / count) * 2 * pi;
      final radius  = 11.0 * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(center.dx + cos(angle) * radius,
               center.dy + sin(angle) * radius),
        1.8 * (1.0 - progress * 0.5),
        Paint()
          ..color = _colors[i % _colors.length].withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── Skeleton Item ────────────────────────────────────────────────────────────

class _PostSkeleton extends StatelessWidget {
  const _PostSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.white12,
                    highlightColor: Colors.white24,
                    child: const CircleAvatar(radius: 15, backgroundColor: Colors.white),
                  ),
                  const SizedBox(width: 9),
                  Shimmer.fromColors(
                    baseColor: Colors.white12,
                    highlightColor: Colors.white24,
                    child: Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const Spacer(),
                  Shimmer.fromColors(
                    baseColor: Colors.white12,
                    highlightColor: Colors.white24,
                    child: Container(
                      width: 40,
                      height: 14,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Shimmer.fromColors(
                baseColor: Colors.white12,
                highlightColor: Colors.white24,
                child: Container(
                  width: double.infinity,
                  height: 18,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 4),
              Shimmer.fromColors(
                baseColor: Colors.white12,
                highlightColor: Colors.white24,
                child: Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Container(height: 0.5, color: _C.divider),
      ],
    );
  }
}