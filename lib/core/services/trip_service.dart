import '../models/trip.dart';
import '../models/hospital_recommendation.dart';
import '../models/hospital.dart';
import '../network/api_client.dart';

/// Service for all trip-related API calls.
class TripService {
  final ApiClient _client;

  TripService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// `POST /trips` — Create a new emergency trip.
  Future<Trip> createTrip({
    required String incidentType,
    required int severity,
    required double pickupLatitude,
    required double pickupLongitude,
    required String idempotencyKey,
  }) async {
    final response = await _client.post(
      '/trips',
      data: {
        'incidentType': incidentType,
        'severity': severity,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'idempotencyKey': idempotencyKey,
      },
    );
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /trips/{id}` — Get trip by ID.
  Future<Trip> getTrip(String tripId) async {
    final response = await _client.get('/trips/$tripId');
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /trips/{id}/recommendations` — Get scored hospital list.
  Future<List<HospitalRecommendation>> getRecommendations(String tripId) async {
    final response = await _client.get('/trips/$tripId/recommendations');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => HospitalRecommendation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /trips/{id}/handshake` — Lock hospital and reserve bed.
  Future<HandshakeResult> handshake({
    required String tripId,
    required String hospitalId,
    required String idempotencyKey,
    int? etaSeconds,
  }) async {
    final data = <String, dynamic>{
      'hospitalId': hospitalId,
      'idempotencyKey': idempotencyKey,
    };
    if (etaSeconds != null) data['etaSeconds'] = etaSeconds;

    final response = await _client.post('/trips/$tripId/handshake', data: data);
    return HandshakeResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /trips/{id}/en-route` — Mark trip as en-route.
  Future<Trip> markEnRoute(String tripId) async {
    final response = await _client.post('/trips/$tripId/en-route');
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /trips/{id}/cancel` — Cancel an active trip.
  Future<Trip> cancelTrip(String tripId, {String? reason}) async {
    final response = await _client.post(
      '/trips/$tripId/cancel',
      data: reason != null ? {'reason': reason} : null,
    );
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /trips/{id}/qr` — Get paramedic QR token.
  Future<Map<String, dynamic>> getQrToken(String tripId) async {
    final response = await _client.get('/trips/$tripId/qr');
    return response.data as Map<String, dynamic>;
  }

  /// `POST /trips/link-paramedic` — Link paramedic via scanned QR token.
  Future<Map<String, dynamic>> linkParamedic(String paramedicToken) async {
    final response = await _client.post(
      '/trips/link-paramedic',
      data: {'paramedicToken': paramedicToken},
    );
    return response.data as Map<String, dynamic>;
  }
}
