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
}
