import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

/// A single activity log entry.
class ActivityItem {
  final String id;
  final String type;      // 'athlete', 'team', 'tournament', 'match', 'announcement'
  final String action;    // 'created', 'updated', 'deleted', 'completed'
  final String title;
  final String? subtitle;
  final DateTime createdAt;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.action,
    required this.title,
    this.subtitle,
    required this.createdAt,
  });

  factory ActivityItem.fromMap(Map<String, dynamic> map, String id) {
    return ActivityItem(
      id: id,
      type: map['type'] ?? '',
      action: map['action'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'action': action,
        'title': title,
        'subtitle': subtitle,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Returns the icon for this activity type.
  IconData get icon {
    switch (type) {
      case 'athlete':
        return Icons.person;
      case 'team':
        return Icons.groups;
      case 'tournament':
        return Icons.emoji_events;
      case 'match':
        return Icons.sports_esports;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.info_outlined;
    }
  }

  /// Returns the accent color for this activity type.
  Color get color {
    switch (type) {
      case 'athlete':
        return const Color(0xFF00E5FF);
      case 'team':
        return const Color(0xFFB388FF);
      case 'tournament':
        return const Color(0xFFFFAB40);
      case 'match':
        return const Color(0xFF00E676);
      case 'announcement':
        return const Color(0xFFFF80AB);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  /// Human-readable action label.
  String get actionLabel {
    switch (action) {
      case 'created':
        return 'was created';
      case 'updated':
        return 'was updated';
      case 'deleted':
        return 'was deleted';
      case 'completed':
        return 'was completed';
      default:
        return action;
    }
  }
}

/// Streams recent activity log entries from Firestore.
class ActivityProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<ActivityItem> _activities = [];
  bool _isLoading = false;
  StreamSubscription? _sub;

  List<ActivityItem> get activities => _activities;
  bool get isLoading => _isLoading;

  void startListening({int limit = 15}) {
    _isLoading = true;
    notifyListeners();

    _sub?.cancel();
    _sub = _service.streamActivityLog(limit: limit).listen(
      (items) {
        _activities = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
