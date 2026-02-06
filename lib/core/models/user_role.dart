/// Matches backend `UserRole` enum.
enum UserRole {
  driver,
  paramedic,
  hospital,
  police,
  admin;

  /// Parse from backend JSON string (e.g. "DRIVER" → UserRole.driver).
  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => UserRole.driver,
    );
  }

  /// Serialize to backend format (e.g. UserRole.driver → "DRIVER").
  String toJson() => name.toUpperCase();

  /// Human-readable label.
  String get label {
    switch (this) {
      case UserRole.driver:
        return 'Ambulance Driver';
      case UserRole.paramedic:
        return 'Paramedic';
      case UserRole.hospital:
        return 'Hospital';
      case UserRole.police:
        return 'Police';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
