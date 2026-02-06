import '../models/auth_user.dart';
import '../network/api_client.dart';

/// Service for authentication API calls.
class AuthService {
  final ApiClient _client;

  AuthService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// `POST /auth/login` — Returns JWT + user info.
  Future<AuthUser> login({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /auth/register` — Creates account and returns JWT.
  Future<AuthUser> register({
    required String phoneNumber,
    required String fullName,
    required String password,
    required String role,
    String? hospitalId,
  }) async {
    final data = <String, dynamic>{
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'password': password,
      'role': role,
    };
    if (hospitalId != null) data['hospitalId'] = hospitalId;

    final response = await _client.post('/auth/register', data: data);
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }
}
