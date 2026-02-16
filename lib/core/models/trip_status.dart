/// Matches backend `TripStatus` enum.
enum TripStatus {
  vitals,
  destinationLocked,
  enRoute,
  arrived,
  completed,
  cancelled;

  static TripStatus fromJson(String value) {
    switch (value.toUpperCase()) {
      case 'VITALS':
        return TripStatus.vitals;
      case 'DESTINATION_LOCKED':
        return TripStatus.destinationLocked;
      case 'EN_ROUTE':
        return TripStatus.enRoute;
      case 'ARRIVED':
        return TripStatus.arrived;
      case 'COMPLETED':
        return TripStatus.completed;
      case 'CANCELLED':
        return TripStatus.cancelled;
      default:
        return TripStatus.vitals;
    }
  }

  String toJson() {
    switch (this) {
      case TripStatus.vitals:
        return 'VITALS';
      case TripStatus.destinationLocked:
        return 'DESTINATION_LOCKED';
      case TripStatus.enRoute:
        return 'EN_ROUTE';
      case TripStatus.arrived:
        return 'ARRIVED';
      case TripStatus.completed:
        return 'COMPLETED';
      case TripStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case TripStatus.vitals:
        return 'Vitals';
      case TripStatus.destinationLocked:
        return 'Hospital Locked';
      case TripStatus.enRoute:
        return 'En Route';
      case TripStatus.arrived:
        return 'Arrived';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal => this == completed || this == cancelled;
  bool get isActive => !isTerminal;
}
