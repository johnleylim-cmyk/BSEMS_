import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../app/theme.dart';

/// Shimmer loading placeholder for premium skeleton screens.
class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppTheme.surfaceLight : AppTheme.lightSurfaceLight,
      highlightColor: isDark ? AppTheme.border : AppTheme.lightBorder,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceLight : AppTheme.lightSurfaceLight,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Creates a list-style shimmer with N items.
  static Widget list({int count = 5, double itemHeight = 72}) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoader(height: itemHeight),
        ),
      ),
    );
  }

  /// Creates a grid-style shimmer.
  static Widget grid({int count = 6, double itemHeight = 140}) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(
        count,
        (i) => ShimmerLoader(width: 280, height: itemHeight),
      ),
    );
  }

  /// Dashboard skeleton: 4 stat tiles + 2 chart cards.
  static Widget dashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 stat tile placeholders
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 16 : 0),
                child: const ShimmerLoader(height: 130),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 2 chart card placeholders
        Row(
          children: [
            const Expanded(child: ShimmerLoader(height: 280)),
            const SizedBox(width: 16),
            const Expanded(child: ShimmerLoader(height: 280)),
          ],
        ),
        const SizedBox(height: 24),
        // Activity feed placeholder
        const ShimmerLoader(height: 200),
      ],
    );
  }

  /// Bracket skeleton: match cards + connector lines
  static Widget bracket() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          3,
          (col) => Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              children: [
                // Round header
                const ShimmerLoader(width: 200, height: 28, borderRadius: 8),
                const SizedBox(height: 12),
                // Match cards
                ...List.generate(
                  (4 ~/ (col + 1)).clamp(1, 4),
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: const ShimmerLoader(width: 200, height: 90),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Single card shimmer with custom dimensions.
  static Widget card({double width = 280, double height = 140}) {
    return ShimmerLoader(width: width, height: height);
  }
}
