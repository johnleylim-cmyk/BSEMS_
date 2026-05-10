import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/bracket_generator.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../widgets/bracket_tree_view.dart';
import '../../widgets/glass_card.dart';

/// A read-only public bracket screen accessible without authentication.
/// Route: /bracket/:tournamentId
class PublicBracketScreen extends StatefulWidget {
  final String tournamentId;
  const PublicBracketScreen({super.key, required this.tournamentId});

  @override
  State<PublicBracketScreen> createState() => _PublicBracketScreenState();
}

class _PublicBracketScreenState extends State<PublicBracketScreen> {
  final _db = FirebaseFirestore.instance;
  TournamentModel? _tournament;
  List<MatchModel> _matches = [];
  bool _loading = true;
  bool _tournamentLoaded = false;
  bool _matchesLoaded = false;
  String? _error;
  StreamSubscription? _tournamentSub;
  StreamSubscription? _matchesSub;

  @override
  void initState() {
    super.initState();
    _listenToData();
  }

  @override
  void dispose() {
    _tournamentSub?.cancel();
    _matchesSub?.cancel();
    super.dispose();
  }

  void _listenToData() {
    _tournamentSub = _db
        .collection(AppConstants.tournamentsCollection)
        .doc(widget.tournamentId)
        .snapshots()
        .listen((tournamentDoc) {
      if (!tournamentDoc.exists) {
        setState(() {
          _error = 'Tournament not found';
          _loading = false;
          _tournamentLoaded = true;
        });
        return;
      }

      setState(() {
        _tournament = TournamentModel.fromMap(
          tournamentDoc.data() as Map<String, dynamic>,
          tournamentDoc.id,
        );
        _tournamentLoaded = true;
        _loading = !(_tournamentLoaded && _matchesLoaded);
        _error = null;
      });
    }, onError: (e) {
      setState(() {
        _error = 'Failed to load tournament: $e';
        _loading = false;
      });
    });

    _matchesSub = _db
        .collection(AppConstants.matchesCollection)
        .where('tournamentId', isEqualTo: widget.tournamentId)
        .snapshots()
        .listen((matchSnap) {
      final matches = matchSnap.docs
          .map((doc) => MatchModel.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) {
          final r = a.round.compareTo(b.round);
          return r != 0 ? r : a.matchNumber.compareTo(b.matchNumber);
        });

      setState(() {
        _matches = matches;
        _matchesLoaded = true;
        _loading = !(_tournamentLoaded && _matchesLoaded);
        _error = null;
      });
    }, onError: (e) {
      setState(() {
        _error = 'Failed to load bracket: $e';
        _loading = false;
      });
    });
  }

  void _copyShareLink() {
    final url = Uri.base.resolve('/bracket/${widget.tournamentId}').toString();
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bracket link copied to clipboard!'),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64,
                          color: AppTheme.accentRed.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('B',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tournament!.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall,
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentCyan
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _tournament!.format.label,
                                        style: const TextStyle(
                                            color: AppTheme.accentCyan,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGreen
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _tournament!.status.label,
                                        style: const TextStyle(
                                            color: AppTheme.accentGreen,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_matches.length} matches',
                                      style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Share button
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _copyShareLink,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.share,
                                        size: 16, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text('Share',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(),

                      const SizedBox(height: 8),

                      // Powered by BSEMS
                      Text(
                        'Powered by BSEMS — Barangay Sports & Esports Management System',
                        style: TextStyle(
                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 32),

                      // Bracket View
                      if (_matches.isEmpty)
                        GlassCard(
                          child: const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No bracket generated yet',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 14),
                              ),
                            ),
                          ),
                        )
                      else
                        _buildBracket(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBracket() {
    if (_tournament!.format == TournamentFormat.roundRobin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoundRobinSchedule(),
          const SizedBox(height: 28),
          _sectionHeader('Standings', AppTheme.accentCyan),
          const SizedBox(height: 12),
          _buildRoundRobinStandings(),
        ],
      );
    }

    if (_tournament!.format == TournamentFormat.doubleElimination) {
      final winnersMatches = _matches
          .where((m) => m.bracketType == BracketTypes.winners)
          .toList();
      final losersMatches = _matches
          .where((m) => m.bracketType == BracketTypes.losers)
          .toList();
      final grandFinalsMatches = _matches
          .where((m) =>
              m.bracketType == BracketTypes.grandFinals ||
              m.bracketType == BracketTypes.grandFinalsReset)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (winnersMatches.isNotEmpty) ...[
            _sectionHeader('Winners Bracket', AppTheme.accentCyan),
            const SizedBox(height: 12),
            BracketTreeView(
              matches: winnersMatches,
              canManage: false,
              accentColor: AppTheme.accentCyan,
              onScore: (_) {},
            ),
            const SizedBox(height: 28),
          ],
          if (losersMatches.isNotEmpty) ...[
            _sectionHeader('Losers Bracket', AppTheme.accentOrange),
            const SizedBox(height: 12),
            BracketTreeView(
              matches: losersMatches,
              canManage: false,
              accentColor: AppTheme.accentOrange,
              onScore: (_) {},
            ),
            const SizedBox(height: 28),
          ],
          if (grandFinalsMatches.isNotEmpty) ...[
            _sectionHeader('Grand Finals', AppTheme.accentPurple),
            const SizedBox(height: 12),
            BracketTreeView(
              matches: grandFinalsMatches,
              canManage: false,
              accentColor: AppTheme.accentPurple,
              onScore: (_) {},
            ),
          ],
        ],
      );
    }

    return BracketTreeView(
      matches: _matches
          .where((m) => m.bracketType != BracketTypes.roundRobin)
          .toList(),
      canManage: false,
      accentColor: AppTheme.accentCyan,
      onScore: (_) {},
    );
  }

  Widget _buildRoundRobinSchedule() {
    final rounds = <int, List<MatchModel>>{};
    for (final match in _matches) {
      rounds.putIfAbsent(match.round, () => []).add(match);
    }
    final sortedRounds = rounds.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final round in sortedRounds)
            Container(
              width: 260,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Round $round', AppTheme.accentCyan),
                  const SizedBox(height: 12),
                  for (final match in rounds[round]!..sort(
                      (a, b) => a.matchNumber.compareTo(b.matchNumber),
                    ))
                    _PublicMatchCard(match: match),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundRobinStandings() {
    final standings = <String, _PublicStanding>{};

    void ensureTeam(String? id, String? name) {
      if (id == null || name == null || name == 'TBD' || name == 'BYE') return;
      standings.putIfAbsent(id, () => _PublicStanding(name));
    }

    for (final match in _matches) {
      ensureTeam(match.team1Id, match.team1Name);
      ensureTeam(match.team2Id, match.team2Name);
      if (match.status != MatchStatus.completed ||
          match.team1Id == null ||
          match.team2Id == null) {
        continue;
      }

      final team1 = standings[match.team1Id]!;
      final team2 = standings[match.team2Id]!;
      team1.played++;
      team2.played++;
      team1.pointsFor += match.score1;
      team1.pointsAgainst += match.score2;
      team2.pointsFor += match.score2;
      team2.pointsAgainst += match.score1;

      if (match.score1 == match.score2) {
        team1.draws++;
        team2.draws++;
      } else if (match.score1 > match.score2) {
        team1.wins++;
        team2.losses++;
      } else {
        team2.wins++;
        team1.losses++;
      }
    }

    final rows = standings.values.toList()
      ..sort((a, b) {
        final points = b.points.compareTo(a.points);
        if (points != 0) return points;
        final diff = b.differential.compareTo(a.differential);
        if (diff != 0) return diff;
        return b.wins.compareTo(a.wins);
      });

    return GlassCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingTextStyle: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          dataTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
          ),
          columns: const [
            DataColumn(label: Text('Team')),
            DataColumn(label: Text('P')),
            DataColumn(label: Text('W')),
            DataColumn(label: Text('D')),
            DataColumn(label: Text('L')),
            DataColumn(label: Text('Diff')),
            DataColumn(label: Text('Pts')),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  DataCell(Text(row.name)),
                  DataCell(Text('${row.played}')),
                  DataCell(Text('${row.wins}')),
                  DataCell(Text('${row.draws}')),
                  DataCell(Text('${row.losses}')),
                  DataCell(Text('${row.differential}')),
                  DataCell(
                    Text(
                      '${row.points}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PublicMatchCard extends StatelessWidget {
  final MatchModel match;

  const _PublicMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.status == MatchStatus.completed;
    final statusColor = match.status == MatchStatus.live
        ? AppTheme.accentGreen
        : match.status == MatchStatus.cancelled
            ? AppTheme.textMuted
            : AppTheme.accentCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _PublicTeamRow(
            name: match.team1Name ?? 'TBD',
            score: match.score1,
            isWinner: isCompleted && match.winnerId == match.team1Id,
          ),
          const Divider(height: 16),
          _PublicTeamRow(
            name: match.team2Name ?? 'TBD',
            score: match.score2,
            isWinner: isCompleted && match.winnerId == match.team2Id,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                match.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicTeamRow extends StatelessWidget {
  final String name;
  final int score;
  final bool isWinner;

  const _PublicTeamRow({
    required this.name,
    required this.score,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWinner ? AppTheme.accentGreen : AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$score',
          style: TextStyle(
            color: isWinner ? AppTheme.accentGreen : AppTheme.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PublicStanding {
  final String name;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;

  _PublicStanding(this.name);

  int get points => wins * 3 + draws;
  int get differential => pointsFor - pointsAgainst;
}
