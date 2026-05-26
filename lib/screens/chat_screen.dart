import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';

// ── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0A0B);
  static const inputFill   = Color(0xFF1A1A1D);
  static const divider     = Color(0xFF1F1F22);
  static const textPrimary = Color(0xFFE8EAED);
  static const textSub     = Color(0xFF7A8A9A);
  static const textMuted   = Color(0xFF3D4F62);
  static const accent      = Color(0xFF7EAFD4);
  static const accentDark  = Color(0xFF1E3D5C);
  static const bubbleMe    = Color(0xFF1E3D5C);
  static const bubbleOther = Color(0xFF111318);
  static const online      = Color(0xFF52C97A);
}

// ── Message model ──────────────────────────────────────────────────────────
class _ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime createdAt;
  final bool isMe;

  const _ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.createdAt,
    required this.isMe,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _hasMarkedChatSeen = false;

  // ── Send ───────────────────────────────────────────────────────────────
  void _send() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (!chatProvider.isReady || chatProvider.roomId == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    final username = userProvider.username;
    final avatar = userProvider.selectedAvatar;
    
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    if (userId == null || username == null) return;
    
    _inputController.clear();
    HapticFeedback.lightImpact();
    
    await _db.collection(chatProvider.roomId!).add({
      'senderId': userId,
      'senderName': username,
      'senderAvatar': avatar,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    _cleanupOldMessages();
  }

  void _cleanupOldMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (!chatProvider.isReady || chatProvider.roomId == null) return;

    try {
      final snapshot = await _db.collection(chatProvider.roomId!)
          .orderBy('createdAt', descending: true)
          .limit(60)
          .get();
          
      if (snapshot.docs.length > 50) {
        final batch = _db.batch();
        for (int i = 50; i < snapshot.docs.length; i++) {
          batch.delete(snapshot.docs[i].reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Cleanup failed: $e');
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(context),
        ],
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: _C.accentDark,
                child: Icon(Icons.people_alt_rounded, color: _C.accent, size: 18),
              ),
              Positioned(
                bottom: 1, right: 1,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _C.online,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.bg, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Chat',
                  style: TextStyle(color: _C.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: _C.online,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: _C.divider),
      ),
    );
  }

  // ── Message list ───────────────────────────────────────────────────────
  Widget _buildMessageList() {
    final me = Provider.of<UserProvider>(context, listen: false).userId;
    final chatProvider = Provider.of<ChatProvider>(context);
    if (me == null) return _buildEmptyState();
    if (!chatProvider.isReady || chatProvider.roomId == null) {
      return const Center(child: CircularProgressIndicator(color: _C.accent));
    }

    if (!_hasMarkedChatSeen) {
      _hasMarkedChatSeen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatProvider.markChatSeen();
      });
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection(chatProvider.roomId!)
                 .orderBy('createdAt', descending: true)
                 .limit(100)
                 .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _C.accent));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState();

        final messages = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _ChatMessage(
            id: doc.id,
            senderId: data['senderId']?.toString() ?? '',
            senderName: data['senderName']?.toString() ?? 'Unknown',
            senderAvatar: data['senderAvatar']?.toString(),
            text: data['text']?.toString() ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isMe: data['senderId']?.toString() == me,
          );
        }).toList();

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg  = messages[index];
            final prev = index < messages.length - 1 ? messages[index + 1] : null;
            final showName = !msg.isMe && (prev == null || prev.senderId != msg.senderId);
            return _buildBubble(msg, showName);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: _C.accentDark, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: _C.accent, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Global Chat',
              style: TextStyle(color: _C.textPrimary, fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text(
            'Be the first to say hello!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.textSub, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Bubble ─────────────────────────────────────────────────────────────
  Widget _buildBubble(_ChatMessage msg, bool showName) {
    final isMe = msg.isMe;
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final String? effectiveAvatar = isMe ? userProvider.selectedAvatar : msg.senderAvatar;

    return Padding(
      padding: EdgeInsets.only(
        top: showName ? 12 : 3,
        left: isMe ? 64 : 0,
        right: isMe ? 0 : 64,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showName)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    _AvatarWidget(name: msg.senderName, avatarAsset: effectiveAvatar, radius: 10),
                    const SizedBox(width: 6),
                  ],
                  Text(msg.senderName,
                      style: const TextStyle(color: _C.textSub, fontSize: 11, fontWeight: FontWeight.w500)),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    _AvatarWidget(name: msg.senderName, avatarAsset: effectiveAvatar, radius: 10),
                  ],
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isMe ? _C.bubbleMe : _C.bubbleOther,
              borderRadius: BorderRadius.only(
                topLeft:     Radius.circular(isMe ? 16 : 4),
                topRight:    Radius.circular(isMe ? 4 : 16),
                bottomLeft:  const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
              border: Border.all(
                color: isMe ? const Color(0x337EAFD4) : _C.divider,
                width: 0.5,
              ),
            ),
            child: Text(msg.text,
                style: const TextStyle(color: _C.textPrimary, fontSize: 14, height: 1.4)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(_formatTime(msg.createdAt),
                style: const TextStyle(color: _C.textMuted, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────
  Widget _buildInputBar(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final myAvatar = userProvider.selectedAvatar;
    final myName  = userProvider.username ?? '';

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _C.divider, width: 0.5)),
        color: _C.bg,
      ),
      padding: EdgeInsets.fromLTRB(
        12, 10, 12,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _AvatarWidget(name: myName, avatarAsset: myAvatar, radius: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _C.inputFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _C.divider, width: 0.5),
                ),
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(color: _C.textPrimary, fontSize: 14),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Message everyone…',
                    hintStyle: TextStyle(color: _C.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _C.accentDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x557EAFD4),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: _C.accent,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m';

    if (msgDay == today) return timeStr;
    if (msgDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $timeStr';
    }
    final day = dt.day.toString().padLeft(2, '0');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} $day, $timeStr';
  }
}

// ── Avatar widget (shows chosen asset or fallback initials) ────────────────
class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.name, this.avatarAsset, this.radius = 10});
  final String name;
  final String? avatarAsset;
  final double radius;

  static const _fills = [
    Color(0xFF1A2530), Color(0xFF1A1E30),
    Color(0xFF1E2535), Color(0xFF251E14), Color(0xFF1A2520),
  ];
  static const _texts = [
    Color(0xFF5A8AAA), Color(0xFF5A6AAA),
    Color(0xFF6A7AAA), Color(0xFF8A7040), Color(0xFF5A8A7A),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % _fills.length : 0;
    final hasAsset = avatarAsset != null &&
        avatarAsset!.isNotEmpty &&
        avatarAsset!.startsWith('assets/');

    return CircleAvatar(
      radius: radius,
      backgroundColor: _fills[idx],
      backgroundImage: hasAsset ? AssetImage(avatarAsset!) : null,
      child: hasAsset
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: _texts[idx],
                fontSize: radius * 0.85,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}