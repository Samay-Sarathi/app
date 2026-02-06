import 'incident_type.dart';
import 'trip_status.dart';

/// Full trip response from backend — matches `TripResponse` Java record.
class Trip {
  final String id;
  final String driverId;
  final String? paramedicId;
  final String? hospitalId;
  final TripStatus status;
  final IncidentType incidentType;
  final int severity;
  final double pickupLatitude;
  final double pickupLongitude;
  final DateTime createdAt;
  final DateTime? lockedAt;
  final DateTime? enRouteAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final int? etaSeconds;
  final String? paramedicToken;
  final DateTime? tokenExpiresAt;
  final int rejectionCount;

  // Extra fields returned by some endpoints (incoming trips)
  final String? driverName;
  final String? paramedicName;
  final String? hospitalName;

  const Trip({
    required this.id,
    required this.driverId,
    this.paramedicId,
    this.hospitalId,
    required this.status,
    required this.incidentType,
    required this.severity,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.createdAt,
    this.lockedAt,
    this.enRouteAt,
    this.arrivedAt,
    this.completedAt,
    this.etaSeconds,
    this.paramedicToken,
    this.tokenExpiresAt,
    this.rejectionCount = 0,
    this.driverName,
    this.paramedicName,
    this.hospitalName,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      driverId: json['driverId'] as String? ?? '',
      paramedicId: json['paramedicId'] as String?,
      hospitalId: json['hospitalId'] as String?,
      status: TripStatus.fromJson(json['status'] as String),
      incidentType: IncidentType.fromJson(json['incidentType'] as String),
      severity: json['severity'] as int? ?? 1,
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble() ?? 0,
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble() ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      lockedAt: _parseDateTimeOrNull(json['lockedAt']),
      enRouteAt: _parseDateTimeOrNull(json['enRouteAt']),
      arrivedAt: _parseDateTimeOrNull(json['arrivedAt']),
      completedAt: _parseDateTimeOrNull(json['completedAt']),
      etaSeconds: json['etaSeconds'] as int?,
      paramedicToken: json['paramedicToken'] as String?,
      tokenExpiresAt: _parseDateTimeOrNull(json['tokenExpiresAt']),
      rejectionCount: json['rejectionCount'] as int? ?? 0,
      driverName: json['driverName'] as String?,
      paramedicName: json['paramedicName'] as String?,
      hospitalName: json['hospitalName'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.parse(value as String);
  }

  static DateTime? _parseDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  Trip copyWith({TripStatus? status, String? hospitalId, String? hospitalName}) {
    return Trip(
      id: id,
      driverId: driverId,
      paramedicId: paramedicId,
      hospitalId: hospitalId ?? this.hospitalId,
      status: status ?? this.status,
      incidentType: incidentType,
      severity: severity,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      createdAt: createdAt,
      lockedAt: lockedAt,
      enRouteAt: enRouteAt,
      arrivedAt: arrivedAt,
      completedAt: completedAt,
      etaSeconds: etaSeconds,
      paramedicToken: paramedicToken,
      tokenExpiresAt: tokenExpiresAt,
      rejectionCount: rejectionCount,
      driverName: driverName,
      paramedicName: paramedicName,
      hospitalName: hospitalName ?? this.hospitalName,
    );
  }
}
