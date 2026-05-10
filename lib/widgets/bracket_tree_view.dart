import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/enums.dart';
import '../models/match_model.dart';

/// MPL-style tournament bracket tree with connecting lines.
///
/// Renders matches grouped by round in columns (left-to-right),
/// with power-of-2 vertical spacing so that parent matches align
/// between their two feeder matches. Connector lines are drawn
/// via [CustomPainter].
class BracketTreeView extends StatelessWidget {
  final List<MatchModel> matches;
  final bool canManage;
  final void Function(MatchModel match) onScore;
  final Color accentColor;
  final Widget Function(MatchModel match)? cardBuilder;

  // Layout constants
  static const double _cardWidth = 240.0;
  static const double _cardHeight = 88.0;
  static const double _roundGap = 56.0;
  static const double _baseVerticalGap = 12.0;

  const BracketTreeView({
    super.key,
    required this.matches,
    required this.canManage,
    required this.onScore,
    this.accentColor = AppTheme.accentCyan,
    this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    // Group matches by round and sort rounds
    final roundMap = <int, List<MatchModel>>{};
    for (final m in matches) {
      roundMap.putIfAbsent(m.round, () => []).add(m);
    }
    for (final list in roundMap.values) {
      list.sort((a, b) => a.matchNumber.compareTo(b.matchNumber));
    }
    final sortedRounds = roundMap.keys.toList()..sort();

    if (sortedRounds.isEmpty) return const SizedBox.shrink();

    // Calculate the max number of matches in the first round
    final maxMatchesInFirstRound = roundMap[sortedRounds.first]!.length;

    // Total height needed (based on first round which has the most matches)
    final totalHeight =
        maxMatchesInFirstRound * _cardHeight +
        (maxMatchesInFirstRound - 1) * _baseVerticalGap;

    // Total width
    final totalWidth =
        sortedRounds.length * _cardWidth +
        (sortedRounds.length - 1) * _roundGap;

    // Precompute card positions for each match
    final positions = <String, Rect>{};
    for (var roundIdx = 0; roundIdx < sortedRounds.length; roundIdx++) {
      final round = sortedRounds[roundIdx];
      final roundMatches = roundMap[round]!;
      final x = roundIdx * (_cardWidth + _roundGap);

      // For each round, compute Y positions
      if (roundIdx == 0) {
        // First round: evenly spaced
        for (var i = 0; i < roundMatches.length; i++) {
          final y = i * (_cardHeight + _baseVerticalGap);
          positions[roundMatches[i].id] = Rect.fromLTWH(
            x, y, _cardWidth, _cardHeight,
          );
        }
      } else {
        // Subsequent rounds: align parallel rounds, reduce paired rounds.
        final prevRound = sortedRounds[roundIdx - 1];
        final prevMatches = roundMap[prevRound]!;
        final isParallelRound = roundMatches.length == prevMatches.length;

        for (var i = 0; i < roundMatches.length; i++) {
          double y;
          final feeder1Idx = i * 2;
          final feeder2Idx = i * 2 + 1;

          if (isParallelRound && i < prevMatches.length) {
            final rect = positions[prevMatches[i].id]!;
            y = rect.top;
          } else if (feeder1Idx < prevMatches.length &&
              feeder2Idx < prevMatches.length) {
            // Center between two feeder matches
            final rect1 = positions[prevMatches[feeder1Idx].id]!;
            final rect2 = positions[prevMatches[feeder2Idx].id]!;
            y = (rect1.center.dy + rect2.center.dy) / 2 - _cardHeight / 2;
          } else if (feeder1Idx < prevMatches.length) {
            // Only one feeder (odd bracket)
            final rect1 = positions[prevMatches[feeder1Idx].id]!;
            y = rect1.top;
          } else {
            // Fallback: even spacing
            y = i * (_cardHeight + _baseVerticalGap);
          }
          positions[roundMatches[i].id] = Rect.fromLTWH(
            x, y, _cardWidth, _cardHeight,
          );
        }
      }
    }

    // Compute connector lines data
    final connectors = <_ConnectorLine>[];
    for (final match in matches) {
      final nextMatchId = match.nextMatchId;
      if (nextMatchId == null) continue;

      final srcRect = positions[match.id];
      final targetRect = positions[nextMatchId];
      if (srcRect == null || targetRect == null) continue;

      connectors.add(_ConnectorLine(
        from: Offset(srcRect.right, srcRect.center.dy),
        to: Offset(targetRect.left, targetRect.center.dy),
      ));
    }

    // Adjust total height to fit all positioned cards
    final maxY = positions.values
        .map((r) => r.bottom)
        .fold(totalHeight, (a, b) => a > b ? a : b);

    return InteractiveViewer(
      constrained: false,
      minScale: 0.3,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(200),
      child: SizedBox(
          width: totalWidth + 40,
          height: maxY + 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Connector lines layer (painted behind cards)
              Positioned.fill(
                child: CustomPaint(
                  painter: _BracketConnectorPainter(
                    connectors: connectors,
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
              ),

              // Round headers
              for (var roundIdx = 0; roundIdx < sortedRounds.length; roundIdx++)
                Positioned(
                  left: roundIdx * (_cardWidth + _roundGap),
                  top: -28,
                  child: _RoundHeader(
                    label: roundIdx == sortedRounds.length - 1
                        ? 'Finals'
                        : 'Round ${roundIdx + 1}',
                    color: accentColor,
                  ),
                ),

              // Match cards
              for (final entry in positions.entries)
                Positioned(
                  left: entry.value.left,
                  top: entry.value.top,
                  width: entry.value.width,
                  height: entry.value.height,
                  child: _buildCard(
                    matches.firstWhere((m) => m.id == entry.key),
                  ),
                ),
            ],
          ),
        ),
    );
  }

  Widget _buildCard(MatchModel match) {
    if (cardBuilder != null) return cardBuilder!(match);
    return _DefaultBracketCard(
      match: match,
      canManage: canManage,
      onScore: () => onScore(match),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CONNECTOR LINE DATA & PAINTER
// ═══════════════════════════════════════════════════════════════════

class _ConnectorLine {
  final Offset from; // right-center of source
  final Offset to; // left-center of target

  const _ConnectorLine({required this.from, required this.to});
}

/// Draws MPL-style bracket connector lines.
///
/// Each line is drawn as: horizontal stub → vertical bar → horizontal stub.
/// ```
///  Match A ──┐
///            ├── Winner
///  Match B ──┘
/// ```
class _BracketConnectorPainter extends CustomPainter {
  final List<_ConnectorLine> connectors;
  final Color color;

  const _BracketConnectorPainter({
    required this.connectors,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final conn in connectors) {
      final midX = (conn.from.dx + conn.to.dx) / 2;
      final path = Path()
        ..moveTo(conn.from.dx, conn.from.dy)
        ..lineTo(midX, conn.from.dy)
        ..lineTo(midX, conn.to.dy)
        ..lineTo(conn.to.dx, conn.to.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectorPainter old) =>
      old.connectors != connectors || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
// ROUND HEADER
// ═══════════════════════════════════════════════════════════════════

class _RoundHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _RoundHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DEFAULT BRACKET MATCH CARD
// ═══════════════════════════════════════════════════════════════════

class _DefaultBracketCard extends StatelessWidget {
  final MatchModel match;
  final bool canManage;
  final VoidCallback onScore;

  const _DefaultBracketCard({
    required this.match,
    required this.canManage,
    required this.onScore,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.status == MatchStatus.completed;
    final isLive = match.status == MatchStatus.live;
    final isWaiting = match.team1Id == null || match.team2Id == null;

    return GestureDetector(
      onTap: canManage && !isCompleted && !isWaiting ? onScore : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isLive
                ? AppTheme.accentGreen
                : (isCompleted
                    ? AppTheme.accentCyan.withValues(alpha: 0.3)
                    : AppTheme.border),
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: AppTheme.accentGreen.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TeamSlot(
              name: match.team1Name ?? 'TBD',
              score: match.score1,
              isWinner: isCompleted && match.winnerId == match.team1Id,
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: AppTheme.border.withValues(alpha: 0.5),
            ),
            _TeamSlot(
              name: match.team2Name ?? 'TBD',
              score: match.score2,
              isWinner: isCompleted && match.winnerId == match.team2Id,
            ),
            if (isLive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamSlot extends StatelessWidget {
  final String name;
  final int score;
  final bool isWinner;

  const _TeamSlot({
    required this.name,
    required this.score,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isWinner)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.arrow_right, size: 14, color: AppTheme.accentGreen),
          ),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWinner ? AppTheme.accentGreen : AppTheme.textPrimary,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isWinner
                ? AppTheme.accentGreen.withValues(alpha: 0.15)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              color: isWinner ? AppTheme.accentGreen : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
