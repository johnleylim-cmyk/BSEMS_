import 'package:flutter/material.dart';
import '../app/theme.dart';

/// A "Load More" indicator shown at the bottom of a paginated list.
/// Shows a loading spinner while fetching, or a "Load More" button when idle.
class LoadMoreIndicator extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const LoadMoreIndicator({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'All items loaded',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accentCyan,
            ),
          ),
        ),
      );
    }

    if (onLoadMore != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            icon: const Icon(Icons.expand_more, size: 18),
            label: const Text('Load More'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentCyan,
            ),
            onPressed: onLoadMore,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
