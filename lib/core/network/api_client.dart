import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'api_exceptions.dart';

/// Singleton Dio-based HTTP client for the LifeLine backend.
///
/// Usage:
///   final client = ApiClient.instance;
///   client.setToken('jwt...');
///   final response = await client.get('/trips/123');
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;
  late final Dio _dio = _createDio();

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(seconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Auth interceptor ──
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );

    // ── Logging (debug only) ──
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint('[API] $o'),
        ),
      );
    }

    return dio;
  }

  // ── Token management ──

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  // ── HTTP verbs ──

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _request(() => _dio.get<T>(path, queryParameters: queryParameters, options: options));

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.post<T>(path, data: data, options: options));

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.put<T>(path, data: data, options: options));

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.patch<T>(path, data: data, options: options));

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.delete<T>(path, data: data, options: options));

  // ── Error handling wrapper ──

  Future<Response<T>> _request<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return ApiException.fromJson(data);
        }
        return ApiException(
          statusCode: e.response?.statusCode ?? 0,
          error: 'Unknown',
          message: e.message ?? 'An unexpected error occurred',
          timestamp: DateTime.now(),
        );

      default:
        return ApiException(
          statusCode: 0,
          error: 'Unknown',
          message: e.message ?? 'An unexpected error occurred',
          timestamp: DateTime.now(),
        );
    }
  }
}
