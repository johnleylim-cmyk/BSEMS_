import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/athlete_model.dart';
import '../services/firestore_service.dart';

/// Athlete state provider with real-time streaming and pagination.
class AthleteProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<AthleteModel> _athletes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  StreamSubscription? _sub;
  DocumentSnapshot? _lastDocument;

  List<AthleteModel> get athletes => _athletes;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get count => _athletes.length;

  static const _pageSize = AppConstants.defaultPageSize;

  /// Start streaming athletes from Firestore (initial page).
  void startListening() {
    _isLoading = true;
    _hasMore = true;
    _lastDocument = null;
    notifyListeners();

    _sub?.cancel();
    _sub = _service.streamAthletesRaw(limit: _pageSize).listen(
      (snap) {
        _athletes = snap.docs
            .map((doc) =>
                AthleteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        // Capture the last document for cursor-based pagination
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

  /// Load the next page of athletes.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.getAthletesPaginated(
        startAfter: _lastDocument,
        limit: _pageSize,
      );
      if (result.items.isNotEmpty) {
        // Avoid duplicates from the real-time stream
        final existingIds = _athletes.map((a) => a.id).toSet();
        final newItems =
            result.items.where((a) => !existingIds.contains(a.id)).toList();
        _athletes = [..._athletes, ...newItems];
        _lastDocument = result.lastDoc;
      }
      _hasMore = result.items.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Add a new athlete.
  Future<String> addAthlete(AthleteModel athlete) async {
    try {
      final id = await _service.addAthlete(athlete);
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update an athlete.
  Future<void> updateAthlete(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateAthlete(id, data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete an athlete.
  Future<void> deleteAthlete(String id) async {
    try {
      await _service.deleteAthlete(id);
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
