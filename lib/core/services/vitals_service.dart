import '../models/vitals_data.dart';
import '../network/api_client.dart';

/// Service for vitals API calls.
class VitalsService {
  final ApiClient _client;

  VitalsService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// `POST /trips/{tripId}/vitals` — Record vitals (also broadcasts via WebSocket).
  Future<VitalsData> recordVitals(String tripId, VitalsData data) async {
    final response = await _client.post(
      '/trips/$tripId/vitals',
      data: data.toJson(),
    );
    return VitalsData.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /trips/{tripId}/vitals` — Get all vitals history.
  Future<List<VitalsData>> getVitalsHistory(String tripId) async {
    final response = await _client.get('/trips/$tripId/vitals');
    final list = response.data as List<dynamic>;
    return list.map((e) => VitalsData.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `GET /trips/{tripId}/vitals/latest` — Get latest vitals snapshot.
  Future<VitalsData?> getLatestVitals(String tripId) async {
    final response = await _client.get('/trips/$tripId/vitals/latest');
    if (response.statusCode == 204) return null;
    return VitalsData.fromJson(response.data as Map<String, dynamic>);
  }
}
