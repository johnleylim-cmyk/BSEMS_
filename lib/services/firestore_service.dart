import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/athlete_model.dart';
import '../models/team_model.dart';
import '../models/sport_model.dart';
import '../models/tournament_model.dart';
import '../models/match_model.dart';
import '../models/schedule_model.dart';
import '../models/announcement_model.dart';
import '../models/venue_model.dart';
import '../models/leaderboard_entry_model.dart';
import '../providers/activity_provider.dart';

/// Central Firestore CRUD service for all collections.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════
  // ATHLETES
  // ═══════════════════════════════════════════════════════════════════
  CollectionReference get _athletes =>
      _db.collection(AppConstants.athletesCollection);

  Future<String> addAthlete(AthleteModel athlete) async {
    final doc = await _athletes.add(athlete.toMap());
    return doc.id;
  }

  Future<void> updateAthlete(String id, Map<String, dynamic> data) =>
      _athletes.doc(id).update(data);

  Future<void> deleteAthlete(String id) => _athletes.doc(id).delete();

  Stream<List<AthleteModel>> streamAthletes({int? limit}) {
    Query query = _athletes.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
          (snap) => snap.docs
              .map((doc) =>
                  AthleteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Raw snapshot stream for athletes (enables cursor tracking for pagination).
  Stream<QuerySnapshot> streamAthletesRaw({int? limit}) {
    Query query = _athletes.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots();
  }

  Future<List<AthleteModel>> getAthletes() async {
    final snap = await _athletes.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) =>
            AthleteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Paginated fetch for athletes.
  Future<({List<AthleteModel> items, DocumentSnapshot? lastDoc})>
      getAthletesPaginated({DocumentSnapshot? startAfter, int limit = 20}) async {
    Query query = _athletes.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    return (
      items: snap.docs
          .map((d) => AthleteModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<AthleteModel?> getAthlete(String id) async {
    final doc = await _athletes.doc(id).get();
    if (!doc.exists) return null;
    return AthleteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ═══════════════════════════════════════════════════════════════════
  // TEAMS
  // ═══════════════════════════════════════════════════════════════════
  CollectionReference get _teams =>
      _db.collection(AppConstants.teamsCollection);

  Future<String> addTeam(TeamModel team) async {
    final doc = await _teams.add(team.toMap());
    return doc.id;
  }

  Future<void> updateTeam(String id, Map<String, dynamic> data) =>
      _teams.doc(id).update(data);

  Future<void> deleteTeam(String id) => _teams.doc(id).delete();

  Stream<List<TeamModel>> streamTeams({int? limit}) {
    Query query = _teams.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
          (snap) => snap.docs
              .map((doc) =>
                  TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  Future<List<TeamModel>> getTeams() async {
    final snap = await _teams.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) =>
            TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Raw snapshot stream for teams (enables cursor tracking for pagination).
  Stream<QuerySnapshot> streamTeamsRaw({int? limit}) {
    Query query = _teams.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots();
  }

  /// Paginated fetch for teams.
  Future<({List<TeamModel> items, DocumentSnapshot? lastDoc})>
      getTeamsPaginated({DocumentSnapshot? startAfter, int limit = 20}) async {
    Query query = _teams.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    return (
      items: snap.docs
          .map((d) => TeamModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<TeamModel?> getTeam(String id) async {
    final doc = await _teams.doc(id).get();
    if (!doc.exists) return null;
    return TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ═══════════════════════════════════════════════════════════════════
  // SPORTS
  // ═══════════════════════════════════════════════════════════════════
  CollectionReference get _sports =>
      _db.collection(AppConstants.sportsCollection);

  Future<String> addSport(SportModel sport) async {
    final doc = await _sports.add(sport.toMap());
    return doc.id;
  }

  Future<void> updateSport(String id, Map<String, dynamic> data) =>
      _sports.doc(id).update(data);

  Future<void> deleteSport(String id) => _sports.doc(id).delete();

  Stream<List<SportModel>> streamSports() {
    return _sports.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((doc) =>
                  SportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  Future<List<SportModel>> getSports() async {
    final snap = await _sports.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) =>
            SportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOURNAMENTS
  // ═══════════════════════════════════════════════════════════════════
  CollectionReference get _tournaments =>
      _db.collection(AppConstants.tournamentsCollection);

  Future<String> addTournament(TournamentModel tournament) async {
    final doc = await _tournaments.add(tournament.toMap());
    return doc.id;
  }

  Future<void> updateTournament(String id, Map<String, dynamic> data) =>
      _tournaments.doc(id).update(data);

  Future<void> deleteTournament(String id) => _tournaments.doc(id).delete();

  Future<void> deleteTournamentCascade(String id) async {
    final matches = await _matches.where('tournamentId', isEqualTo: id).get();
    final writes = <void Function(WriteBatch)>[
      for (final doc in matches.docs) (batch) => batch.delete(doc.reference),
      (batch) => batch.delete(_tournaments.doc(id)),
    ];
    await _commitWrites(writes);
  }

  Stream<List<TournamentModel>> streamTournaments() {
    return _tournaments
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => TournamentModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  Future<List<TournamentModel>> getTournaments() async {
    final snap =
        await _tournaments.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) => TournamentModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<TournamentModel?> getTournament(String id) async {
    final doc = await _tournaments.doc(id).get();
    if (!doc.exists) return null;
    return TournamentModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  // ═══════════════════════════════════════════════════════════════════
  // MATCHES
  // ═══════════════════════════════════════════════════════════════════
  CollectionReference get _matches =>
      _db.collection(AppConstants.matchesCollection);

  String newMatchId() => _matches.doc().id;

  Future<String> addMatch(MatchModel match) async {
    final doc = await _matches.add(match.toMap());
    return doc.id;
  }

  Future<void> updateMatch(String id, Map<String, dynamic> data) =>
      _matches.doc(id).update(data);

  Future<void> deleteMatch(String id) => _matches.doc(id).delete();

  Future<void> replaceTournamentMatches({
    required String tournamentId,
    required List<MatchModel> matches,
    required List<Map<String, dynamic>> bracketData,
    required Map<String, dynamic> tournamentData,
  }) async {
    final existing =
        await _matches.where('tournamentId', isEqualTo: tournamentId).get();

    final writes = <void Function(WriteBatch)>[
      for (final doc in existing.docs) (batch) => batch.delete(doc.reference),
      for (final match in matches)
        (batch) => batch.set(_matches.doc(match.id), match.toMap()),
      (batch) => batch.update(_tournaments.doc(tournamentId), {
            ...tournamentData,
            'bracket': bracketData,
            'bracketGeneratedAt': FieldValue.serverTimestamp(),
          }),
    ];

    await _commitWrites(writes);
  }

  Future<void> applyMatchUpdatesAndSyncBracket({
    required String? tournamentId,
    required Map<String, Map<String, dynamic>> matchUpdates,
  }) async {
    if (matchUpdates.isEmpty) return;

    if (tournamentId == null) {
      await _commitWrites([
        for (final entry in matchUpdates.entries)
          (batch) => batch.update(_matches.doc(entry.key), entry.value),
      ]);
      return;
    }

    final tournamentRef = _tournaments.doc(tournamentId);
    await _db.runTransaction((transaction) async {
      final tournamentSnap = await transaction.get(tournamentRef);

      for (final entry in matchUpdates.entries) {
        transaction.update(_matches.doc(entry.key), entry.value);
      }

      if (!tournamentSnap.exists) return;
      final data = tournamentSnap.data() as Map<String, dynamic>?;
      final rawBracket = data?['bracket'] as List<dynamic>?;
      if (rawBracket == null) return;

      var changed = false;
      final bracket = rawBracket.map((entry) {
        final map = Map<String, dynamic>.from(entry as Map);
        final update = matchUpdates[map['matchId']];
        if (update != null) {
          map.addAll(update);
          changed = true;
        }
        return map;
      }).toList();

      if (changed) {
        transaction.update(tournamentRef, {
          'bracket': bracket,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<List<MatchModel>> streamMatches({String? tournamentId, int? limit}) {
    Query query = _matches;
    if (tournamentId != null) {
      query = query.where('tournamentId', isEqualTo: tournamentId);
    }
    query = query.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
          (snap) => snap.docs
              .map((doc) =>
                  MatchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }
  /// Raw snapshot stream for matches (enables cursor tracking for pagination).
  Stream<QuerySnapshot> streamMatchesRaw({int? limit}) {
    Query query = _matches.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots();
  }

  /// Paginated fetch for matches.
  Future<({List<MatchModel> items, DocumentSnapshot? lastDoc})>
      getMatchesPaginated({DocumentSnapshot? startAfter, int limit = 20}) async {
    Query query = _matches.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    return (
      items: snap.docs
          .map((d) => MatchModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Stream<List<MatchModel>> streamMatchesByTournament(String tournamentId) {
    return _matches
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('round')
        .orderBy('matchNumber')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) =>
                  MatchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  Future<List<MatchModel>> getMatchesByTournament(String tournamentId) async {
    final snap = await _matches
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('round')
        .orderBy('matchNumber')
        .get();
    return snap.docs
        .map((doc) =>
            MatchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCHEDULES
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _commitWrites(List<void Function(WriteBatch)> writes) async {
    const chunkSize = 450;
    for (var i = 0; i < writes.length; i += chunkSize) {
      final batch = _db.batch();
      for (final write in writes.skip(i).take(chunkSize)) {
        write(batch);
      }
      await batch.commit();
    }
  }

  CollectionReference get _schedules =>
      _db.collection(AppConstants.schedulesCollection);

  Future<String> addSchedule(ScheduleModel schedule) async {
    final doc = await _schedules.add(schedule.toMap());
    return doc.id;
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) =>
      _schedules.doc(id).update(data);

  Future<void> deleteSchedule(String id) => _schedules.doc(id).delete();

  Stream<List<ScheduleModel>> streamSchedules() {
    return _schedules.orderBy('date', descending: false).snapshots().map(
          (snap) => snap.docs
              .map((doc) => ScheduleModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ═══════════════════════════════════════════════════════════════════
  CollectionReference get _announcements =>
      _db.collection(AppConstants.announcementsCollection);

  Future<String> addAnnouncement(AnnouncementModel announcement) async {
    final doc = await _announcements.add(announcement.toMap());
    return doc.id;
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) =>
      _announcements.doc(id).update(data);

  Future<void> deleteAnnouncement(String id) =>
      _announcements.doc(id).delete();

  Stream<List<AnnouncementModel>> streamAnnouncements({int? limit}) {
    Query query = _announcements.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
          (snap) => snap.docs
              .map((doc) => AnnouncementModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }
  /// Raw snapshot stream for announcements (enables cursor tracking for pagination).
  Stream<QuerySnapshot> streamAnnouncementsRaw({int? limit}) {
    Query query = _announcements.orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots();
  }

  /// Paginated fetch for announcements.
  Future<({List<AnnouncementModel> items, DocumentSnapshot? lastDoc})>
      getAnnouncementsPaginated({DocumentSnapshot? startAfter, int limit = 20}) async {
    Query query = _announcements.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    return (
      items: snap.docs
          .map((d) => AnnouncementModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // VENUES
  // ═══════════════════════════════════════════════════════════════════
  CollectionReference get _venues =>
      _db.collection(AppConstants.venuesCollection);

  Future<String> addVenue(VenueModel venue) async {
    final doc = await _venues.add(venue.toMap());
    return doc.id;
  }

  Future<void> updateVenue(String id, Map<String, dynamic> data) =>
      _venues.doc(id).update(data);

  Future<void> deleteVenue(String id) => _venues.doc(id).delete();

  Stream<List<VenueModel>> streamVenues() {
    return _venues.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((doc) =>
                  VenueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  Future<List<VenueModel>> getVenues() async {
    final snap = await _venues.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) =>
            VenueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // LEADERBOARD
  // ═══════════════════════════════════════════════════════════════════
  CollectionReference get _leaderboard =>
      _db.collection(AppConstants.leaderboardCollection);

  Future<String> addLeaderboardEntry(LeaderboardEntryModel entry) async {
    final doc = await _leaderboard.add(entry.toMap());
    return doc.id;
  }

  Future<void> updateLeaderboardEntry(
          String id, Map<String, dynamic> data) =>
      _leaderboard.doc(id).update(data);

  Stream<List<LeaderboardEntryModel>> streamLeaderboard({String? sportId}) {
    Query query = _leaderboard.orderBy('points', descending: true);
    if (sportId != null) {
      query = query.where('sportId', isEqualTo: sportId);
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .map((doc) => LeaderboardEntryModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SETTINGS (barangay name, etc.)
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getSettings() async {
    final doc = await _db
        .collection(AppConstants.settingsCollection)
        .doc('general')
        .get();
    return doc.data() ?? {};
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.settingsCollection)
        .doc('general')
        .set(data, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, int>> getDashboardCounts() async {
    final results = await Future.wait([
      _athletes.count().get(),
      _teams.count().get(),
      _tournaments.count().get(),
      _matches.count().get(),
      _sports.count().get(),
      _venues.count().get(),
    ]);

    return {
      'athletes': results[0].count ?? 0,
      'teams': results[1].count ?? 0,
      'tournaments': results[2].count ?? 0,
      'matches': results[3].count ?? 0,
      'sports': results[4].count ?? 0,
      'venues': results[5].count ?? 0,
    };
  }

  // ═══════════════════════════════════════════════════════════════════
  // ACTIVITY LOG
  // ═══════════════════════════════════════════════════════════════════
  CollectionReference get _activityLog =>
      _db.collection(AppConstants.activityLogCollection);

  /// Write a single activity log entry.
  Future<void> logActivity({
    required String type,
    required String action,
    required String title,
    String? subtitle,
  }) async {
    await _activityLog.add({
      'type': type,
      'action': action,
      'title': title,
      'subtitle': subtitle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream the most recent activity log entries.
  Stream<List<ActivityItem>> streamActivityLog({int limit = 15}) {
    return _activityLog
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ActivityItem.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
