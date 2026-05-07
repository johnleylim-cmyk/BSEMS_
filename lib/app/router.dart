import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/athletes/athletes_list_screen.dart';
import '../screens/teams/teams_list_screen.dart';
import '../screens/tournaments/tournaments_list_screen.dart';
import '../screens/tournaments/tournament_detail_screen.dart';
import '../screens/tournaments/public_bracket_screen.dart';
import '../screens/matches/matches_list_screen.dart';
import '../screens/matches/match_scoring_screen.dart';
import '../screens/sports/sports_screen.dart';
import '../screens/venues/venues_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/announcements/announcements_screen.dart';
import '../screens/leaderboards/leaderboards_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/reports/reports_screen.dart';

/// Routes that require at least manager role.
const _managerRoutes = ['/sports', '/venues', '/reports'];

/// Routes that require admin role.
const _adminRoutes = ['/settings'];

/// Routes that are publicly accessible (no auth required).
const _publicRoutes = ['/login', '/register', '/bracket'];

/// Custom fade-slide page transition for premium feel.
CustomTransitionPage<void> _buildTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.02, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

/// GoRouter configuration with auth + role-guarded routes and page transitions.
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';
      final isPublicRoute = _publicRoutes.any((r) => location.startsWith(r));

      // 1. Allow public routes through
      if (isPublicRoute && !isAuthRoute) return null;

      // 2. Auth guard — block unauthenticated users
      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/dashboard';

      // 3. Role guard — block unauthorized role access
      if (isAuth) {
        // Admin-only routes
        if (_adminRoutes.any((r) => location.startsWith(r)) &&
            !authProvider.isAdmin) {
          return '/dashboard';
        }
        // Manager-only routes
        if (_managerRoutes.any((r) => location.startsWith(r)) &&
            !authProvider.isManager) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      // ── Auth routes (no shell) ──
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const RegisterScreen(),
        ),
      ),

      // ── Public bracket view (no auth, no shell) ──
      GoRoute(
        path: '/bracket/:id',
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: PublicBracketScreen(
            tournamentId: state.pathParameters['id']!,
          ),
        ),
      ),

      // ── Main app (with shell/sidebar) ──
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/athletes',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const AthletesListScreen(),
            ),
          ),
          GoRoute(
            path: '/teams',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const TeamsListScreen(),
            ),
          ),
          GoRoute(
            path: '/tournaments',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const TournamentsListScreen(),
            ),
          ),
          GoRoute(
            path: '/tournaments/:id',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: TournamentDetailScreen(
                tournamentId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/matches',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const MatchesListScreen(),
            ),
          ),
          GoRoute(
            path: '/matches/:id/score',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: MatchScoringScreen(
                matchId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/sports',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const SportsScreen(),
            ),
          ),
          GoRoute(
            path: '/venues',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const VenuesScreen(),
            ),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const ScheduleScreen(),
            ),
          ),
          GoRoute(
            path: '/announcements',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const AnnouncementsScreen(),
            ),
          ),
          GoRoute(
            path: '/leaderboards',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const LeaderboardsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => _buildTransitionPage(
              state: state,
              child: const ReportsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
