import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/hospital.dart';
import '../models/trip.dart';
import '../network/api_exceptions.dart';
import '../services/hospital_service.dart';

/// Manages hospital dashboard state — heartbeat, incoming trips, bed management.
class HospitalProvider extends ChangeNotifier {
  final HospitalService _hospitalService;

  HospitalHeartbeat? _heartbeat;
  List<Trip> _incomingTrips = [];
  bool _isLoading = false;
  String? _error;
  Timer? _heartbeatTimer;

  HospitalProvider([HospitalService? hospitalService])
      : _hospitalService = hospitalService ?? HospitalService();

  // ── Getters ──

  HospitalHeartbeat? get heartbeat => _heartbeat;
  List<Trip> get incomingTrips => _incomingTrips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get bedAvailable => _heartbeat?.bedAvailable ?? 0;
  int get bedCapacityTotal => _heartbeat?.bedCapacityTotal ?? 0;
  int get occupancyPercent => _heartbeat?.occupancyPercent ?? 0;

  // ── Heartbeat ──

  /// Send a heartbeat and optionally start periodic timer.
  Future<bool> sendHeartbeat({
    required int bedAvailable,
    required int bedCapacityTotal,
    required int chaosScore,
    Map<String, dynamic>? crisisParameters,
    Map<String, bool>? equipment,
  }) async {
    _error = null;
    try {
      _heartbeat = await _hospitalService.sendHeartbeat(
        bedAvailable: bedAvailable,
        bedCapacityTotal: bedCapacityTotal,
        chaosScore: chaosScore,
        crisisParameters: crisisParameters,
        equipment: equipment,
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Heartbeat failed.';
      notifyListeners();
      return false;
    }
  }

  /// Start sending heartbeats every [AppConfig.heartbeatIntervalSeconds].
  void startHeartbeatTimer({
    required int bedAvailable,
    required int bedCapacityTotal,
    required int chaosScore,
  }) {
    _heartbeatTimer?.cancel();
    // Send immediately
    sendHeartbeat(
      bedAvailable: bedAvailable,
      bedCapacityTotal: bedCapacityTotal,
      chaosScore: chaosScore,
    );
    // Then periodically
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: AppConfig.heartbeatIntervalSeconds),
      (_) => sendHeartbeat(
        bedAvailable: bedAvailable,
        bedCapacityTotal: bedCapacityTotal,
        chaosScore: chaosScore,
      ),
    );
  }

  void stopHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ── Incoming Trips ──

  Future<void> fetchIncomingTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _incomingTrips = await _hospitalService.getIncomingTrips();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load incoming trips.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reject an incoming trip.
  Future<bool> rejectTrip(String tripId, String reason) async {
    try {
      await _hospitalService.rejectIncoming(tripId: tripId, reason: reason);
      await fetchIncomingTrips(); // Refresh list
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Confirm manual arrival.
  Future<bool> confirmArrival(String tripId, {String method = 'VISUAL'}) async {
    try {
      await _hospitalService.confirmManualArrival(
        tripId: tripId,
        verificationMethod: method,
      );
      await fetchIncomingTrips();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Complete a trip (patient handoff).
  Future<bool> completeTrip(String tripId) async {
    try {
      await _hospitalService.completeTrip(tripId);
      await fetchIncomingTrips();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
