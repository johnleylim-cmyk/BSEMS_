import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/bracket_generator.dart';
import '../../core/enums.dart';
import '../../core/utils.dart';
import '../../models/tournament_model.dart';
import '../../models/match_model.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/bracket_tree_view.dart';
import '../../widgets/breadcrumb_bar.dart';
import '../../widgets/confetti_overlay.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});
  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  MatchProvider? _matchProvider;
  bool _confettiShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _matchProvider ??= context.read<MatchProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().listenToTournamentMatches(
        widget.tournamentId,
      );
    });
  }

  @override
  void dispose() {
    _matchProvider?.startListening();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    context.go('/tournaments');
  }

  @override
  Widget build(BuildContext context) {
    final tournamentProv = context.watch<TournamentProvider>();
    final matchProv = context.watch<MatchProvider>();
    final auth = context.watch<AuthProvider>();
    final tournament = tournamentProv.tournaments
        .where((t) => t.id == widget.tournamentId)
        .firstOrNull;
    if (tournament == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final matches =
        matchProv.matches
            .where((match) => match.tournamentId == widget.tournamentId)
            .toList()
          ..sort((a, b) {
            final roundOrder = a.round.compareTo(b.round);
            if (roundOrder != 0) return roundOrder;
            return a.matchNumber.compareTo(b.matchNumber);
          });
    final championHighlight = _resolveChampionHighlight(
      matches,
      tournament.format,
    );

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            BreadcrumbBar(items: [
              const BreadcrumbItem(label: 'Dashboard', route: '/dashboard'),
              const BreadcrumbItem(label: 'Tournaments', route: '/tournaments'),
              BreadcrumbItem(label: tournament.name),
            ]),
            const SizedBox(height: 8),

            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: () => _goBack(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppUtils.statusColor(
                                tournament.status.name,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tournament.status.label,
                              style: TextStyle(
                                color: AppUtils.statusColor(
                                  tournament.status.name,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tournament.format.label,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (tournament.status == TournamentStatus.draft &&
                    auth.isManager)
                  GradientButton(
                    label: 'Generate Bracket',
                    icon: Icons.account_tree,
                    onPressed: () => _generateBracket(context, tournament),
                  ),
                if (matches.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _ShareBracketButton(
                    tournamentId: widget.tournamentId,
                  ),
                ],
              ],
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Info Cards
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.groups,
                          color: AppTheme.accentCyan,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${tournament.teamIds.length}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Teams',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassCard(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.sports_esports,
                          color: AppTheme.accentPurple,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${matches.length}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Matches',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassCard(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: AppTheme.accentOrange,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tournament.prizePool ?? 'N/A',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Prize Pool',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),

            // Bracket Visualization
            if (matches.isNotEmpty) ...[
              if (championHighlight != null) ...[
                _ChampionBanner(
                  tournamentName: tournament.name,
                  highlight: championHighlight,
                  onFirstBuild: () {
                    if (!_confettiShown) {
                      _confettiShown = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) ConfettiOverlay.show(context);
                      });
                    }
                  },
                ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.04),
                const SizedBox(height: 20),
              ],
              Text(
                'Bracket',
                style: Theme.of(context).textTheme.headlineMedium,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),

              // Check if this is a double elimination tournament
              if (tournament.format == TournamentFormat.doubleElimination) ...[
                _buildDoubleEliminationBracket(matches, auth.isManager),
              ] else ...[
                // Single elimination and round robin use the bracket tree view.
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: BracketTreeView(
                    matches: matches.where((m) => m.bracketType != BracketTypes.roundRobin).toList(),
                    canManage: auth.isManager,
                    accentColor: AppTheme.accentCyan,
                    onScore: (m) => _scoreMatch(context, m),
                  ),
                ),
              ],
              if (tournament.format == TournamentFormat.roundRobin) ...[
                const SizedBox(height: 28),
                Text(
                  'Standings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                _buildRoundRobinStandings(matches),
              ],
            ] else if (tournament.status == TournamentStatus.draft) ...[
              const EmptyBracketState(),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the double elimination bracket UI with Winners, Losers, and Grand Finals sections.
  Widget _buildDoubleEliminationBracket(
    List<MatchModel> matches,
    bool canManage,
  ) {
    final winnersMatches = matches
        .where((m) => m.bracketType == BracketTypes.winners)
        .toList();
    final losersMatches = matches
        .where((m) => m.bracketType == BracketTypes.losers)
        .toList();
    final grandFinalsMatches = matches
        .where((m) => m.bracketType == BracketTypes.grandFinals)
        .toList();
    // Fallback: if no bracketType is set, show all matches flat
    final untaggedMatches = matches
        .where((m) => m.bracketType == null)
        .toList();

    if (winnersMatches.isEmpty && losersMatches.isEmpty) {
      // Old data without bracketType falls back to the flat display.
      final rounds = <int>{};
      for (final m in matches) {
        rounds.add(m.round);
      }
      final sortedRounds = rounds.toList()..sort();
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedRounds.map((round) {
            final roundMatches = matches.where((m) => m.round == round).toList()
              ..sort((a, b) => a.matchNumber.compareTo(b.matchNumber));
            return Container(
              width: 260,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      round == sortedRounds.last ? 'Finals' : 'Round $round',
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...roundMatches.map(
                    (m) => _BracketMatchCard(
                      match: m,
                      canManage: canManage,
                      onScore: () => _scoreMatch(context, m),
                      team1Logo: context.read<TeamProvider>().getLogoForTeam(m.team1Id),
                      team2Logo: context.read<TeamProvider>().getLogoForTeam(m.team2Id),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (winnersMatches.isNotEmpty) ...[
          _BracketSectionHeader(
            label: 'Winners Bracket',
            color: AppTheme.accentCyan,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: BracketTreeView(
              matches: winnersMatches,
              canManage: canManage,
              accentColor: AppTheme.accentCyan,
              onScore: (m) => _scoreMatch(context, m),
            ),
          ),
          const SizedBox(height: 28),
        ],

        if (losersMatches.isNotEmpty) ...[
          _BracketSectionHeader(
            label: 'Losers Bracket',
            color: AppTheme.accentOrange,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: BracketTreeView(
              matches: losersMatches,
              canManage: canManage,
              accentColor: AppTheme.accentOrange,
              onScore: (m) => _scoreMatch(context, m),
            ),
          ),
          const SizedBox(height: 28),
        ],

        if (grandFinalsMatches.isNotEmpty) ...[
          _BracketSectionHeader(
            label: 'Grand Finals',
            color: AppTheme.accentPurple,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: BracketTreeView(
              matches: grandFinalsMatches,
              canManage: canManage,
              accentColor: AppTheme.accentPurple,
              onScore: (m) => _scoreMatch(context, m),
            ),
          ),
        ],

        if (untaggedMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: BracketTreeView(
              matches: untaggedMatches,
              canManage: canManage,
              accentColor: AppTheme.accentCyan,
              onScore: (m) => _scoreMatch(context, m),
            ),
          ),
        ],
      ],
    );
  }

  _ChampionHighlight? _resolveChampionHighlight(
    List<MatchModel> matches,
    TournamentFormat format,
  ) {
    if (format == TournamentFormat.roundRobin || matches.isEmpty) {
      return null;
    }

    MatchModel? championshipMatch;
    if (format == TournamentFormat.doubleElimination) {
      final grandFinals =
          matches
              .where((match) => match.bracketType == BracketTypes.grandFinals)
              .toList()
            ..sort((a, b) {
              final roundOrder = a.round.compareTo(b.round);
              if (roundOrder != 0) return roundOrder;
              return a.matchNumber.compareTo(b.matchNumber);
            });
      if (grandFinals.isNotEmpty) {
        championshipMatch = grandFinals.last;
      }
    } else {
      final eliminationMatches =
          matches
              .where((match) => match.bracketType != BracketTypes.roundRobin)
              .toList()
            ..sort((a, b) {
              final roundOrder = a.round.compareTo(b.round);
              if (roundOrder != 0) return roundOrder;
              return a.matchNumber.compareTo(b.matchNumber);
            });
      if (eliminationMatches.isNotEmpty) {
        championshipMatch = eliminationMatches.last;
      }
    }

    if (championshipMatch == null ||
        championshipMatch.status != MatchStatus.completed ||
        championshipMatch.winnerId == null) {
      return null;
    }

    final winnerIsTeam1 =
        championshipMatch.winnerId == championshipMatch.team1Id;
    final championName = winnerIsTeam1
        ? championshipMatch.team1Name
        : championshipMatch.team2Name;
    final runnerUpName = winnerIsTeam1
        ? championshipMatch.team2Name
        : championshipMatch.team1Name;

    if (championName == null || runnerUpName == null) {
      return null;
    }

    return _ChampionHighlight(
      championName: championName,
      runnerUpName: runnerUpName,
      championScore: winnerIsTeam1
          ? championshipMatch.score1
          : championshipMatch.score2,
      runnerUpScore: winnerIsTeam1
          ? championshipMatch.score2
          : championshipMatch.score1,
      matchLabel: format == TournamentFormat.doubleElimination
          ? 'Grand Finals'
          : 'Championship Final',
    );
  }

  Widget _buildRoundRobinStandings(List<MatchModel> matches) {
    final standings = <String, _RoundRobinStanding>{};

    final teamProv = context.read<TeamProvider>();
    void ensureTeam(String? id, String? name) {
      if (id == null || name == null || name == 'TBD' || name == 'BYE') return;
      standings.putIfAbsent(id, () => _RoundRobinStanding(name, teamProv.getLogoForTeam(id)));
    }

    for (final match in matches) {
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

    if (rows.isEmpty) {
      return const Text(
        'Standings will appear after teams are assigned.',
        style: TextStyle(color: AppTheme.textMuted),
      );
    }

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
            DataColumn(label: Text('')),
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
                  DataCell(Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: AvatarBadge(name: row.name, imageUrl: row.logo, size: 28),
                  )),
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

  void _generateBracket(BuildContext context, TournamentModel tournament) {
    final teams = context
        .read<TeamProvider>()
        .teams
        .where(
          (team) =>
              tournament.sportId.isEmpty || team.sportId == tournament.sportId,
        )
        .toList();
    final selectedIds = <String>[];
    final selectedNames = <String>[];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Select Teams for Bracket'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: teams.isEmpty
                ? const Center(
                    child: Text('No eligible teams for this tournament sport.'),
                  )
                : ListView.builder(
                    itemCount: teams.length,
                    itemBuilder: (_, i) {
                      final t = teams[i];
                      final isSelected = selectedIds.contains(t.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(t.name),
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              selectedIds.add(t.id);
                              selectedNames.add(t.name);
                            } else {
                              final idx = selectedIds.indexOf(t.id);
                              if (idx >= 0) {
                                selectedIds.removeAt(idx);
                                selectedNames.removeAt(idx);
                              }
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedIds.length >= 2
                  ? () async {
                      Navigator.pop(ctx);
                      final matchProvider = context.read<MatchProvider>();
                      try {
                        await context
                            .read<TournamentProvider>()
                            .generateBracket(
                              tournamentId: widget.tournamentId,
                              teamIds: selectedIds,
                              teamNames: selectedNames,
                              format: tournament.format,
                              onLocalMatchesReady: (matches) {
                                matchProvider.replaceTournamentMatchesLocally(
                                  tournamentId: widget.tournamentId,
                                  matches: matches,
                                );
                              },
                            );
                        if (context.mounted) {
                          AppUtils.showSuccess(context, 'Bracket generated!');
                        }
                      } catch (e) {
                        matchProvider.listenToTournamentMatches(
                          widget.tournamentId,
                        );
                        if (context.mounted) {
                          AppUtils.showError(context, e.toString());
                        }
                      }
                    }
                  : null,
              child: Text('Generate (${selectedIds.length} teams)'),
            ),
          ],
        ),
      ),
    );
  }

  void _scoreMatch(BuildContext context, MatchModel match) {
    if (match.status == MatchStatus.completed) {
      AppUtils.showError(context, 'Completed matches cannot be edited');
      return;
    }
    if (match.team1Id == null || match.team2Id == null) {
      AppUtils.showError(
        context,
        'This match is waiting for teams from earlier rounds',
      );
      return;
    }

    final s1Ctrl = TextEditingController(text: '${match.score1}');
    final s2Ctrl = TextEditingController(text: '${match.score2}');

    int? readScore(TextEditingController controller) {
      final score = int.tryParse(controller.text.trim());
      if (score == null || score < 0) return null;
      return score;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.team1Name ?? 'TBD',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: s1Ctrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.team2Name ?? 'TBD',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: s2Ctrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () async {
              final s1 = readScore(s1Ctrl);
              final s2 = readScore(s2Ctrl);
              if (s1 == null || s2 == null) {
                AppUtils.showError(context, 'Scores must be zero or higher');
                return;
              }
              try {
                await context.read<MatchProvider>().updateScore(
                  match.id,
                  s1,
                  s2,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) AppUtils.showError(context, e.toString());
              }
            },
            child: const Text('Save Score'),
          ),
          ElevatedButton(
            onPressed: () async {
              final s1 = readScore(s1Ctrl);
              final s2 = readScore(s2Ctrl);
              if (s1 == null || s2 == null) {
                AppUtils.showError(context, 'Scores must be zero or higher');
                return;
              }
              if (match.team1Id == null || match.team2Id == null) {
                AppUtils.showError(
                  context,
                  'Both teams must be assigned first',
                );
                return;
              }
              if (s1 == s2 && match.bracketType != BracketTypes.roundRobin) {
                AppUtils.showError(
                  context,
                  'Bracket matches cannot end in a tie',
                );
                return;
              }

              final winnerId = s1 == s2
                  ? null
                  : (s1 > s2 ? match.team1Id : match.team2Id);
              try {
                await context.read<MatchProvider>().completeMatch(
                  match.id,
                  s1,
                  s2,
                  winnerId,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (context.mounted) {
                  AppUtils.showSuccess(context, 'Match completed!');
                }
              } catch (e) {
                if (context.mounted) AppUtils.showError(context, e.toString());
              }
            },
            child: const Text('Complete Match'),
          ),
        ],
      ),
    );
  }
}

class _RoundRobinStanding {
  final String name;
  final String? logo;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;

  _RoundRobinStanding(this.name, this.logo);

  int get points => wins * 3 + draws;
  int get differential => pointsFor - pointsAgainst;
}

class _ChampionHighlight {
  final String championName;
  final String runnerUpName;
  final int championScore;
  final int runnerUpScore;
  final String matchLabel;

  const _ChampionHighlight({
    required this.championName,
    required this.runnerUpName,
    required this.championScore,
    required this.runnerUpScore,
    required this.matchLabel,
  });
}

class _ChampionBanner extends StatelessWidget {
  final String tournamentName;
  final _ChampionHighlight highlight;
  final VoidCallback? onFirstBuild;

  const _ChampionBanner({
    required this.tournamentName,
    required this.highlight,
    this.onFirstBuild,
  });

  @override
  Widget build(BuildContext context) {
    onFirstBuild?.call();
    final titleStyle = Theme.of(context).textTheme.displaySmall;

    return GlassCard(
      glow: true,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          gradient: LinearGradient(
            colors: [
              AppTheme.accentOrange.withValues(alpha: 0.20),
              AppTheme.accentCyan.withValues(alpha: 0.10),
              Colors.white.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 760;
            final details = <Widget>[
              Text(
                'Tournament Champion',
                style: const TextStyle(
                  color: AppTheme.accentOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                highlight.championName,
                style: titleStyle?.copyWith(
                  fontSize: isCompact ? 28 : 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tournamentName,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ChampionMetaChip(
                    icon: Icons.workspace_premium,
                    label: highlight.matchLabel,
                  ),
                  _ChampionMetaChip(
                    icon: Icons.sports_score,
                    label:
                        '${highlight.championScore} - ${highlight.runnerUpScore}',
                  ),
                  _ChampionMetaChip(
                    icon: Icons.flag_outlined,
                    label: 'Def. ${highlight.runnerUpName}',
                  ),
                ],
              ),
            ];

            final trophy = Container(
              width: isCompact ? 70 : 84,
              height: isCompact ? 70 : 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentOrange.withValues(alpha: 0.95),
                    const Color(0xFFFFD180),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.24),
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFF2C1A00),
                size: 38,
              ),
            );

            final sideSummary = Column(
              crossAxisAlignment: isCompact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                const Text(
                  'Runner-up',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  highlight.runnerUpName,
                  textAlign: isCompact ? TextAlign.left : TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Final Result',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${highlight.championScore} - ${highlight.runnerUpScore}',
                  style: TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: isCompact ? 24 : 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  trophy,
                  const SizedBox(height: 18),
                  ...details,
                  const SizedBox(height: 18),
                  sideSummary,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                trophy,
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: details,
                  ),
                ),
                const SizedBox(width: 20),
                sideSummary,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChampionMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChampionMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BracketMatchCard extends StatelessWidget {
  final MatchModel match;
  final bool canManage;
  final VoidCallback onScore;
  final String? team1Logo;
  final String? team2Logo;
  const _BracketMatchCard({
    required this.match,
    required this.canManage,
    required this.onScore,
    this.team1Logo,
    this.team2Logo,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.status == MatchStatus.completed;
    final isLive = match.status == MatchStatus.live;
    final isWaiting = match.team1Id == null || match.team2Id == null;
    return GestureDetector(
      onTap: canManage && !isCompleted && !isWaiting ? onScore : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isLive ? AppTheme.accentGreen : AppTheme.border,
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
          children: [
            _TeamRow(
              name: match.team1Name ?? 'TBD',
              score: match.score1,
              isWinner: isCompleted && match.winnerId == match.team1Id,
              logo: team1Logo,
            ),
            const Divider(height: 16),
            _TeamRow(
              name: match.team2Name ?? 'TBD',
              score: match.score2,
              isWinner: isCompleted && match.winnerId == match.team2Id,
              logo: team2Logo,
            ),
            if (isLive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (isWaiting)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'WAITING FOR TEAMS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final int score;
  final bool isWinner;
  final String? logo;
  const _TeamRow({
    required this.name,
    required this.score,
    required this.isWinner,
    this.logo,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AvatarBadge(name: name, imageUrl: logo, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWinner ? AppTheme.accentGreen : AppTheme.textPrimary,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            color: isWinner ? AppTheme.accentGreen : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class EmptyBracketState extends StatelessWidget {
  const EmptyBracketState({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.account_tree_outlined,
            size: 64,
            color: AppTheme.accentCyan.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Bracket Generated',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Click "Generate Bracket" to auto-create the tournament bracket',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _BracketSectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _BracketSectionHeader({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Share bracket button — copies public bracket URL to clipboard.
class _ShareBracketButton extends StatefulWidget {
  final String tournamentId;
  const _ShareBracketButton({required this.tournamentId});

  @override
  State<_ShareBracketButton> createState() => _ShareBracketButtonState();
}

class _ShareBracketButtonState extends State<_ShareBracketButton> {
  bool _hovered = false;

  void _copyLink() {
    final url = Uri.base.resolve('/bracket/${widget.tournamentId}').toString();
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bracket link copied to clipboard!'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _copyLink,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.accentCyan.withValues(alpha: 0.15)
                : AppTheme.accentCyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.accentCyan.withValues(alpha: _hovered ? 0.4 : 0.2),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share_outlined, size: 16, color: AppTheme.accentCyan),
              SizedBox(width: 6),
              Text(
                'Share Bracket',
                style: TextStyle(
                  color: AppTheme.accentCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
