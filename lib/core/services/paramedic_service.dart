import '../network/api_client.dart';
import '../models/vitals_data.dart';

/// Service for the anonymous paramedic flow (QR scan → vitals entry).
class ParamedicService {
  final ApiClient _client;

  ParamedicService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// `POST /paramedic/link` — Link paramedic to trip via paramedic token.
  /// Returns `{ sessionToken, tripId, hospitalName }`.
  Future<Map<String, dynamic>> linkToTrip({
    required String paramedicToken,
    String? deviceId,
    String? userAgent,
  }) async {
    final response = await _client.post(
      '/paramedic/link',
      data: {
        'paramedicToken': paramedicToken,
        if (deviceId != null) 'deviceId': deviceId,
        if (userAgent != null) 'userAgent': userAgent,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// `POST /paramedic/vitals` — Submit vitals for the linked trip.
  Future<VitalsData> submitVitals({
    required String sessionToken,
    required VitalsData data,
  }) async {
    final body = data.toJson();
    body['sessionToken'] = sessionToken;
    final response = await _client.post('/paramedic/vitals', data: body);
    return VitalsData.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /paramedic/identity` — Submit self-reported paramedic identity.
  Future<void> updateIdentity({
    required String sessionToken,
    String? paramedicName,
    String? contactNumber,
  }) async {
    await _client.put(
      '/paramedic/identity',
      data: {
        'sessionToken': sessionToken,
        if (paramedicName != null) 'paramedicName': paramedicName,
        if (contactNumber != null) 'contactNumber': contactNumber,
      },
    );
  }
}
