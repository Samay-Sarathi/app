import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/role_selection_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/driver/driver_dashboard_screen.dart';
import '../features/driver/emergency_case_screen.dart';
import '../features/driver/severity_rating_screen.dart';
import '../features/driver/hospital_selection_screen.dart';
import '../features/driver/navigation_screen.dart';
import '../features/driver/green_corridor_screen.dart';
import '../features/driver/triage_sync_screen.dart';
import '../features/hospital/emergency_alert_screen.dart';
import '../features/hospital/ambulance_sync_screen.dart';
import '../features/hospital/hospital_capacity_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
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
        path: '/driver/green-corridor',
        builder: (context, state) => const GreenCorridorScreen(),
      ),
      GoRoute(
        path: '/driver/triage',
        builder: (context, state) => const TriageSyncScreen(),
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
        builder: (context, state) => const HospitalCapacityScreen(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}
