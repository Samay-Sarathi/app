import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/driver/driver_dashboard_screen.dart';
import '../features/trip/screens/emergency_case_screen.dart';
import '../features/trip/screens/severity_rating_screen.dart';
import '../features/trip/screens/hospital_selection_screen.dart';
import '../features/trip/screens/navigation_screen.dart';
import '../features/trip/screens/triage_sync_screen.dart';
import '../features/hospital/screens/emergency_alert_screen.dart';
import '../features/paramedic/screens/qr_scan_screen.dart';
import '../features/hospital/screens/ambulance_sync_screen.dart';
import '../features/hospital/hospital_dashboard_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/police/police_dashboard_screen.dart';

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

      // Paramedic routes
      GoRoute(
        path: '/paramedic/qr-scan',
        builder: (context, state) => const QrScanScreen(),
      ),
    ],
  );
}
