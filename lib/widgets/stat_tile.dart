import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';

/// A premium stat tile with animated count-up value and hover glow.
class StatTile extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final String? trend;
  final bool trendUp;
  final int animationDelay;

  const StatTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
    this.trend,
    this.trendUp = true,
    this.animationDelay = 0,
  });

  @override
  State<StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<StatTile>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _counterController;
  late Animation<int> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _setupAnimation();
    Future.delayed(
      Duration(milliseconds: widget.animationDelay + 200),
      () {
        if (mounted) _counterController.forward();
      },
    );
  }

  void _setupAnimation() {
    final targetValue = int.tryParse(widget.value) ?? 0;
    _counterAnimation = IntTween(begin: 0, end: targetValue).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant StatTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _setupAnimation();
      _counterController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? AppTheme.accentCyan;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNumeric = int.tryParse(widget.value) != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: _hovered
            ? (Matrix4.identity()..setEntry(0, 0, 1.03)..setEntry(1, 1, 1.03))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.card : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _hovered
                ? color.withValues(alpha: 0.3)
                : (isDark ? AppTheme.border : AppTheme.lightBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? color.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.08),
              blurRadius: _hovered ? 28 : 20,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(widget.icon, color: color, size: 22),
                ),
                if (widget.trend != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (widget.trendUp
                              ? AppTheme.accentGreen
                              : AppTheme.accentRed)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.trendUp
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 14,
                          color: widget.trendUp
                              ? AppTheme.accentGreen
                              : AppTheme.accentRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.trend!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.trendUp
                                ? AppTheme.accentGreen
                                : AppTheme.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isNumeric)
              AnimatedBuilder(
                animation: _counterAnimation,
                builder: (_, child) => Text(
                  '${_counterAnimation.value}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.textPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                ),
              )
            else
              Text(
                widget.value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                    ),
              ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                  ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.animationDelay))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}
