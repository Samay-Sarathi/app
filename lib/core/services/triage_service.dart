import '../models/triage_data.dart';
import '../network/api_client.dart';

/// Service for triage vitals API calls.
class TriageService {
  final ApiClient _client;

  TriageService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// `POST /trips/{tripId}/triage` — Record vitals (also broadcasts via WebSocket).
  Future<TriageData> recordVitals(String tripId, TriageData data) async {
    final response = await _client.post(
      '/trips/$tripId/triage',
      data: data.toJson(),
    );
    return TriageData.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /trips/{tripId}/triage` — Get all vitals history.
  Future<List<TriageData>> getVitalsHistory(String tripId) async {
    final response = await _client.get('/trips/$tripId/triage');
    final list = response.data as List<dynamic>;
    return list.map((e) => TriageData.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `GET /trips/{tripId}/triage/latest` — Get latest vitals snapshot.
  Future<TriageData?> getLatestVitals(String tripId) async {
    final response = await _client.get('/trips/$tripId/triage/latest');
    if (response.statusCode == 204) return null;
    return TriageData.fromJson(response.data as Map<String, dynamic>);
  }
}
