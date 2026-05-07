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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tournamentDoc = await _db
          .collection(AppConstants.tournamentsCollection)
          .doc(widget.tournamentId)
          .get();

      if (!tournamentDoc.exists) {
        setState(() {
          _error = 'Tournament not found';
          _loading = false;
        });
        return;
      }

      _tournament = TournamentModel.fromMap(
        tournamentDoc.data() as Map<String, dynamic>,
        tournamentDoc.id,
      );

      final matchSnap = await _db
          .collection(AppConstants.matchesCollection)
          .where('tournamentId', isEqualTo: widget.tournamentId)
          .get();

      _matches = matchSnap.docs
          .map((doc) =>
              MatchModel.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) {
          final r = a.round.compareTo(b.round);
          return r != 0 ? r : a.matchNumber.compareTo(b.matchNumber);
        });

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load bracket: $e';
        _loading = false;
      });
    }
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
    if (_tournament!.format == TournamentFormat.doubleElimination) {
      final winnersMatches = _matches
          .where((m) => m.bracketType == BracketTypes.winners)
          .toList();
      final losersMatches = _matches
          .where((m) => m.bracketType == BracketTypes.losers)
          .toList();
      final grandFinalsMatches = _matches
          .where((m) => m.bracketType == BracketTypes.grandFinals)
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
