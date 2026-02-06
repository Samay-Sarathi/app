/// Base exception for all LifeLine API errors.
class ApiException implements Exception {
  final int statusCode;
  final String error;
  final String message;
  final DateTime timestamp;
  final Map<String, String>? validationDetails;

  const ApiException({
    required this.statusCode,
    required this.error,
    required this.message,
    required this.timestamp,
    this.validationDetails,
  });

  factory ApiException.fromJson(Map<String, dynamic> json) {
    return ApiException(
      statusCode: json['status'] as int? ?? 0,
      error: json['error'] as String? ?? 'Unknown Error',
      message: json['message'] as String? ?? 'An unexpected error occurred',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      validationDetails: json['details'] != null
          ? Map<String, String>.from(json['details'] as Map)
          : null,
    );
  }

  bool get isValidationError => statusCode == 400 && validationDetails != null;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when there is no network connectivity.
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when the request times out.
class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'Request timed out']);

  @override
  String toString() => 'TimeoutException: $message';
}
