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
  late final Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final progress = _animation.value;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background,
                    AppTheme.softSurface,
                    AppTheme.background,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RadiancePainter(progress: progress),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _animation,
                            child: const Icon(
                              Icons.local_florist_rounded,
                              size: 76,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FadeTransition(
                            opacity: _animation,
                            child: Text(
                              l10n.brandParentName,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(height: 26),
                          _GuruPair(progress: progress, l10n: l10n),
                          const SizedBox(height: 26),
                          FadeTransition(
                            opacity: _animation,
                            child: Column(
                              children: [
                                Text(
                                  l10n.appTitle,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontSize: 30),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.brandTagline,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GuruPair extends StatelessWidget {
  const _GuruPair({required this.progress, required this.l10n});

  final double progress;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _GuruImage(
            assetPath: 'assets/images/VidyasagarJi.png',
            label: l10n.brandVidyasagarJi,
            alignment: Alignment.centerRight,
            scale: progress,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GuruImage(
            assetPath: 'assets/images/AjitSagarJi.png',
            label: l10n.brandAjitSagarJi,
            alignment: Alignment.centerLeft,
            scale: (progress * 1.15).clamp(0, 1),
          ),
        ),
      ],
    );
  }
}

class _GuruImage extends StatelessWidget {
  const _GuruImage({
    required this.assetPath,
    required this.label,
    required this.alignment,
    required this.scale,
  });

  final String assetPath;
  final String label;
  final Alignment alignment;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: Transform.scale(
            scale: 0.86 + (scale * 0.14),
            alignment: alignment,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person,
                size: 120,
                color: AppTheme.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _RadiancePainter extends CustomPainter {
  const _RadiancePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.43);
    final radius = size.width * (0.72 + (progress * 0.18));
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.secondary.withValues(alpha: 0.20 * progress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RadiancePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
