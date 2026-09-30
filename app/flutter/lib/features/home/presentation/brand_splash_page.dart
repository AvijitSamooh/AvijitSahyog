import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../home_page.dart';

class BrandSplashPage extends StatefulWidget {
  const BrandSplashPage({
    super.key,
    this.duration = const Duration(seconds: 5),
  });

  final Duration duration;

  @override
  State<BrandSplashPage> createState() => _BrandSplashPageState();
}

class _BrandSplashPageState extends State<BrandSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
    _timer = Timer(widget.duration, _openHome);
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _stage(double start, double end) => CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final logoStage = _stage(0, .30);
    final guruStage = _stage(.25, .68);
    final titleStage = _stage(.58, 1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _ReferenceBackground(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    FadeTransition(
                      opacity: logoStage,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: .72, end: 1).animate(logoStage),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/AvijitSamuhLogo.png',
                              width: 128,
                              height: 128,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.brandParentName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 29,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.brandTagline,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      flex: 4,
                      child: FadeTransition(
                        opacity: guruStage,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .08),
                            end: Offset.zero,
                          ).animate(guruStage),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _Guru(
                                  asset: 'assets/images/VidyasagarJi.png',
                                  label: l10n.brandVidyasagarJi,
                                  alignment: Alignment.bottomRight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _Guru(
                                  asset: 'assets/images/AjitSagarJi.png',
                                  label: l10n.brandAjitSagarJi,
                                  alignment: Alignment.bottomLeft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: titleStage,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .08),
                          end: Offset.zero,
                        ).animate(titleStage),
                        child: Column(
                          children: [
                            Text(
                              l10n.appTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 31,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              l10n.brandTagline,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Guru extends StatelessWidget {
  const _Guru({
    required this.asset,
    required this.label,
    required this.alignment,
  });

  final String asset;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            alignment: alignment,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReferenceBackground extends StatelessWidget {
  const _ReferenceBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ReferenceBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ReferenceBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFEBC5),
          Color(0xFFFFF8ED),
          Color(0xFFF8E2B8),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFC65C).withValues(alpha: .22),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height * .30),
          radius: size.width * .72,
        ),
      );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * .30),
      size.width * .72,
      glow,
    );

    final rays = Paint()
      ..color = const Color(0xFFE5B35B).withValues(alpha: .13)
      ..strokeWidth = 1.4;
    final center = Offset(size.width / 2, size.height * .28);
    for (var i = -8; i <= 8; i++) {
      final end = Offset(
        size.width / 2 + i * size.width * .12,
        size.height * .62,
      );
      canvas.drawLine(center, end, rays);
    }

    final road = Path()
      ..moveTo(size.width * .43, size.height)
      ..cubicTo(
        size.width * .47,
        size.height * .82,
        size.width * .54,
        size.height * .68,
        size.width * .50,
        size.height * .54,
      )
      ..cubicTo(
        size.width * .49,
        size.height * .50,
        size.width * .51,
        size.height * .48,
        size.width * .50,
        size.height * .45,
      );
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFFF4D9A4).withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .08,
    );

    final temple = Paint()
      ..color = const Color(0xFFD5A65B).withValues(alpha: .14);
    final templeBase = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .37),
      width: size.width * .42,
      height: size.height * .20,
    );
    canvas.drawRect(templeBase, temple);
    final dome = Path()
      ..moveTo(size.width * .37, size.height * .30)
      ..lineTo(size.width * .50, size.height * .18)
      ..lineTo(size.width * .63, size.height * .30)
      ..close();
    canvas.drawPath(dome, temple);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .25),
        width: size.width * .035,
        height: size.height * .10,
      ),
      temple,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
