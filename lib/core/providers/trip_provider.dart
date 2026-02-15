import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/hospital_recommendation.dart';
import '../models/hospital.dart';
import '../network/api_exceptions.dart';
import '../services/trip_service.dart';

/// Manages the active trip state through its full lifecycle.
class TripProvider extends ChangeNotifier {
  final TripService _tripService;

  Trip? _activeTrip;
  List<HospitalRecommendation> _recommendations = [];
  HandshakeResult? _handshakeResult;
  double? _selectedHospitalLat;
  double? _selectedHospitalLng;
  bool _isLoading = false;
  String? _error;

  // Driver stats
  int _tripsToday = 0;
  int _avgResponseTimeMinutes = 0;
  double _distanceCoveredKm = 0.0;

  TripProvider([TripService? tripService])
      : _tripService = tripService ?? TripService();

  // ── Getters ──

  Trip? get activeTrip => _activeTrip;
  List<HospitalRecommendation> get recommendations => _recommendations;
  HandshakeResult? get handshakeResult => _handshakeResult;
  double? get selectedHospitalLat => _selectedHospitalLat;
  double? get selectedHospitalLng => _selectedHospitalLng;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveTrip => _activeTrip != null && _activeTrip!.status.isActive;
  int get tripsToday => _tripsToday;
  int get avgResponseTimeMinutes => _avgResponseTimeMinutes;
  double get distanceCoveredKm => _distanceCoveredKm;

  // ── Actions ──

  /// Fetch driver's current active trip (for resuming after 409 error).
  Future<Trip?> fetchActiveTrip() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trip = await _tripService.getActiveTrip();
      if (trip != null) {
        _activeTrip = trip;
      }
      _isLoading = false;
      notifyListeners();
      return trip;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to fetch active trip.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Create a new emergency trip.
  Future<bool> createTrip({
    required String incidentType,
    required int severity,
    required double pickupLatitude,
    required double pickupLongitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeTrip = await _tripService.createTrip(
        incidentType: incidentType,
        severity: severity,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        idempotencyKey: const Uuid().v4(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      // Re-throw 409 errors so caller can show cancel/resume dialog
      if (e.isConflict) rethrow;
      return false;
    } catch (e) {
      _error = 'Failed to create trip.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch hospital recommendations for the active trip.
  Future<bool> fetchRecommendations() async {
    if (_activeTrip == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recommendations = await _tripService.getRecommendations(_activeTrip!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to load recommendations.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Lock a hospital via handshake.
  Future<bool> lockHospital(String hospitalId, {int? etaSeconds}) async {
    if (_activeTrip == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Save hospital coordinates from recommendations before locking
    final rec = _recommendations.where((r) => r.hospitalId == hospitalId).toList();
    if (rec.isNotEmpty) {
      _selectedHospitalLat = rec.first.latitude;
      _selectedHospitalLng = rec.first.longitude;
    }

    try {
      _handshakeResult = await _tripService.handshake(
        tripId: _activeTrip!.id,
        hospitalId: hospitalId,
        idempotencyKey: const Uuid().v4(),
        etaSeconds: etaSeconds,
      );
      // Refresh trip state
      _activeTrip = await _tripService.getTrip(_activeTrip!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to lock hospital.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get QR token for paramedic handoff.
  Future<Map<String, dynamic>?> getQrToken(String tripId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final qrData = await _tripService.getQrToken(tripId);
      _isLoading = false;
      notifyListeners();
      return qrData;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to get QR token.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Mark the trip as en-route.
  Future<bool> startEnRoute() async {
    if (_activeTrip == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeTrip = await _tripService.markEnRoute(_activeTrip!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to start en-route.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark the active trip as arrived at hospital.
  Future<bool> arriveAtHospital({String? notes, double? latitude, double? longitude}) async {
    if (_activeTrip == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeTrip = await _tripService.markArrived(
        _activeTrip!.id,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to confirm arrival.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel the active trip.
  Future<bool> cancelTrip({String? reason}) async {
    if (_activeTrip == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.cancelTrip(_activeTrip!.id, reason: reason);
      // Clear trip state — trip is terminal, no longer active
      _activeTrip = null;
      _recommendations = [];
      _handshakeResult = null;
      _selectedHospitalLat = null;
      _selectedHospitalLng = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to cancel trip.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh the active trip from backend.
  Future<void> refreshTrip() async {
    if (_activeTrip == null) return;
    try {
      _activeTrip = await _tripService.getTrip(_activeTrip!.id);
      notifyListeners();
    } catch (_) {}
  }

  /// Clear trip state (e.g., after completion).
  void clearTrip() {
    _activeTrip = null;
    _recommendations = [];
    _handshakeResult = null;
    _selectedHospitalLat = null;
    _selectedHospitalLng = null;
    _error = null;
    notifyListeners();
  }

  /// Reset hospital-specific state (used when hospital rejects).
  void clearHospitalLock() {
    _handshakeResult = null;
    _selectedHospitalLat = null;
    _selectedHospitalLng = null;
    notifyListeners();
  }

  /// Link paramedic via scanned QR token.
  Future<Map<String, dynamic>?> linkParamedic(String paramedicToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _tripService.linkParamedic(paramedicToken);
      // Refresh active trip if it was updated
      if (_activeTrip != null) {
        _activeTrip = await _tripService.getTrip(_activeTrip!.id);
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to link paramedic.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Fetch driver dashboard stats from the backend.
  Future<void> fetchDriverStats() async {
    try {
      final data = await _tripService.getDriverStats();
      _tripsToday = data['tripsToday'] as int? ?? 0;
      _avgResponseTimeMinutes = data['avgResponseTimeMinutes'] as int? ?? 0;
      _distanceCoveredKm = (data['distanceCoveredKm'] as num?)?.toDouble() ?? 0.0;
      notifyListeners();
    } catch (_) {
      // Stats are non-critical — silently ignore failures
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
