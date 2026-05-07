/// Application-wide constants for BSEMS.
class AppConstants {
  AppConstants._();

  static const String appName = 'BSEMS';
  static const String appFullName = 'Barangay Sports & Esports Management System';
  static const String appVersion = '1.0.0';

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String athletesCollection = 'athletes';
  static const String teamsCollection = 'teams';
  static const String sportsCollection = 'sports';
  static const String tournamentsCollection = 'tournaments';
  static const String matchesCollection = 'matches';
  static const String schedulesCollection = 'schedules';
  static const String announcementsCollection = 'announcements';
  static const String venuesCollection = 'venues';
  static const String leaderboardCollection = 'leaderboard_entries';
  static const String settingsCollection = 'settings';
  static const String activityLogCollection = 'activity_log';

  // Storage paths
  static const String athletePhotosPath = 'athlete_photos';
  static const String teamLogosPath = 'team_logos';
  static const String announcementImagesPath = 'announcement_images';
  static const String venueImagesPath = 'venue_images';

  // Pagination
  static const int defaultPageSize = 20;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 1000;
}
