import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../core/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/other_providers.dart';
import '../widgets/sidebar_nav.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/theme_toggle_button.dart';

/// Shell screen — wraps all authenticated routes with sidebar + bottom nav.
class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  /// All nav items with role requirements.
  /// [minRole] = null means visible to all authenticated users.
  static const _allNavItems = [
    NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      route: '/dashboard',
    ),
    NavItem(
      label: 'Athletes',
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      route: '/athletes',
    ),
    NavItem(
      label: 'Teams',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      route: '/teams',
    ),
    NavItem(
      label: 'Tournaments',
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      route: '/tournaments',
    ),
    NavItem(
      label: 'Matches',
      icon: Icons.sports_esports_outlined,
      activeIcon: Icons.sports_esports,
      route: '/matches',
    ),
    NavItem(
      label: 'Sports / Games',
      icon: Icons.sports_basketball_outlined,
      activeIcon: Icons.sports_basketball,
      route: '/sports',
      minRole: UserRole.manager,
    ),
    NavItem(
      label: 'Venues',
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on,
      route: '/venues',
      minRole: UserRole.manager,
    ),
    NavItem(
      label: 'Schedule',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      route: '/schedule',
    ),
    NavItem(
      label: 'Announcements',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign,
      route: '/announcements',
    ),
    NavItem(
      label: 'Leaderboards',
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard,
      route: '/leaderboards',
    ),
    NavItem(
      label: 'Reports',
      icon: Icons.picture_as_pdf_outlined,
      activeIcon: Icons.picture_as_pdf,
      route: '/reports',
      minRole: UserRole.manager,
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      route: '/settings',
      minRole: UserRole.admin,
    ),
  ];

  /// Filters nav items based on the user's role.
  static List<NavItem> _filterNavItems(UserRole? userRole) {
    return _allNavItems.where((item) {
      if (item.minRole == null) return true;
      if (userRole == null) return false;
      // Admin sees everything
      if (userRole == UserRole.admin) return true;
      // Manager sees manager+ items
      if (userRole == UserRole.manager &&
          (item.minRole == UserRole.manager || item.minRole == UserRole.viewer)) {
        return true;
      }
      // Viewer only sees items with no minRole (null) or viewer minRole
      if (userRole == UserRole.viewer && item.minRole == UserRole.viewer) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final authProvider = context.watch<AuthProvider>();
    final announcementProvider = context.watch<AnnouncementProvider>();
    final filteredNavItems = _filterNavItems(authProvider.user?.role);
    final unread = announcementProvider.unreadCount(
      authProvider.lastSeenAnnouncementsAt,
    );

    return ResponsiveLayout(
      // ── Desktop: Sidebar + Content ──
      desktop: Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: Row(
          children: [
            SidebarNav(
              items: filteredNavItems,
              currentRoute: currentRoute,
              barangayName: 'Sports & Esports',
              onLogout: () => _handleLogout(context, authProvider),
            ),
            Expanded(
              child: Column(
                children: [
                  // ── Top bar with notification bell + theme toggle ──
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.sfc(context).withValues(alpha: 0.5),
                      border: Border(
                        bottom: BorderSide(color: AppTheme.brd(context), width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        const ThemeToggleButton(),
                        const SizedBox(width: 12),
                        _NotificationBell(
                          unreadCount: unread,
                          onTap: () => context.go('/announcements'),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                              color: AppTheme.border, width: 0.5),
                        ),
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Mobile: Bottom Nav + Content ──
      mobile: Scaffold(
        backgroundColor: AppTheme.bg(context),
        appBar: AppBar(
          backgroundColor: AppTheme.sfc(context),
          elevation: 0,
          title: const Text('BSEMS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          actions: [
            const ThemeToggleButton(),
            const SizedBox(width: 8),
            _NotificationBell(
              unreadCount: unread,
              onTap: () => context.go('/announcements'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              top: BorderSide(
                  color: AppTheme.border.withValues(alpha: 0.5)),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.accentCyan,
            unselectedItemColor: AppTheme.textMuted,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            currentIndex: _getMobileIndex(currentRoute),
            onTap: (i) => _onMobileTap(context, i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people_outlined), label: 'Athletes'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_outlined),
                  label: 'Tournaments'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.sports_esports_outlined),
                  label: 'Matches'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz), label: 'More'),
            ],
          ),
        ),
        drawer: Drawer(
          backgroundColor: AppTheme.surface,
          child: SafeArea(
            child: SidebarNav(
              items: filteredNavItems,
              currentRoute: currentRoute,
              barangayName: 'Sports & Esports',
              onLogout: () => _handleLogout(context, authProvider),
            ),
          ),
        ),
      ),
    );
  }

  int _getMobileIndex(String route) {
    if (route.startsWith('/dashboard')) return 0;
    if (route.startsWith('/athletes')) return 1;
    if (route.startsWith('/tournaments')) return 2;
    if (route.startsWith('/matches')) return 3;
    return 4;
  }

  void _onMobileTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/athletes');
      case 2:
        context.go('/tournaments');
      case 3:
        context.go('/matches');
      case 4:
        Scaffold.of(context).openDrawer();
    }
  }

  void _handleLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
      if (context.mounted) context.go('/login');
    }
  }
}

/// Notification bell icon with animated badge.
class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationBell({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Announcements',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            unreadCount > 0
                ? Icons.notifications_active
                : Icons.notifications_outlined,
            color:
                unreadCount > 0 ? AppTheme.accentOrange : AppTheme.textMuted,
            size: 24,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentRed.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                constraints:
                    const BoxConstraints(minWidth: 18, minHeight: 14),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.15, duration: 800.ms),
            ),
        ],
      ),
      onPressed: onTap,
    );
  }
}
