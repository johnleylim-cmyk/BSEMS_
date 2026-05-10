import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../core/bracket_generator.dart';
import '../../core/enums.dart';
import '../../core/utils.dart';
import '../../providers/match_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/breadcrumb_bar.dart';
import 'package:go_router/go_router.dart';

class MatchScoringScreen extends StatefulWidget {
  final String matchId;
  const MatchScoringScreen({super.key, required this.matchId});
  @override
  State<MatchScoringScreen> createState() => _MatchScoringScreenState();
}

class _MatchScoringScreenState extends State<MatchScoringScreen> {
  final _s1Ctrl = TextEditingController();
  final _s2Ctrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final match = context
          .read<MatchProvider>()
          .matches
          .where((m) => m.id == widget.matchId)
          .firstOrNull;
      if (match != null) {
        _s1Ctrl.text = '${match.score1}';
        _s2Ctrl.text = '${match.score2}';
      }
    });
  }

  @override
  void dispose() {
    _s1Ctrl.dispose();
    _s2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchProv = context.watch<MatchProvider>();
    final auth = context.watch<AuthProvider>();
    final match = matchProv.matches
        .where((m) => m.id == widget.matchId)
        .firstOrNull;

    if (match == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_esports_outlined,
                size: 64,
                color: AppTheme.accentCyan.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Match Not Found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'This match may have been deleted or does not exist.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/matches'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final isCompleted = match.status == MatchStatus.completed;
    final isLive = match.status == MatchStatus.live;
    final hasTeams = match.team1Id != null && match.team2Id != null;
    final statusColor = AppUtils.statusColor(match.status.name);
    final teamProvider = context.watch<TeamProvider>();
    final team1Logo = teamProvider.getLogoForTeam(match.team1Id);
    final team2Logo = teamProvider.getLogoForTeam(match.team2Id);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb navigation
            BreadcrumbBar(items: [
              const BreadcrumbItem(label: 'Dashboard', route: '/dashboard'),
              const BreadcrumbItem(label: 'Matches', route: '/matches'),
              BreadcrumbItem(label: 'Match #${match.matchNumber}'),
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
                  onPressed: () => context.go('/matches'),
                ),
                const SizedBox(width: 8),
                Text(
                  'Match Scoring',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentGreen,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGreen.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        match.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(),

            const SizedBox(height: 32),

            // Match Info
            Row(
              children: [
                Text(
                  'Round ${match.round}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                if (match.matchNumber > 0) ...[
                  const Text(
                    ' / ',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  Text(
                    'Match #${match.matchNumber}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // Scoreboard
            GlassCard(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Team 1
                          Expanded(
                            child: Column(
                              children: [
                                AvatarBadge(
                                  name: match.team1Name ?? 'TBD',
                                  imageUrl: team1Logo,
                                  size: 64,
                                  showBorder: isCompleted && match.winnerId == match.team1Id,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  match.team1Name ?? 'TBD',
                                  style: TextStyle(
                                    color:
                                        isCompleted &&
                                            match.winnerId == match.team1Id
                                        ? AppTheme.accentGreen
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isCompleted &&
                                    match.winnerId == match.team1Id) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGreen.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'WINNER',
                                      style: TextStyle(
                                        color: AppTheme.accentGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // VS / Score
                          Column(
                            children: [
                              Text(
                                '${match.score1} - ${match.score2}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 36,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'VS',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          // Team 2
                          Expanded(
                            child: Column(
                              children: [
                                AvatarBadge(
                                  name: match.team2Name ?? 'TBD',
                                  imageUrl: team2Logo,
                                  size: 64,
                                  showBorder: isCompleted && match.winnerId == match.team2Id,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  match.team2Name ?? 'TBD',
                                  style: TextStyle(
                                    color:
                                        isCompleted &&
                                            match.winnerId == match.team2Id
                                        ? AppTheme.accentGreen
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isCompleted &&
                                    match.winnerId == match.team2Id) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGreen.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'WINNER',
                                      style: TextStyle(
                                        color: AppTheme.accentGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms)
                .scale(begin: const Offset(0.95, 0.95), duration: 400.ms),

            const SizedBox(height: 32),

            // Scoring Controls (Manager+ only)
            if (auth.isManager && hasTeams) ...[
              Text(
                isCompleted ? 'Correct Result' : 'Update Score',
                style: Theme.of(context).textTheme.headlineMedium,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                match.team1Name ?? 'TBD',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _s1Ctrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
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
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _s2Ctrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (!isCompleted && match.status == MatchStatus.scheduled) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _startMatch(context),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _saveScore(context),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save Score'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GradientButton(
                            label:
                                isCompleted ? 'Update Result' : 'Complete Match',
                            icon: Icons.check_circle,
                            isLoading: _saving,
                            onPressed: () => _completeMatch(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            ] else if (auth.isManager && !isCompleted && !hasTeams) ...[
              GlassCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_clock_outlined,
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This match is waiting for teams from earlier rounds.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
            ] else if (!auth.isManager && !isCompleted) ...[
              GlassCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outlined,
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Only managers can update scores',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveScore(BuildContext context) async {
    final s1 = int.tryParse(_s1Ctrl.text) ?? 0;
    final s2 = int.tryParse(_s2Ctrl.text) ?? 0;
    if (s1 < 0 || s2 < 0) {
      AppUtils.showError(context, 'Scores cannot be negative');
      return;
    }

    final match = context
        .read<MatchProvider>()
        .matches
        .where((m) => m.id == widget.matchId)
        .firstOrNull;
    if (match == null) {
      AppUtils.showError(context, 'Match not found');
      return;
    }
    if (match.team1Id == null || match.team2Id == null) {
      AppUtils.showError(
        context,
        'This match is waiting for teams from earlier rounds',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<MatchProvider>().updateScore(
        widget.matchId,
        s1,
        s2,
        allowCompletedEdit: match.status == MatchStatus.completed,
      );
      if (context.mounted) AppUtils.showSuccess(context, 'Score saved');
    } catch (e) {
      if (context.mounted) AppUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startMatch(BuildContext context) async {
    setState(() => _saving = true);
    try {
      await context.read<MatchProvider>().startMatch(widget.matchId);
      if (context.mounted) AppUtils.showSuccess(context, 'Match started');
    } catch (e) {
      if (context.mounted) AppUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _completeMatch(BuildContext context) async {
    final s1 = int.tryParse(_s1Ctrl.text) ?? 0;
    final s2 = int.tryParse(_s2Ctrl.text) ?? 0;
    if (s1 < 0 || s2 < 0) {
      AppUtils.showError(context, 'Scores cannot be negative');
      return;
    }

    final match = context
        .read<MatchProvider>()
        .matches
        .where((m) => m.id == widget.matchId)
        .firstOrNull;
    if (match == null) return;
    if (match.team1Id == null || match.team2Id == null) {
      AppUtils.showError(context, 'Both teams must be assigned first');
      return;
    }
    if (s1 == s2 && match.bracketType != BracketTypes.roundRobin) {
      AppUtils.showError(context, 'Bracket matches cannot end in a tie');
      return;
    }

    final winnerId = s1 == s2
        ? null
        : (s1 > s2 ? match.team1Id : match.team2Id);
    setState(() => _saving = true);
    try {
      await context.read<MatchProvider>().completeMatch(
        widget.matchId,
        s1,
        s2,
        winnerId,
        allowCompletedEdit: match.status == MatchStatus.completed,
      );
      if (context.mounted) AppUtils.showSuccess(context, 'Match completed!');
    } catch (e) {
      if (context.mounted) AppUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
