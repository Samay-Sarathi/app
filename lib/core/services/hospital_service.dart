import '../models/hospital.dart';
import '../models/trip.dart';
import '../network/api_client.dart';

/// Service for all hospital-related API calls.
class HospitalService {
  final ApiClient _client;

  HospitalService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// `PATCH /hospitals/heartbeat` — Update bed capacity, chaos score, and equipment.
  Future<HospitalHeartbeat> sendHeartbeat({
    required int bedAvailable,
    required int bedCapacityTotal,
    required int chaosScore,
    Map<String, dynamic>? crisisParameters,
    Map<String, bool>? equipment,
  }) async {
    final data = <String, dynamic>{
      'bedAvailable': bedAvailable,
      'bedCapacityTotal': bedCapacityTotal,
      'chaosScore': chaosScore,
    };
    if (crisisParameters != null) data['crisisParameters'] = crisisParameters;
    if (equipment != null) data['equipment'] = equipment;

    final response = await _client.patch('/hospitals/heartbeat', data: data);
    return HospitalHeartbeat.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /hospitals/incoming` — Get all incoming/arrived trips.
  Future<List<Trip>> getIncomingTrips() async {
    final response = await _client.get('/hospitals/incoming');
    final list = response.data as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `POST /hospitals/reject-incoming` — Reject a trip with reason.
  Future<Map<String, dynamic>> rejectIncoming({
    required String tripId,
    required String reason,
    String? details,
  }) async {
    final data = <String, dynamic>{
      'tripId': tripId,
      'reason': reason,
    };
    if (details != null) data['details'] = details;

    final response = await _client.post('/hospitals/reject-incoming', data: data);
    return response.data as Map<String, dynamic>;
  }

  /// `POST /hospitals/manual-arrival` — Manually confirm ambulance arrived.
  Future<Trip> confirmManualArrival({
    required String tripId,
    required String verificationMethod,
  }) async {
    final response = await _client.post(
      '/hospitals/manual-arrival',
      data: {
        'tripId': tripId,
        'verificationMethod': verificationMethod,
      },
    );
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /trips/{id}/complete` — Mark trip as completed (patient handoff).
  Future<Trip> completeTrip(String tripId) async {
    final response = await _client.post('/trips/$tripId/complete');
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }
}
