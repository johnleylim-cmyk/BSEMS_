import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/team_model.dart';
import '../services/firestore_service.dart';

/// Team state provider with real-time streaming and pagination.
class TeamProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<TeamModel> _teams = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  StreamSubscription? _sub;
  DocumentSnapshot? _lastDocument;

  List<TeamModel> get teams => _teams;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get count => _teams.length;

  static const _pageSize = AppConstants.defaultPageSize;

  /// Look up a team's logo by its ID. Returns null if not found.
  String? getLogoForTeam(String? teamId) {
    if (teamId == null) return null;
    for (final team in _teams) {
      if (team.id == teamId) return team.logo;
    }
    return null;
  }

  void startListening() {
    _isLoading = true;
    _hasMore = true;
    _lastDocument = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _service.streamTeamsRaw(limit: _pageSize).listen(
      (snap) {
        _teams = snap.docs
            .map((doc) =>
                TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        if (snap.docs.isNotEmpty) {
          _lastDocument = snap.docs.last;
        }
        _isLoading = false;
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

  /// Load the next page of teams.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.getTeamsPaginated(
        startAfter: _lastDocument,
        limit: _pageSize,
      );
      if (result.items.isNotEmpty) {
        final existingIds = _teams.map((t) => t.id).toSet();
        final newItems =
            result.items.where((t) => !existingIds.contains(t.id)).toList();
        _teams = [..._teams, ...newItems];
        _lastDocument = result.lastDoc;
      }
      _hasMore = result.items.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<String> addTeam(TeamModel team) async {
    try {
      return await _service.addTeam(team);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<TeamModel>> fetchAllTeams() async {
    try {
      final teams = await _service.getTeams();
      _teams = teams;
      _hasMore = false;
      _error = null;
      notifyListeners();
      return teams;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTeam(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateTeam(id, data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTeam(String id) async {
    try {
      await _service.deleteTeam(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
