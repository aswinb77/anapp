import 'package:flutter/material.dart';

class NoInternetScreen extends StatefulWidget {
  final Future<bool> Function()? onRetry;
  final VoidCallback? onBrowseOffline;

  const NoInternetScreen({
    super.key,
    this.onRetry,
    this.onBrowseOffline,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  bool _retrying = false;
  late final AnimationController _spinCtrl;

  static const _bg        = Color(0xFF0A0A0C);
  static const _surface   = Color(0xFF111116);
  static const _surface2  = Color(0xFF1A1A22);
  static const _border    = Color(0xFF1E1E24);
  static const _border2   = Color(0xFF22222E);
  static const _gold      = Color(0xFFC8A97A);
  static const _goldDark  = Color(0xFF1A1510);
  static const _goldBorder = Color(0xFF3A2E18);
  static const _goldText  = Color(0xFF8A7040);
  static const _t1        = Color(0xFFF0EDE8);
  static const _t2        = Color(0xFF6A6A7A);
  static const _t3        = Color(0xFF5A5A6A);
  static const _t4        = Color(0xFF4A4A5A);
  static const _t5        = Color(0xFF3A3A48);
  static const _surface3  = Color(0xFF0E0E14);
  static const _seatLit   = Color(0xFF2A2A38);
  static const _border3   = Color(0xFF22222E);

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    _spinCtrl.repeat();

    final ok = await (widget.onRetry?.call() ?? Future.value(false));

    _spinCtrl.stop();
    _spinCtrl.reset();
    if (mounted) setState(() => _retrying = false);
    if (ok && mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _FilmStrip(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTheaterBlock(),
                    _buildBody(),
                  ],
                ),
              ),
            ),
            _FilmStrip(),
          ],
        ),
      ),
    );
  }

  Widget _buildTheaterBlock() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _buildScreenSurface(),
          _buildSeatRow(),
        ],
      ),
    );
  }

  Widget _buildScreenSurface() {
    return Container(
      height: 140,
      color: _surface2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ScanlinePainter()),
          ),
          Center(
            child: Container(
              width: 70,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x10C8A97A), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrokenReel(),
              const SizedBox(height: 10),
              Text(
                'NO SIGNAL',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.5,
                  color: _t5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatRow() {
    const seats = [false, true, false, true, false, true, false, false, true, false, true, false];
    return Container(
      height: 22,
      color: _surface3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: seats.map((lit) => Container(
          width: 14,
          height: 12,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: lit ? _seatLit : _surface2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            border: Border.all(color: _border3, width: 0.5),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _goldDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _goldBorder, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: _gold, shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'INTERMISSION',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.8,
                    color: _goldText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _retrying ? null : _handleRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                disabledBackgroundColor: _surface,
                foregroundColor: _bg,
                disabledForegroundColor: _t4,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotationTransition(
                    turns: _spinCtrl,
                    child: const Icon(Icons.refresh_rounded, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _retrying ? 'Finding signal…' : 'Try again',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 0.5, color: _surface2),
          const SizedBox(height: 20),
          _buildTip(Icons.wifi_rounded,     'Make sure your Wi-Fi or mobile data is switched on'),
          _buildTip(Icons.airplanemode_off, 'Check that airplane mode isn\'t stealing the signal'),
          _buildTip(Icons.router_outlined,  'Try moving closer to your router or restarting it'),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF141418),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border2, width: 0.5),
            ),
            child: Icon(icon, size: 15, color: _t4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12, color: _t3, height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilmStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      color: const Color(0xFF111116),
      child: Row(
        children: List.generate(20, (_) => Container(
          width: 13, height: 13,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF1E1E24), width: 0.5),
          ),
        )),
      ),
    );
  }
}

class _BrokenReel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(52, 52),
      painter: _ReelPainter(),
    );
  }
}

class _ReelPainter extends CustomPainter {
  static const _ring  = Color(0xFF2E2E3A);
  static const _inner = Color(0xFF1E1E2A);
  static const _gold  = Color(0xFFC8A97A);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = _ring;

    canvas.drawCircle(Offset(cx, cy), 24, ringPaint);
    canvas.drawCircle(Offset(cx, cy), 8,
        Paint()..style = PaintingStyle.fill..color = _inner);
    canvas.drawCircle(Offset(cx, cy), 8, ringPaint);

    final spokePaint = Paint()
      ..color = _ring
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final angle = i * 60 * (3.14159265 / 180);
      final cos   = _cosA(angle);
      final sin   = _sinA(angle);
      canvas.drawLine(
        Offset(cx + 9 * cos,  cy + 9 * sin),
        Offset(cx + 21 * cos, cy + 21 * sin),
        spokePaint,
      );
    }

    final tearPaint = Paint()
      ..color = _gold
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(cx + 18, cy - 20);
    canvas.rotate(0.27);
    canvas.drawLine(const Offset(0, -10), const Offset(0, 10), tearPaint);
    canvas.restore();
  }

  double _cosA(double a) {
    const vals = [1.0, 0.5, -0.5, -1.0, -0.5, 0.5];
    final idx = ((a / (3.14159265 / 3)) % 6).round() % 6;
    return vals[idx];
  }

  double _sinA(double a) {
    const vals = [0.0, 0.866, 0.866, 0.0, -0.866, -0.866];
    final idx = ((a / (3.14159265 / 3)) % 6).round() % 6;
    return vals[idx];
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x2A000000)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
