import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/app_config.dart';

/// WebSocket service using STOMP over raw WebSocket.
/// Connects to the Spring Boot backend for real-time data:
///   - Location streaming (driver → server → hospital/police)
///   - Vitals streaming (driver/paramedic → server → hospital)
///   - Trip status changes (server → all subscribers)
///   - Hospital incoming alerts (server → hospital)
class WebSocketService extends ChangeNotifier {
  StompClient? _client;
  bool _isConnected = false;
  final Map<String, StompUnsubscribe> _subscriptions = {};
  final Map<String, List<void Function(Map<String, dynamic>)>> _listeners = {};

  bool get isConnected => _isConnected;

  /// Derive WS URL from the REST base URL.
  static String get _wsUrl {
    // e.g. http://10.0.2.2:8080/api/v1 → ws://10.0.2.2:8080/ws/websocket
    final base = AppConfig.baseUrl
        .replaceFirst('/api/v1', '')
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/ws/websocket';
  }

  /// Connect with JWT token for authentication.
  void connect(String token) {
    if (_isConnected && _client != null) return;

    _client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onWebSocketError: (error) {
          debugPrint('WebSocket error: $error');
        },
        onStompError: (frame) {
          debugPrint('STOMP error: ${frame.body}');
        },
        // Reconnect automatically — lives are at risk
        reconnectDelay: const Duration(seconds: 3),
        heartbeatIncoming: const Duration(seconds: 25),
        heartbeatOutgoing: const Duration(seconds: 25),
      ),
    );

    _client!.activate();
    debugPrint('WebSocket connecting to $_wsUrl');
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    notifyListeners();
    debugPrint('WebSocket CONNECTED');

    // Re-subscribe after reconnect
    final entries = Map<String, List<void Function(Map<String, dynamic>)>>.from(_listeners);
    for (final entry in entries.entries) {
      _doSubscribe(entry.key);
    }
  }

  void _onDisconnect(StompFrame frame) {
    _isConnected = false;
    _subscriptions.clear();
    notifyListeners();
    debugPrint('WebSocket DISCONNECTED');
  }

  /// Subscribe to a STOMP topic and register a callback.
  void subscribe(String destination, void Function(Map<String, dynamic>) callback) {
    _listeners.putIfAbsent(destination, () => []);
    _listeners[destination]!.add(callback);

    if (_isConnected && !_subscriptions.containsKey(destination)) {
      _doSubscribe(destination);
    }
  }

  void _doSubscribe(String destination) {
    if (_client == null || !_isConnected) return;

    final unsubscribe = _client!.subscribe(
      destination: destination,
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            final callbacks = _listeners[destination];
            if (callbacks != null) {
              for (final cb in callbacks) {
                cb(data);
              }
            }
          } catch (e) {
            debugPrint('Failed to parse STOMP message on $destination: $e');
          }
        }
      },
    );

    _subscriptions[destination] = unsubscribe;
  }

  /// Unsubscribe from a topic.
  void unsubscribe(String destination) {
    _subscriptions[destination]?.call(unsubscribeHeaders: {});
    _subscriptions.remove(destination);
    _listeners.remove(destination);
  }

  /// Send a STOMP message to a destination (e.g., /app/trip/{id}/location).
  void send(String destination, Map<String, dynamic> body) {
    if (_client == null || !_isConnected) {
      debugPrint('Cannot send — WebSocket not connected');
      return;
    }

    _client!.send(
      destination: destination,
      body: jsonEncode(body),
    );
  }

  /// Disconnect and clean up.
  void disconnect() {
    for (final unsub in _subscriptions.values) {
      try {
        unsub.call(unsubscribeHeaders: {});
      } catch (_) {}
    }
    _subscriptions.clear();
    _listeners.clear();
    _client?.deactivate();
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
