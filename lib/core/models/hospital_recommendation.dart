/// Hospital recommendation from `GET /trips/{id}/recommendations`.
/// Matches backend `HospitalRecommendationResponse`.
class HospitalRecommendation {
  final String hospitalId;
  final String hospitalName;
  final double distanceKm;
  final int etaMinutes;
  final int bedAvailable;
  final int chaosScore;
  final List<String> specialties;
  final int score;
  final Map<String, int> scoreBreakdown;
  final bool isRecommended;
  final double latitude;
  final double longitude;
  final Map<String, bool> equipment;

  const HospitalRecommendation({
    required this.hospitalId,
    required this.hospitalName,
    required this.distanceKm,
    required this.etaMinutes,
    required this.bedAvailable,
    required this.chaosScore,
    required this.specialties,
    required this.score,
    required this.scoreBreakdown,
    required this.isRecommended,
    required this.latitude,
    required this.longitude,
    this.equipment = const {},
  });

  /// Placeholder instance for skeleton loading (Skeletonizer).
  factory HospitalRecommendation.dummy() => const HospitalRecommendation(
        hospitalId: '00000000-0000-0000-0000-000000000000',
        hospitalName: 'Loading hospital name...',
        distanceKm: 4.2,
        etaMinutes: 8,
        bedAvailable: 5,
        chaosScore: 30,
        specialties: ['Emergency', 'Cardiology'],
        score: 85,
        scoreBreakdown: {},
        isRecommended: true,
        latitude: 0,
        longitude: 0,
        equipment: {'CT': true, 'MRI': true, 'Ventilator': true},
      );

  factory HospitalRecommendation.fromJson(Map<String, dynamic> json) {
    return HospitalRecommendation(
      hospitalId: json['hospitalId'] as String,
      hospitalName: json['hospitalName'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      etaMinutes: json['etaMinutes'] as int,
      bedAvailable: json['bedAvailable'] as int,
      chaosScore: json['chaosScore'] as int,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      score: json['score'] as int,
      scoreBreakdown: (json['scoreBreakdown'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      isRecommended: json['isRecommended'] as bool? ?? false,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      equipment: (json['equipment'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
          {},
    );
  }
}
