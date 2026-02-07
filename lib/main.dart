import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/trip_provider.dart';
import 'core/providers/hospital_provider.dart';
import 'core/services/websocket_service.dart';
import 'routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const LifeLineApp());
}

class LifeLineApp extends StatelessWidget {
  const LifeLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => WebSocketService()),
      ],
      child: _WebSocketBridge(
        child: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return MaterialApp.router(
              title: 'LifeLine',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: settings.themeMode,
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    );
  }
}

/// Bridges AuthProvider ↔ WebSocketService so that connect/disconnect
/// happens automatically on login / logout / session restore.
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
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
