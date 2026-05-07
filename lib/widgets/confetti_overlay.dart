import 'dart:math';
import 'package:flutter/material.dart';

/// A confetti overlay that spawns colorful particles with gravity.
/// Use [ConfettiOverlay.show(context)] to trigger a burst.
class ConfettiOverlay {
  /// Show a confetti burst over the current screen for [duration].
  static void show(BuildContext context, {Duration duration = const Duration(seconds: 3)}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiAnimation(
        duration: duration,
        onComplete: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ConfettiAnimation extends StatefulWidget {
  final Duration duration;
  final VoidCallback onComplete;

  const _ConfettiAnimation({
    required this.duration,
    required this.onComplete,
  });

  @override
  State<_ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<_ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      })
      ..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _particles = List.generate(120, (_) => _Particle(_random, size));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  late double x, y, vx, vy;
  late double size;
  late Color color;
  late double rotation;
  late double rotationSpeed;

  static const _colors = [
    Color(0xFFFFD700), // gold
    Color(0xFF00E5FF), // cyan
    Color(0xFFB388FF), // purple
    Color(0xFFFF80AB), // pink
    Color(0xFF00E676), // green
    Color(0xFFFFAB40), // orange
    Color(0xFFFF5252), // red
  ];

  _Particle(Random r, Size screenSize) {
    x = screenSize.width * 0.3 + r.nextDouble() * screenSize.width * 0.4;
    y = screenSize.height * 0.1 + r.nextDouble() * screenSize.height * 0.2;
    vx = (r.nextDouble() - 0.5) * 12;
    vy = -(r.nextDouble() * 8 + 2);
    size = r.nextDouble() * 8 + 4;
    color = _colors[r.nextInt(_colors.length)];
    rotation = r.nextDouble() * 2 * pi;
    rotationSpeed = (r.nextDouble() - 0.5) * 10;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = progress * 3.0; // seconds
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final x = p.x + p.vx * elapsed * 60;
      final y = p.y + p.vy * elapsed * 60 + 0.5 * 400 * elapsed * elapsed;
      final rot = p.rotation + p.rotationSpeed * elapsed;

      if (y > size.height + 50) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
