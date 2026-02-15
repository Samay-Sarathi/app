import '../network/api_client.dart';
import '../models/triage_data.dart';

/// Service for the anonymous helper flow (QR scan → triage entry).
class HelperService {
  final ApiClient _client;

  HelperService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// `POST /helper/link` — Link helper to trip via paramedic token.
  /// Returns `{ sessionToken, tripId, hospitalName }`.
  Future<Map<String, dynamic>> linkToTrip({
    required String paramedicToken,
    String? deviceId,
    String? userAgent,
  }) async {
    final response = await _client.post(
      '/helper/link',
      data: {
        'paramedicToken': paramedicToken,
        if (deviceId != null) 'deviceId': deviceId,
        if (userAgent != null) 'userAgent': userAgent,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// `POST /helper/vitals` — Submit vitals for the linked trip.
  Future<TriageData> submitVitals({
    required String sessionToken,
    required TriageData data,
  }) async {
    final body = data.toJson();
    body['sessionToken'] = sessionToken;
    final response = await _client.post('/helper/vitals', data: body);
    return TriageData.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /helper/identity` — Submit self-reported helper identity.
  Future<void> updateIdentity({
    required String sessionToken,
    String? helperName,
    String? contactNumber,
  }) async {
    await _client.put(
      '/helper/identity',
      data: {
        'sessionToken': sessionToken,
        if (helperName != null) 'helperName': helperName,
        if (contactNumber != null) 'contactNumber': contactNumber,
      },
    );
  }
}
