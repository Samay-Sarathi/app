/// Triage vitals data — matches backend `TriageResponse` / `TriageRequest`.
class TriageData {
  final String? id;
  final String? tripId;
  final String? recordedBy;
  final int? heartRate;
  final String? bloodPressure;
  final int? spo2;
  final int? respiratoryRate;
  final double? temperature;
  final int? gcsScore;
  final int? painLevel;
  final String? notes;
  final DateTime? recordedAt;

  const TriageData({
    this.id,
    this.tripId,
    this.recordedBy,
    this.heartRate,
    this.bloodPressure,
    this.spo2,
    this.respiratoryRate,
    this.temperature,
    this.gcsScore,
    this.painLevel,
    this.notes,
    this.recordedAt,
  });

  factory TriageData.fromJson(Map<String, dynamic> json) {
    return TriageData(
      id: json['id'] as String?,
      tripId: json['tripId'] as String?,
      recordedBy: json['recordedBy'] as String?,
      heartRate: json['heartRate'] as int?,
      bloodPressure: json['bloodPressure'] as String?,
      spo2: json['spo2'] as int?,
      respiratoryRate: json['respiratoryRate'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      gcsScore: json['gcsScore'] as int?,
      painLevel: json['painLevel'] as int?,
      notes: json['notes'] as String?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (heartRate != null) 'heartRate': heartRate,
      if (bloodPressure != null) 'bloodPressure': bloodPressure,
      if (spo2 != null) 'spo2': spo2,
      if (respiratoryRate != null) 'respiratoryRate': respiratoryRate,
      if (temperature != null) 'temperature': temperature,
      if (gcsScore != null) 'gcsScore': gcsScore,
      if (painLevel != null) 'painLevel': painLevel,
      if (notes != null) 'notes': notes,
    };
  }
}
