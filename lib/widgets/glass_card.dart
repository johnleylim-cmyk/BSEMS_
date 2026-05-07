import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// A frosted-glass card with blur backdrop, gradient overlay, subtle border,
/// and premium hover effects (scale, glow, border shift).
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool glow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.glow = false,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: widget.width,
          height: widget.height,
          transform: _hovered
              ? (Matrix4.identity()..setEntry(0, 0, 1.015)..setEntry(1, 1, 1.015))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xE6FFFFFF), Color(0xD9FFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _hovered
                  ? AppTheme.accentCyan.withValues(alpha: 0.25)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppTheme.lightBorder),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppTheme.accentCyan.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : (widget.glow ? AppTheme.glowShadow : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]),
          ),
          padding: widget.padding ?? const EdgeInsets.all(AppTheme.spaceMd),
          child: widget.child,
        ),
      ),
    );

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.onTap != null
          ? GestureDetector(onTap: widget.onTap, child: card)
          : card,
    );
  }
}
