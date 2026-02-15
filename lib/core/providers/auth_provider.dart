import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_user.dart';
import '../models/user_role.dart';
import '../network/api_client.dart';
import '../network/api_exceptions.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';

/// Manages authentication state, token persistence, and role-based access.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _storage;
  final ApiClient _apiClient;
  WebSocketService? _webSocketService;

  AuthUser? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider({
    AuthService? authService,
    FlutterSecureStorage? storage,
    ApiClient? apiClient,
  })  : _authService = authService ?? AuthService(),
        _storage = storage ?? const FlutterSecureStorage(),
        _apiClient = apiClient ?? ApiClient.instance;

  // ── Getters ──

  AuthUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  UserRole? get role => _user?.role;
  String? get token => _user?.token;
  String get fullName => _user?.fullName ?? '';

  /// Dashboard route for the current user's role.
  String get dashboardRoute {
    switch (_user?.role) {
      case UserRole.driver:
        return '/driver/dashboard';
      case UserRole.hospital:
        return '/hospital/capacity';
      case UserRole.police:
        return '/police/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.paramedic:
        return '/roles';
      case null:
        return '/roles';
    }
  }

  // ── Actions ──

  /// Attach WebSocket service for auto-connect/disconnect on auth changes.
  void attachWebSocket(WebSocketService ws) {
    _webSocketService = ws;
    // If already authenticated (e.g. restored session), connect now
    if (_user != null) {
      ws.connect(_user!.token);
    }
  }

  /// Try to restore session from secure storage on app start.
  Future<void> tryRestoreSession() async {
    try {
      final json = await _storage.read(key: 'auth_user');
      if (json != null) {
        _user = AuthUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
        _apiClient.setToken(_user!.token);
        _webSocketService?.connect(_user!.token);
      }
    } catch (_) {
      // Corrupted storage — clear it
      await _storage.delete(key: 'auth_user');
    }
    notifyListeners();
  }

  /// Login with phone number and password.
  Future<bool> login({
    required String phoneNumber,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(
        phoneNumber: phoneNumber,
        password: password,
      );
      _apiClient.setToken(_user!.token);
      await _storage.write(key: 'auth_user', value: jsonEncode(_user!.toJson()));
      _webSocketService?.connect(_user!.token);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } on NetworkException {
      _error = 'Unable to connect to server. Please check your network and ensure the server is running.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on TimeoutException {
      _error = 'Server is not responding. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a new account.
  Future<bool> register({
    required String phoneNumber,
    required String fullName,
    required String password,
    required UserRole role,
    String? hospitalId,
    String? email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        phoneNumber: phoneNumber,
        fullName: fullName,
        password: password,
        role: role.toJson(),
        hospitalId: hospitalId,
        email: email,
      );
      _apiClient.setToken(_user!.token);
      await _storage.write(key: 'auth_user', value: jsonEncode(_user!.toJson()));
      _webSocketService?.connect(_user!.token);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } on NetworkException {
      _error = 'Unable to connect to server. Please check your network.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear session and token.
  Future<void> logout() async {
    _user = null;
    _error = null;
    _apiClient.clearToken();
    _webSocketService?.disconnect();
    await _storage.delete(key: 'auth_user');
    notifyListeners();
  }

  /// Register FCM device token with the backend.
  Future<void> registerDeviceToken(String token) async {
    if (_user == null) return;
    try {
      await _authService.registerDeviceToken(token);
    } catch (_) {
      // Non-critical — token registration can retry on next app launch
    }
  }

  /// Clear any displayed error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
