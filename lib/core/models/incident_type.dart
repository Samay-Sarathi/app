/// Matches backend `IncidentType` enum.
enum IncidentType {
  cardiac,
  trauma,
  stroke,
  respiratory,
  obstetric,
  pediatric,
  burn,
  other;

  static IncidentType fromJson(String value) {
    return IncidentType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => IncidentType.other,
    );
  }

  String toJson() => name.toUpperCase();

  String get label {
    switch (this) {
      case IncidentType.cardiac:
        return 'Heart Attack';
      case IncidentType.trauma:
        return 'Road Accident';
      case IncidentType.stroke:
        return 'Stroke';
      case IncidentType.respiratory:
        return 'Breathing Issue';
      case IncidentType.obstetric:
        return 'Pregnancy Emergency';
      case IncidentType.pediatric:
        return 'Pediatric Emergency';
      case IncidentType.burn:
        return 'Burn Injury';
      case IncidentType.other:
        return 'Other';
    }
  }
}
