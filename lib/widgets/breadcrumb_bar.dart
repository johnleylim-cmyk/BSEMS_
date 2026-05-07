import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';

/// A single breadcrumb segment.
class BreadcrumbItem {
  final String label;
  final String? route;

  const BreadcrumbItem({required this.label, this.route});
}

/// Premium breadcrumb navigation bar with hover effects and chevron separators.
class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                ),
              ),
            _BreadcrumbSegment(
              label: items[i].label,
              route: items[i].route,
              isLast: i == items.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbSegment extends StatefulWidget {
  final String label;
  final String? route;
  final bool isLast;

  const _BreadcrumbSegment({
    required this.label,
    this.route,
    required this.isLast,
  });

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClickable = widget.route != null && !widget.isLast;

    final baseColor = widget.isLast
        ? AppTheme.accentCyan
        : (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted);
    final hoverColor = widget.isLast
        ? AppTheme.accentCyan
        : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary);

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: isClickable ? () => context.go(widget.route!) : null,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: _hovered && isClickable ? hoverColor : baseColor,
            fontSize: 13,
            fontWeight: widget.isLast ? FontWeight.w600 : FontWeight.w400,
            decoration: _hovered && isClickable
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: hoverColor,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}
