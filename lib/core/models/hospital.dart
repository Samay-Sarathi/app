/// Handshake response from `POST /trips/{id}/handshake`.
/// Matches backend `HandshakeResponse`.
class HandshakeResult {
  final String tripId;
  final String hospitalId;
  final String hospitalName;
  final double hospitalLatitude;
  final double hospitalLongitude;
  final String paramedicToken;
  final DateTime tokenExpiresAt;
  final int? etaSeconds;

  const HandshakeResult({
    required this.tripId,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalLatitude,
    required this.hospitalLongitude,
    required this.paramedicToken,
    required this.tokenExpiresAt,
    this.etaSeconds,
  });

  factory HandshakeResult.fromJson(Map<String, dynamic> json) {
    return HandshakeResult(
      tripId: json['tripId'] as String,
      hospitalId: json['hospitalId'] as String,
      hospitalName: json['hospitalName'] as String,
      hospitalLatitude: (json['hospitalLatitude'] as num?)?.toDouble() ?? 0,
      hospitalLongitude: (json['hospitalLongitude'] as num?)?.toDouble() ?? 0,
      paramedicToken: json['paramedicToken'] as String,
      tokenExpiresAt: DateTime.parse(json['tokenExpiresAt'] as String),
      etaSeconds: json['etaSeconds'] as int?,
    );
  }
}

/// Hospital heartbeat response from `PATCH /hospitals/heartbeat`.
class HospitalHeartbeat {
  final String hospitalId;
  final String name;
  final double latitude;
  final double longitude;
  final int bedAvailable;
  final int bedCapacityTotal;
  final int bedReserved;
  final int chaosScore;
  final String status;
  final DateTime lastHeartbeat;

  const HospitalHeartbeat({
    required this.hospitalId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.bedAvailable,
    required this.bedCapacityTotal,
    required this.bedReserved,
    required this.chaosScore,
    required this.status,
    required this.lastHeartbeat,
  });

  factory HospitalHeartbeat.fromJson(Map<String, dynamic> json) {
    return HospitalHeartbeat(
      hospitalId: json['hospitalId'] as String,
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      bedAvailable: json['bedAvailable'] as int? ?? 0,
      bedCapacityTotal: json['bedCapacityTotal'] as int? ?? 0,
      bedReserved: json['bedReserved'] as int? ?? 0,
      chaosScore: json['chaosScore'] as int? ?? 5,
      status: json['status'] as String? ?? 'ACTIVE',
      lastHeartbeat: DateTime.parse(json['lastHeartbeat'] as String),
    );
  }

  int get occupancyPercent {
    if (bedCapacityTotal == 0) return 0;
    return (((bedCapacityTotal - bedAvailable) / bedCapacityTotal) * 100).round();
  }
}
