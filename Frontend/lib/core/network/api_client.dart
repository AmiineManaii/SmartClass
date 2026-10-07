import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Dio-based HTTP client for the SmartClass API.
///
/// - Base URL from [ApiConfig] (`--dart-define=API_BASE_URL`)
/// - `X-Request-Id` on every request (backend request tracking)
/// - Bearer JWT injected on authenticated calls
/// - Single-flight access-token refresh + one retry on 401
/// - Throws [ApiException] (never raw [DioException])
class ApiClient {
  ApiClient({
    required this.tokens,
    Dio? dio,
    this.onUnauthorized,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                sendTimeout: ApiConfig.connectTimeout,
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final Dio _dio;
  final TokenStorage tokens;

  /// Called when the session can no longer be refreshed (logout).
  /// Assigned by the app layer to avoid a core → app dependency.
  VoidCallback? onUnauthorized;

  Future<String?>? _refreshFuture;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-Request-Id'] = const Uuid().v4();
    if (options.extra['authenticated'] != false) {
      final accessToken = await tokens.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isPublicCall = err.requestOptions.extra['authenticated'] == false;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (err.response?.statusCode == 401 && !isPublicCall && !alreadyRetried) {
      try {
        final newToken = await (_refreshFuture ??=
            _performRefresh().whenComplete(() => _refreshFuture = null));
        if (newToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          err.requestOptions.extra['retried'] = true;
          final retry = await _dio.fetch<dynamic>(err.requestOptions);
          return handler.resolve(retry);
        }
      } catch (_) {
        // Refresh failed: fall through to unauthorized handling below.
      }
      await tokens.clear();
      onUnauthorized?.call();
    }
    handler.next(err);
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException(message: 'No refresh token available');
    }
    final res = await _dio.post<dynamic>(
      '${ApiConfig.apiPrefix}/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: const {'authenticated': false}),
    );
    final data = apiEnvelope(res);
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      throw const ApiException(message: 'Invalid refresh response');
    }
    await tokens.saveSession(accessToken: access, refreshToken: refresh);
    return access;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) {
    return _guard(() => _dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: Options(extra: {'authenticated': authenticated}),
        ));
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    bool authenticated = true,
  }) {
    return _guard(() => _dio.post<T>(
          path,
          data: data,
          options: Options(extra: {'authenticated': authenticated}),
        ));
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    bool authenticated = true,
  }) {
    return _guard(() => _dio.patch<T>(
          path,
          data: data,
          options: Options(extra: {'authenticated': authenticated}),
        ));
  }

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const ApiException(
          code: 'NETWORK_ERROR',
          message: 'Network error',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          code: 'NETWORK_ERROR',
          message: 'Insecure connection',
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request cancelled');
      case DioExceptionType.transformTimeout:
        return const ApiException(message: 'Response parsing failed');
      case DioExceptionType.unknown:
        if (e.response == null) {
          return ApiException(message: e.message ?? 'Unknown error');
        }
        return _fromResponse(e.response!);
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response == null) {
          return ApiException(message: e.message ?? 'Unknown error');
        }
        return _fromResponse(response);
    }
  }

  ApiException _fromResponse(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body['error'] is Map<String, dynamic>) {
      final error = body['error'] as Map<String, dynamic>;
      final details = error['details'];
      return ApiException(
        statusCode: response.statusCode,
        code: error['code']?.toString(),
        message: error['message']?.toString() ?? 'Request failed',
        details: details is List ? details : const [],
      );
    }
    return ApiException(
      statusCode: response.statusCode,
      message: 'Request failed (${response.statusCode})',
    );
  }
}

/// Extracts the backend `{ data: ... }` envelope (see `auth.controller.ts`).
Map<String, dynamic> apiEnvelope(Response response) {
  final body = response.data;
  if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
    return body['data'] as Map<String, dynamic>;
  }
  throw const ApiException(message: 'Unexpected response format');
}
