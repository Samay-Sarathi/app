import 'user_role.dart';

/// Auth response from `POST /auth/login` and `POST /auth/register`.
class AuthUser {
  final String token;
  final String userId;
  final UserRole role;
  final String fullName;

  const AuthUser({
    required this.token,
    required this.userId,
    required this.role,
    required this.fullName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      token: json['token'] as String,
      userId: json['userId'] as String,
      role: UserRole.fromJson(json['role'] as String),
      fullName: json['fullName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'role': role.toJson(),
        'fullName': fullName,
      };
}
