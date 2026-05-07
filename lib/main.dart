import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'providers/auth_provider.dart';
import 'providers/athlete_provider.dart';
import 'providers/team_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/match_provider.dart';
import 'providers/other_providers.dart';
import 'providers/theme_provider.dart';
import 'providers/activity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BSEMSApp());
}

class BSEMSApp extends StatelessWidget {
  const BSEMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(
          create: (_) => AthleteProvider()..startListening(),
        ),
        ChangeNotifierProvider(create: (_) => TeamProvider()..startListening()),
        ChangeNotifierProvider(
          create: (_) => TournamentProvider()..startListening(),
        ),
        ChangeNotifierProvider(
          create: (_) => MatchProvider()..startListening(),
        ),
        ChangeNotifierProvider(
          create: (_) => SportProvider()..startListening(),
        ),
        ChangeNotifierProvider(
          create: (_) => VenueProvider()..startListening(),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider()..startListening(),
        ),
        ChangeNotifierProvider(
          create: (_) => AnnouncementProvider()..startListening(),
        ),
        ChangeNotifierProvider(
          create: (_) => LeaderboardProvider()..startListening(),
        ),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => ActivityProvider()..startListening(),
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          final router = createRouter(authProvider);
          return MaterialApp.router(
            title: 'BSEMS — Barangay Sports & Esports Management',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
