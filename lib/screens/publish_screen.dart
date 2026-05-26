import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _trailerController = TextEditingController();

  String _type = 'news';
  bool _isSubmitting = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  // ── Palette ──────────────────────────────────────────────
  static const _bg          = Color(0xFF111111);
  static const _surface     = Color(0xFF1a1a1a);
  static const _surfaceAlt  = Color(0xFF222222);
  static const _border      = Color(0xFF2a2a2a);
  static const _borderFocus = Color(0xFF555555);
  static const _accent      = Color(0xFFe0e0e0);
  static const _accentSoft  = Color(0x1Ae0e0e0);
  static const _accentBorder = Color(0x44555555);
  static const _textPrimary = Color(0xFFF0F0F0);
  static const _textMuted   = Color(0xFF888888);
  static const _textHint    = Color(0xFF444444);
  static const Color _errorColor = Color(0xFFe55d5d);

  final _typeOptions = const [
    _TypeOption(
      value: 'news',
      label: 'News',
      description: 'Industry updates',
      icon: Icons.newspaper_rounded,
      isFullWidth: false,
    ),
    _TypeOption(
      value: 'leak',
      label: 'Leak',
      description: 'Exclusive intel',
      icon: Icons.lock_open_rounded,
      isFullWidth: false,
    ),
    _TypeOption(
      value: 'trailer',
      label: 'Trailer',
      description: 'Video content with YouTube link',
      icon: Icons.play_circle_rounded,
      isFullWidth: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _trailerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 400));

    final post = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: _type,
      trailerUrl: _type == 'trailer' ? _trailerController.text.trim() : null,
      authorName: 'You',
      createdAt: DateTime.now(),
    );

    if (!mounted) return;
    Provider.of<FeedProvider>(context, listen: false).addPost(post);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              children: [
                _buildSection(
                  label: 'Post type',
                  child: _buildTypeGrid(),
                ),
                const SizedBox(height: 22),
                _buildSection(
                  label: 'Title',
                  counter: _buildCounter(_titleController, 100),
                  child: _buildTextField(
                    controller: _titleController,
                    hint: 'Give your post a compelling title…',
                    maxLines: 1,
                    maxLength: 100,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                ),
                const SizedBox(height: 22),
                _buildSection(
                  label: 'Content',
                  counter: _buildWordCounter(_contentController),
                  child: _buildTextField(
                    controller: _contentController,
                    hint: 'What\'s the story? Share all the details…',
                    maxLines: 6,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Content is required' : null,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: _type == 'trailer'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 22),
                            _buildSection(
                              label: 'YouTube URL',
                              child: _buildTextField(
                                controller: _trailerController,
                                hint: 'https://youtube.com/watch?v=…',
                                maxLines: 1,
                                prefixIcon: Icons.link_rounded,
                                keyboardType: TextInputType.url,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 36),
                _buildPublishButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _surface,
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: const Icon(Icons.close_rounded, color: _textMuted, size: 18),
        ),
      ),
      title: Column(
        children: [
          const Text(
            'New post',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Text(
              'Draft saved',
              style: TextStyle(color: _textMuted, fontSize: 10),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: _isSubmitting ? null : _submit,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _accentBorder),
            ),
            child: Text(
              _isSubmitting ? 'Publishing…' : 'Publish',
              style: TextStyle(
                color: _isSubmitting ? _textMuted : _accent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: _border),
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────
  Widget _buildSection({
    required String label,
    required Widget child,
    Widget? counter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: _borderFocus,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            if (counter != null) ...[
              const Spacer(),
              counter,
            ],
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  // ── Type selector ─────────────────────────────────────────
  Widget _buildTypeGrid() {
    final rows = <Widget>[];
    final twoCol = _typeOptions.where((o) => !o.isFullWidth).toList();
    final fullWidth = _typeOptions.where((o) => o.isFullWidth).toList();

    rows.add(
      Row(
        children: twoCol.map((opt) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: opt == twoCol.last ? 0 : 8,
              ),
              child: _buildTypeCard(opt),
            ),
          );
        }).toList(),
      ),
    );

    for (final opt in fullWidth) {
      rows.add(const SizedBox(height: 8));
      rows.add(_buildTypeCard(opt));
    }

    return Column(children: rows);
  }

  Widget _buildTypeCard(_TypeOption opt) {
    final isSelected = _type == opt.value;
    return GestureDetector(
      onTap: () => setState(() => _type = opt.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? _accentSoft : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _borderFocus : _border,
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? _accent.withValues(alpha: 0.10)
                    : _surfaceAlt,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                opt.icon,
                size: 18,
                color: isSelected ? _accent : _textHint,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt.label,
                    style: TextStyle(
                      color: isSelected ? _accent : _textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    opt.description,
                    style: TextStyle(
                      color: isSelected
                          ? _accent.withValues(alpha: 0.45)
                          : _textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _borderFocus : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _borderFocus : _border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Text field ────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          const SizedBox.shrink(),
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 14,
        height: 1.55,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textHint, fontSize: 14),
        filled: true,
        fillColor: _surface,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: _textHint, size: 18)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderFocus, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorColor, width: 1.0),
        ),
        errorStyle: const TextStyle(color: _errorColor, fontSize: 12),
      ),
    );
  }

  // ── Live counters ─────────────────────────────────────────
  Widget _buildCounter(TextEditingController controller, int max) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (_, __, ___) {
        final count = controller.text.length;
        final isWarn = count > (max * 0.85).floor();
        return Text(
          '$count / $max',
          style: TextStyle(
            color: isWarn ? _accent : _textHint,
            fontSize: 11,
          ),
        );
      },
    );
  }

  Widget _buildWordCounter(TextEditingController controller) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (_, __, ___) {
        final text = controller.text.trim();
        final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
        return Text(
          '$words word${words != 1 ? 's' : ''}',
          style: const TextStyle(color: _textHint, fontSize: 11),
        );
      },
    );
  }

  // ── Publish button (no icon) ──────────────────────────────
  Widget _buildPublishButton() {
    return SizedBox(
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _isSubmitting ? _surfaceAlt : _accent,
          border: _isSubmitting
              ? Border.all(color: _border, width: 0.5)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSubmitting ? null : _submit,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: _isSubmitting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _textMuted,
                            backgroundColor: _textMuted.withValues(alpha: 0.2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Publishing…',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Publish post',
                      style: TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────
class _TypeOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  final bool isFullWidth;

  const _TypeOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.isFullWidth,
  });
}