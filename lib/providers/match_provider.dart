import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/bracket_generator.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import '../models/match_model.dart';
import '../services/firestore_service.dart';

class MatchProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<MatchModel> _matches = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  StreamSubscription? _sub;
  DocumentSnapshot? _lastDocument;

  List<MatchModel> get matches => _matches;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get count => _matches.length;

  static const _pageSize = AppConstants.defaultPageSize;

  void startListening({String? tournamentId}) {
    _isLoading = true;
    _hasMore = true;
    _lastDocument = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _service
        .streamMatchesRaw(limit: _pageSize)
        .listen(
          (snap) {
            _matches = snap.docs
                .map((doc) =>
                    MatchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .toList();
            if (snap.docs.isNotEmpty) {
              _lastDocument = snap.docs.last;
            }
            _isLoading = false;
            _error = null;
            _hasMore = snap.docs.length >= _pageSize;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Load the next page of matches.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.getMatchesPaginated(
        startAfter: _lastDocument,
        limit: _pageSize,
      );
      if (result.items.isNotEmpty) {
        final existingIds = _matches.map((m) => m.id).toSet();
        final newItems =
            result.items.where((m) => !existingIds.contains(m.id)).toList();
        _matches = [..._matches, ...newItems];
        _lastDocument = result.lastDoc;
      }
      _hasMore = result.items.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  void listenToTournamentMatches(String tournamentId) {
    _isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _service
        .streamMatchesByTournament(tournamentId)
        .listen(
          (data) {
            _matches = data;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void replaceTournamentMatchesLocally({
    required String tournamentId,
    required List<MatchModel> matches,
  }) {
    _matches = [
      for (final match in _matches)
        if (match.tournamentId != tournamentId) match,
      ...matches,
    ];
    _sortMatches();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> updateScore(
    String matchId,
    int score1,
    int score2, {
    bool allowCompletedEdit = false,
  }) async {
    if (score1 < 0 || score2 < 0) {
      throw ArgumentError('Scores cannot be negative');
    }

    final match = _findMatch(matchId);
    if (match == null) {
      throw StateError('Match not found');
    }
    if (match.status == MatchStatus.completed && allowCompletedEdit) {
      await completeMatch(
        matchId,
        score1,
        score2,
        null,
        allowCompletedEdit: true,
      );
      return;
    }
    if (match.status == MatchStatus.completed) {
      throw StateError('Completed matches cannot be edited');
    }
    if (match.team1Id == null || match.team2Id == null) {
      throw StateError('Both teams must be assigned before updating a score');
    }

    final updates = {
      matchId: {'score1': score1, 'score2': score2},
    };
    final previousMatches = List<MatchModel>.of(_matches);
    _applyLocalUpdates(updates);

    try {
      await _service.applyMatchUpdatesAndSyncBracket(
        tournamentId: match.tournamentId,
        matchUpdates: updates,
      );
      _error = null;
    } catch (e) {
      _matches = previousMatches;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> completeMatch(
    String matchId,
    int score1,
    int score2,
    String? winnerId, {
    bool allowCompletedEdit = false,
  }) async {
    if (score1 < 0 || score2 < 0) {
      throw ArgumentError('Scores cannot be negative');
    }

    final match = _findMatch(matchId);
    if (match == null) {
      throw StateError('Match not found');
    }
    if (match.status == MatchStatus.completed && !allowCompletedEdit) {
      throw StateError('This match is already completed');
    }
    if (match.team1Id == null || match.team2Id == null) {
      throw StateError('Both teams must be assigned before completing a match');
    }

    final allowsDraw = match.bracketType == BracketTypes.roundRobin;
    String? resolvedWinnerId;

    if (score1 == score2) {
      if (!allowsDraw) {
        throw ArgumentError('Bracket matches cannot end in a tie');
      }
      resolvedWinnerId = null;
    } else {
      resolvedWinnerId = score1 > score2 ? match.team1Id : match.team2Id;
      if (winnerId != null &&
          winnerId.isNotEmpty &&
          winnerId != resolvedWinnerId) {
        throw ArgumentError('Winner does not match the submitted score');
      }
    }

    if (match.status == MatchStatus.completed &&
        match.winnerId != resolvedWinnerId &&
        _hasLockedDownstream(match)) {
      throw StateError(
        'This result feeds into a match that has already started or finished',
      );
    }

    final updates = <String, Map<String, dynamic>>{
      match.id: {
        'score1': score1,
        'score2': score2,
        'winnerId': resolvedWinnerId,
        'status': MatchStatus.completed.name,
      },
    };

    if (resolvedWinnerId != null) {
      final winnerName = resolvedWinnerId == match.team1Id
          ? match.team1Name
          : match.team2Name;
      final loserId = resolvedWinnerId == match.team1Id
          ? match.team2Id
          : match.team1Id;
      final loserName = resolvedWinnerId == match.team1Id
          ? match.team2Name
          : match.team1Name;

      if (winnerName == null || loserId == null || loserName == null) {
        throw StateError('Match teams are incomplete');
      }

      if (match.bracketType == BracketTypes.grandFinals &&
          match.nextMatchId != null) {
        _applyGrandFinalResetUpdate(
          updates,
          match: match,
          winnerId: resolvedWinnerId,
        );
      } else {
        _applyRouteUpdate(
          updates,
          targetMatchId: match.nextMatchId,
          targetSlot: match.nextMatchSlot,
          teamId: resolvedWinnerId,
          teamName: winnerName,
        );
      }

      if (match.bracketType == BracketTypes.winners) {
        _applyRouteUpdate(
          updates,
          targetMatchId: match.loserNextMatchId,
          targetSlot: match.loserNextMatchSlot,
          teamId: loserId,
          teamName: loserName,
        );
      }
    }

    final previousMatches = List<MatchModel>.of(_matches);
    _applyLocalUpdates(updates);

    try {
      await _service.applyMatchUpdatesAndSyncBracket(
        tournamentId: match.tournamentId,
        matchUpdates: updates,
      );
      _error = null;
    } catch (e) {
      _matches = previousMatches;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> startMatch(String matchId) async {
    final match = _findMatch(matchId);
    if (match == null) {
      throw StateError('Match not found');
    }
    if (match.status == MatchStatus.completed ||
        match.status == MatchStatus.cancelled) {
      throw StateError('This match cannot be started');
    }
    if (match.team1Id == null || match.team2Id == null) {
      throw StateError('Both teams must be assigned before starting a match');
    }

    final updates = {
      matchId: {'status': MatchStatus.live.name},
    };
    final previousMatches = List<MatchModel>.of(_matches);
    _applyLocalUpdates(updates);

    try {
      await _service.applyMatchUpdatesAndSyncBracket(
        tournamentId: match.tournamentId,
        matchUpdates: updates,
      );
      _error = null;
    } catch (e) {
      _matches = previousMatches;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMatch(String id) async {
    final match = _findMatch(id);
    final previousMatches = List<MatchModel>.of(_matches);
    _matches = _matches.where((match) => match.id != id).toList();
    notifyListeners();

    try {
      if (match == null) {
        await _service.deleteMatch(id);
      } else {
        await _service.deleteMatchAndSyncBracket(match);
      }
      _error = null;
    } catch (e) {
      _matches = previousMatches;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  MatchModel? _findMatch(String matchId) {
    return _matches.where((match) => match.id == matchId).firstOrNull;
  }

  bool _hasLockedDownstream(MatchModel match) {
    final targetIds = {
      if (match.nextMatchId != null) match.nextMatchId!,
      if (match.loserNextMatchId != null) match.loserNextMatchId!,
    };
    for (final targetId in targetIds) {
      final target = _findMatch(targetId);
      if (target == null) continue;
      if (target.status == MatchStatus.live ||
          target.status == MatchStatus.completed) {
        return true;
      }
    }
    return false;
  }

  void _applyGrandFinalResetUpdate(
    Map<String, Map<String, dynamic>> updates, {
    required MatchModel match,
    required String winnerId,
  }) {
    final targetMatchId = match.nextMatchId;
    if (targetMatchId == null) return;

    final resetUpdate = updates.putIfAbsent(targetMatchId, () => {});
    if (winnerId == match.team2Id) {
      resetUpdate.addAll({
        'team1Id': match.team1Id,
        'team1Name': match.team1Name,
        'team2Id': match.team2Id,
        'team2Name': match.team2Name,
        'score1': 0,
        'score2': 0,
        'winnerId': null,
        'status': MatchStatus.scheduled.name,
      });
    } else {
      resetUpdate.addAll({
        'team1Id': null,
        'team1Name': 'Not Needed',
        'team2Id': null,
        'team2Name': 'Not Needed',
        'score1': 0,
        'score2': 0,
        'winnerId': null,
        'status': MatchStatus.cancelled.name,
      });
    }
  }

  void _applyRouteUpdate(
    Map<String, Map<String, dynamic>> updates, {
    required String? targetMatchId,
    required int? targetSlot,
    required String teamId,
    required String teamName,
  }) {
    if (targetMatchId == null || targetSlot == null) return;
    if (targetSlot != 1 && targetSlot != 2) {
      throw StateError('Invalid bracket target slot: $targetSlot');
    }

    final targetUpdate = updates.putIfAbsent(targetMatchId, () => {});
    if (targetSlot == 1) {
      targetUpdate['team1Id'] = teamId;
      targetUpdate['team1Name'] = teamName;
    } else {
      targetUpdate['team2Id'] = teamId;
      targetUpdate['team2Name'] = teamName;
    }
  }

  void _applyLocalUpdates(Map<String, Map<String, dynamic>> updates) {
    _matches = [
      for (final match in _matches)
        updates.containsKey(match.id)
            ? _matchWithUpdates(match, updates[match.id]!)
            : match,
    ];
    _sortMatches();
    notifyListeners();
  }

  MatchModel _matchWithUpdates(MatchModel match, Map<String, dynamic> update) {
    return MatchModel(
      id: match.id,
      tournamentId: update.containsKey('tournamentId')
          ? update['tournamentId'] as String?
          : match.tournamentId,
      round: update.containsKey('round') ? update['round'] as int : match.round,
      matchNumber: update.containsKey('matchNumber')
          ? update['matchNumber'] as int
          : match.matchNumber,
      team1Id: update.containsKey('team1Id')
          ? update['team1Id'] as String?
          : match.team1Id,
      team2Id: update.containsKey('team2Id')
          ? update['team2Id'] as String?
          : match.team2Id,
      team1Name: update.containsKey('team1Name')
          ? update['team1Name'] as String?
          : match.team1Name,
      team2Name: update.containsKey('team2Name')
          ? update['team2Name'] as String?
          : match.team2Name,
      score1: update.containsKey('score1')
          ? update['score1'] as int
          : match.score1,
      score2: update.containsKey('score2')
          ? update['score2'] as int
          : match.score2,
      winnerId: update.containsKey('winnerId')
          ? update['winnerId'] as String?
          : match.winnerId,
      status: update.containsKey('status')
          ? MatchStatus.values.firstWhere(
              (status) => status.name == update['status'],
              orElse: () => match.status,
            )
          : match.status,
      scheduledAt: match.scheduledAt,
      venue: update.containsKey('venue')
          ? update['venue'] as String?
          : match.venue,
      notes: update.containsKey('notes')
          ? update['notes'] as String?
          : match.notes,
      bracketType: update.containsKey('bracketType')
          ? update['bracketType'] as String?
          : match.bracketType,
      nextMatchId: update.containsKey('nextMatchId')
          ? update['nextMatchId'] as String?
          : match.nextMatchId,
      nextMatchSlot: update.containsKey('nextMatchSlot')
          ? update['nextMatchSlot'] as int?
          : match.nextMatchSlot,
      loserNextMatchId: update.containsKey('loserNextMatchId')
          ? update['loserNextMatchId'] as String?
          : match.loserNextMatchId,
      loserNextMatchSlot: update.containsKey('loserNextMatchSlot')
          ? update['loserNextMatchSlot'] as int?
          : match.loserNextMatchSlot,
      createdAt: match.createdAt,
    );
  }

  void _sortMatches() {
    _matches.sort((a, b) {
      final tournamentOrder = (a.tournamentId ?? '').compareTo(
        b.tournamentId ?? '',
      );
      if (tournamentOrder != 0) return tournamentOrder;
      final roundOrder = a.round.compareTo(b.round);
      if (roundOrder != 0) return roundOrder;
      return a.matchNumber.compareTo(b.matchNumber);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
