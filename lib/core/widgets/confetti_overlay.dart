import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Lightweight, high-performance particle confetti overlay.
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool autoPlay;
  final Duration duration;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.autoPlay = true,
    this.duration = const Duration(milliseconds: 3500),
  });

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  static const List<Color> _palette = [
    AppColors.gameRed,
    AppColors.gameBlue,
    AppColors.gameYellow,
    AppColors.gameGreen,
    AppColors.primary,
    Color(0xFFFFD700), // Gold
    Color(0xFFFF4081), // Pink
    Color(0xFF00E5FF), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addListener(() {
      setState(() {});
    });

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        play();
      });
    }
  }

  void play() {
    _initParticles();
    _controller.forward(from: 0.0);
  }

  void _initParticles() {
    _particles.clear();
    const particleCount = 70;
    for (int i = 0; i < particleCount; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          y: -0.1 - _random.nextDouble() * 0.3,
          vx: (_random.nextDouble() - 0.5) * 0.35,
          vy: 0.35 + _random.nextDouble() * 0.45,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 6,
          flutterSpeed: 3 + _random.nextDouble() * 6,
          flutterPhase: _random.nextDouble() * 2 * pi,
          color: _palette[_random.nextInt(_palette.length)],
          width: 8 + _random.nextDouble() * 7,
          height: 12 + _random.nextDouble() * 8,
          isCircle: _random.nextBool() && _random.nextBool(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isAnimating || _controller.value > 0.0 && _controller.value < 1.0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  progress: _controller.value,
                  particles: _particles,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  final double vx;
  final double vy;
  double rotation;
  final double rotationSpeed;
  final double flutterSpeed;
  final double flutterPhase;
  final Color color;
  final double width;
  final double height;
  final bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.flutterSpeed,
    required this.flutterPhase,
    required this.color,
    required this.width,
    required this.height,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - (progress - 0.7).clamp(0.0, 0.3) / 0.3).clamp(0.0, 1.0);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final currentY = (p.y + p.vy * progress) * size.height;
      final sway = sin(progress * p.flutterSpeed + p.flutterPhase) * 20;
      final currentX = (p.x + p.vx * progress) * size.width + sway;

      // Don't render out-of-screen particles
      if (currentY > size.height + 30 || currentY < -50) continue;

      final currentRotation = p.rotation + p.rotationSpeed * progress;
      final flutterScale = cos(progress * p.flutterSpeed + p.flutterPhase).abs();

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRotation);
      canvas.scale(1.0, flutterScale);

      paint.color = p.color.withValues(alpha: opacity);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.width / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.width,
              height: p.height,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
