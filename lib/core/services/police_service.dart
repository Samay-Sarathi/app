import '../models/trip.dart';
import '../network/api_client.dart';

/// Service for police-related API calls.
class PoliceService {
  final ApiClient _client;

  PoliceService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// `GET /police/active-trips` — All non-terminal trips.
  Future<List<Trip>> getActiveTrips() async {
    final response = await _client.get('/police/active-trips');
    final list = response.data as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `GET /police/active-corridors` — EN_ROUTE trips only.
  Future<List<Trip>> getActiveCorridors() async {
    final response = await _client.get('/police/active-corridors');
    final list = response.data as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `GET /police/alerts` — Recent trip events (last 24h).
  Future<List<Map<String, dynamic>>> getAlerts() async {
    final response = await _client.get('/police/alerts');
    final list = response.data as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// `GET /police/my-assignments` — Active corridor assignments for this officer.
  Future<List<Map<String, dynamic>>> getMyAssignments() async {
    final response = await _client.get('/police/my-assignments');
    final list = response.data as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// `POST /police/assignments/{id}/acknowledge` — Acknowledge a corridor assignment.
  Future<Map<String, dynamic>> acknowledgeAssignment(
    String assignmentId, {
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.post(
      '/police/assignments/$assignmentId/acknowledge',
      data: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// `POST /police/assignments/{id}/clear` — Mark route as cleared.
  Future<Map<String, dynamic>> clearRoute(
    String assignmentId, {
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.post(
      '/police/assignments/$assignmentId/clear',
      data: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// `POST /police/location` — Send officer location to driver.
  Future<void> updateLocation({
    required String tripId,
    required double latitude,
    required double longitude,
  }) async {
    await _client.post('/police/location', data: {
      'tripId': tripId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}
