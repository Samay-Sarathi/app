import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/models/user_role.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/driver/driver_dashboard_screen.dart';
import '../features/trip/screens/emergency_case_screen.dart';
import '../features/trip/screens/severity_rating_screen.dart';
import '../features/trip/screens/hospital_selection_screen.dart';
import '../features/trip/screens/navigation_screen.dart';
import '../features/trip/screens/arrival_screen.dart';
import '../features/hospital/screens/emergency_alert_screen.dart';
import '../features/hospital/screens/ambulance_sync_screen.dart';
import '../features/paramedic/paramedic_scan_screen.dart';
import '../features/paramedic/paramedic_vitals_screen.dart';
import '../features/hospital/hospital_dashboard_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/police/police_dashboard_screen.dart';
import '../shared/screens/about_screen.dart';
import '../shared/screens/terms_screen.dart';

/// Routes that don't require authentication.
const _publicPaths = {'/', '/roles', '/sign-in', '/register', '/about', '/terms', '/paramedic/scan', '/paramedic/vitals'};

/// Allowed route prefixes per role.
const _roleRoutes = <UserRole, List<String>>{
  UserRole.driver: ['/driver/'],
  UserRole.hospital: ['/hospital/'],
  UserRole.police: ['/police/'],
  UserRole.admin: ['/admin/'],
};

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final auth = context.read<AuthProvider>();
      final path = state.uri.path;

      // Public routes — always accessible
      if (_publicPaths.contains(path)) return null;

      // Not authenticated — bounce to role selection
      if (!auth.isAuthenticated) return '/roles';

      // Authenticated — check role access
      final role = auth.role;
      if (role == null) return '/roles';

      final allowed = _roleRoutes[role] ?? [];
      final hasAccess = allowed.any((prefix) => path.startsWith(prefix));
      if (!hasAccess) return auth.dashboardRoute;

      return null; // allow
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/roles',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) {
          final role = state.extra as String? ?? 'driver';
          return SignInScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = state.extra as String? ?? 'driver';
          return RegisterScreen(role: role);
        },
      ),

      // Driver routes
      GoRoute(
        path: '/driver/dashboard',
        builder: (context, state) => const DriverDashboardScreen(),
      ),
      GoRoute(
        path: '/driver/emergency-case',
        builder: (context, state) => const EmergencyCaseScreen(),
      ),
      GoRoute(
        path: '/driver/severity',
        builder: (context, state) {
          final extra = state.extra;
          String caseType = 'Heart Attack';
          String incidentType = 'CARDIAC';
          if (extra is Map<String, dynamic>) {
            caseType = extra['label'] as String? ?? 'Heart Attack';
            incidentType = extra['incidentType'] as String? ?? 'CARDIAC';
          } else if (extra is String) {
            caseType = extra;
          }
          return SeverityRatingScreen(
            caseType: caseType,
            incidentType: incidentType,
          );
        },
      ),
      GoRoute(
        path: '/driver/hospital-select',
        builder: (context, state) => const HospitalSelectionScreen(),
      ),
      GoRoute(
        path: '/driver/navigation',
        builder: (context, state) => const NavigationScreen(),
      ),
      GoRoute(
        path: '/driver/arrival',
        builder: (context, state) => const ArrivalScreen(),
      ),

      // Hospital routes
      GoRoute(
        path: '/hospital/alert',
        builder: (context, state) => const EmergencyAlertScreen(),
      ),
      GoRoute(
        path: '/hospital/sync',
        builder: (context, state) => const AmbulanceSyncScreen(),
      ),
      GoRoute(
        path: '/hospital/capacity',
        builder: (context, state) => const HospitalDashboardScreen(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Police routes
      GoRoute(
        path: '/police/dashboard',
        builder: (context, state) => const PoliceDashboardScreen(),
      ),

      // Paramedic routes (public, no auth)
      GoRoute(
        path: '/paramedic/scan',
        builder: (context, state) => const ParamedicScanScreen(),
      ),
      GoRoute(
        path: '/paramedic/vitals',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ParamedicVitalsScreen(
            sessionToken: extra['sessionToken'] as String? ?? '',
            tripId: extra['tripId'] as String? ?? '',
            hospitalName: extra['hospitalName'] as String?,
          );
        },
      ),

      // Shared screens
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
    ],
  );
}
