import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';

/// A premium animated empty state with rotating gradient ring,
/// breathing pulse, and floating orbit particles.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating gradient ring
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (_, child) => Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppTheme.accentCyan.withValues(alpha: 0.3),
                              AppTheme.accentPurple.withValues(alpha: 0.15),
                              AppTheme.accentPink.withValues(alpha: 0.1),
                              AppTheme.accentCyan.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Inner dark circle to create ring effect
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppTheme.background : AppTheme.lightBackground,
                    ),
                  ),

                  // Breathing pulse circle
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) {
                      final scale = 0.9 + _pulseController.value * 0.1;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentCyan.withValues(
                              alpha: 0.06 + _pulseController.value * 0.04,
                            ),
                            border: Border.all(
                              color: AppTheme.accentCyan.withValues(
                                alpha: 0.1 + _pulseController.value * 0.08,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Orbiting particles
                  ...List.generate(5, (i) {
                    final offset = i * (2 * math.pi / 5);
                    return AnimatedBuilder(
                      animation: _orbitController,
                      builder: (_, child) {
                        final angle = _orbitController.value * 2 * math.pi + offset;
                        final radius = 58.0;
                        return Positioned(
                          left: 70 + math.cos(angle) * radius - 3,
                          top: 70 + math.sin(angle) * radius - 3,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: [
                                AppTheme.accentCyan,
                                AppTheme.accentPurple,
                                AppTheme.accentPink,
                                AppTheme.accentGreen,
                                AppTheme.accentOrange,
                              ][i].withValues(
                                alpha: 0.5 + math.sin(_orbitController.value * math.pi * 2 + i) * 0.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: [
                                    AppTheme.accentCyan,
                                    AppTheme.accentPurple,
                                    AppTheme.accentPink,
                                    AppTheme.accentGreen,
                                    AppTheme.accentOrange,
                                  ][i].withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Center icon
                  Icon(
                    widget.icon,
                    size: 40,
                    color: AppTheme.accentCyan.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onAction,
                icon: const Icon(Icons.add),
                label: Text(widget.actionLabel!),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(
            begin: const Offset(0.9, 0.9),
            duration: 600.ms,
            curve: Curves.easeOut);
  }
}
