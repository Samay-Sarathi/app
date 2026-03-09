import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/trip_provider.dart';
import 'core/providers/hospital_provider.dart';
import 'core/services/websocket_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'shared/widgets/connectivity_banner.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await dotenv.load(fileName: '.env');

  // Initialize Firebase only when real credentials are configured.
  // Placeholder values crash iOS at the native level (NSException)
  // before Dart's try-catch can intercept.
  if (DefaultFirebaseOptions.currentPlatform.apiKey != 'PLACEHOLDER') {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await NotificationService.instance.init();
    } catch (_) {
      debugPrint(
        'Firebase init failed. Run `flutterfire configure` to enable push notifications.',
      );
    }
  }

  // Initialize persisted settings before building the widget tree
  final settings = SettingsProvider();
  await settings.init();

  runApp(LifeLineApp(settings: settings));
}

class LifeLineApp extends StatelessWidget {
  final SettingsProvider settings;
  const LifeLineApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => WebSocketService()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: _WebSocketBridge(
        child: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return MaterialApp.router(
              title: 'Samay Sarathi',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: settings.themeMode,
              routerConfig: AppRouter.router,
              builder: (context, child) =>
                  ConnectivityBanner(child: child ?? const SizedBox.shrink()),
            );
          },
        ),
      ),
    );
  }
}

/// Bridges AuthProvider <-> WebSocketService so that connect/disconnect
/// happens automatically on login / logout / session restore.
/// Also registers the FCM device token with the backend after login.
class _WebSocketBridge extends StatefulWidget {
  final Widget child;
  const _WebSocketBridge({required this.child});

  @override
  State<_WebSocketBridge> createState() => _WebSocketBridgeState();
}

class _WebSocketBridgeState extends State<_WebSocketBridge> {
  @override
  void initState() {
    super.initState();
    // Schedule after first frame so providers are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final ws = context.read<WebSocketService>();
      auth.attachWebSocket(ws);

      // Register FCM token after auth restores session
      _registerDeviceToken(auth);

      // Re-register on token refresh
      NotificationService.instance.onTokenRefresh.listen((_) {
        _registerDeviceToken(auth);
      });
    });
  }

  Future<void> _registerDeviceToken(AuthProvider auth) async {
    if (!auth.isAuthenticated) return;
    final token = await NotificationService.instance.getDeviceToken();
    if (token != null) {
      auth.registerDeviceToken(token);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
