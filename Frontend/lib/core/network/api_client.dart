import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Dio-based HTTP client for the SmartClass API.
///
/// - Base URL from [ApiConfig] (app `.env` `API_BASE_URL`, overridable via `--dart-define`)
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
    // Enable browser cookie transmission and CORS credentials on Web platform
    options.extra['withCredentials'] = true;
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
      String? newToken;
      try {
        newToken = await (_refreshFuture ??=
            _performRefresh().whenComplete(() => _refreshFuture = null));
      } catch (refreshErr) {
        // Only clear tokens if the refresh itself was rejected by the server (401/403)
        // or if there is no refresh token in storage. Temporary network errors must NOT
        // wipe valid session tokens.
        final isAuthFailure = (refreshErr is DioException &&
                (refreshErr.response?.statusCode == 401 ||
                    refreshErr.response?.statusCode == 403)) ||
            (refreshErr is ApiException &&
                (refreshErr.statusCode == 401 || refreshErr.statusCode == 403));

        if (isAuthFailure) {
          await tokens.clear();
          onUnauthorized?.call();
        }
        return handler.next(err);
      }

      if (newToken != null && newToken.isNotEmpty) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        err.requestOptions.extra['retried'] = true;
        // If the request had token query parameter (like SSE stream), update it too
        if (err.requestOptions.queryParameters.containsKey('token')) {
          err.requestOptions.queryParameters['token'] = newToken;
        }
        try {
          final retry = await _dio.fetch<dynamic>(err.requestOptions);
          return handler.resolve(retry);
        } on DioException catch (retryErr) {
          // Retry failed due to network / stream error: reject with that error,
          // but NEVER wipe tokens since the refreshed session credentials are valid!
          return handler.next(retryErr);
        } catch (_) {
          return handler.next(err);
        }
      } else {
        await tokens.clear();
        onUnauthorized?.call();
      }
    }
    handler.next(err);
  }

  /// Public entry point for explicit session refresh (e.g. before long-lived SSE connections)
  Future<String?> refreshSession() async {
    return await (_refreshFuture ??=
        _performRefresh().whenComplete(() => _refreshFuture = null));
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'AUTH_NO_REFRESH_TOKEN',
        message: 'No refresh token available',
      );
    }
    final res = await _dio.post<dynamic>(
      '${ApiConfig.apiPrefix}/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: const {'authenticated': false, 'withCredentials': true}),
    );
    final data = apiEnvelope(res);
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'AUTH_INVALID_REFRESH_RESPONSE',
        message: 'Invalid refresh response',
      );
    }
    final isRemember = await tokens.isRememberMe();
    final savedEmail = await tokens.getSavedEmail();
    await tokens.saveSession(
      accessToken: access,
      refreshToken: refresh,
      rememberMe: isRemember,
      email: savedEmail,
    );
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

  Future<List<int>> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    final res = await _guard(() => _dio.get<List<int>>(
          path,
          queryParameters: queryParameters,
          options: Options(
            responseType: ResponseType.bytes,
            extra: {'authenticated': authenticated},
          ),
        ));
    return res.data ?? <int>[];
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Duration? receiveTimeout,
    bool authenticated = true,
  }) {
    return _guard(() => _dio.post<T>(
          path,
          data: data,
          options: Options(
            receiveTimeout: receiveTimeout,
            extra: {'authenticated': authenticated},
          ),
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

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    bool authenticated = true,
  }) {
    return _guard(() => _dio.delete<T>(
          path,
          data: data,
          options: Options(extra: {'authenticated': authenticated}),
        ));
  }

  /// Raw SSE/event stream POST (long local generations).
  ///
  /// Uses [ApiConfig.streamReceiveTimeout] (minutes, not seconds): the
  /// local LLM can stay silent for 20 s+ before the first token while it
  /// runs server-side tools, and the global 15 s receive timeout would
  /// otherwise surface as a fake "no internet" error mid-generation.
  /// Emits every response line (including SSE `data:` frames) to [onLine].
  /// Throws [ApiException] on non-200 responses (body drained and mapped)
  /// and `REQUEST_CANCELLED` when [cancelToken] cancels.
  Future<void> postStream(
    String path, {
    Object? data,
    required void Function(String line) onLine,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) async {
    final headers = <String, dynamic>{
      'X-Request-Id': const Uuid().v4(),
      'Accept': 'text/event-stream',
    };
    if (authenticated) {
      final accessToken = await tokens.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    late Response<ResponseBody> res;
    try {
      res = await _dio.post<ResponseBody>(
        path,
        data: data,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          // Per-request override: the base 15 s receive timeout must not
          // apply to minute-long AI streams (backend also pings every
          // 10 s with an SSE comment to keep the socket alive), and the
          // 10 s send timeout must not abort large PDF uploads.
          receiveTimeout: ApiConfig.streamReceiveTimeout,
          sendTimeout: const Duration(minutes: 5),
          extra: {'authenticated': authenticated},
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const ApiException(
          code: 'REQUEST_CANCELLED',
          message: 'Request cancelled',
        );
      }
      // With a streamed response the error body is a ResponseBody: drain it
      // so the real backend error code reaches the UI (not a generic one).
      final errorRes = e.response;
      if (errorRes != null && errorRes.data is ResponseBody) {
        throw await _streamError(Response<ResponseBody>(
          requestOptions: errorRes.requestOptions,
          statusCode: errorRes.statusCode,
          data: errorRes.data as ResponseBody,
        ));
      }
      throw _toApiException(e);
    }
    final stream = res.data?.stream;
    if (res.statusCode != 200 || stream == null) {
      throw await _streamError(res);
    }
    var buffer = '';
    try {
      await for (final chunk in stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();
        for (final line in lines) {
          onLine(line);
        }
      }
      if (buffer.trim().isNotEmpty) onLine(buffer);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const ApiException(
          code: 'REQUEST_CANCELLED',
          message: 'Request cancelled',
        );
      }
      rethrow;
    }
  }

  /// Emits every response line (including SSE `data:` frames) to [onLine] from a GET endpoint.
  Future<void> getStream(
    String path, {
    Map<String, dynamic>? queryParameters,
    required void Function(String line) onLine,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) async {
    final headers = <String, dynamic>{
      'X-Request-Id': const Uuid().v4(),
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache, no-store',
    };
    final qParams = Map<String, dynamic>.from(queryParameters ?? {});
    String? currentToken;
    if (authenticated) {
      currentToken = await tokens.readAccessToken();
      if (currentToken != null && currentToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $currentToken';
        qParams['token'] = currentToken;
      }
    }

    Future<Response<ResponseBody>> executeStreamRequest(String? activeToken) {
      final reqHeaders = Map<String, dynamic>.from(headers);
      final reqQParams = Map<String, dynamic>.from(qParams);
      if (authenticated && activeToken != null && activeToken.isNotEmpty) {
        reqHeaders['Authorization'] = 'Bearer $activeToken';
        reqQParams['token'] = activeToken;
      }
      return _dio.get<ResponseBody>(
        path,
        queryParameters: reqQParams.isNotEmpty ? reqQParams : null,
        options: Options(
          responseType: ResponseType.stream,
          headers: reqHeaders,
          // SSE connections are persistent keep-alive streams; avoid arbitrary client timeouts
          receiveTimeout: Duration.zero,
          sendTimeout: const Duration(minutes: 5),
          extra: {
            'authenticated': authenticated,
            'withCredentials': true,
          },
        ),
        cancelToken: cancelToken,
      );
    }

    late Response<ResponseBody> res;
    try {
      res = await executeStreamRequest(currentToken);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const ApiException(
          code: 'REQUEST_CANCELLED',
          message: 'Request cancelled',
        );
      }
      // If 401 on stream and authenticated, proactively refresh session and retry once
      if (authenticated &&
          (e.response?.statusCode == 401 ||
              e.error?.toString().contains('401') == true)) {
        try {
          final refreshed = await refreshSession();
          if (refreshed != null && refreshed.isNotEmpty) {
            res = await executeStreamRequest(refreshed);
          } else {
            throw _toApiException(e);
          }
        } catch (_) {
          final errorRes = e.response;
          if (errorRes != null && errorRes.data is ResponseBody) {
            throw await _streamError(Response<ResponseBody>(
              requestOptions: errorRes.requestOptions,
              statusCode: errorRes.statusCode,
              data: errorRes.data as ResponseBody,
            ));
          }
          throw _toApiException(e);
        }
      } else {
        final errorRes = e.response;
        if (errorRes != null && errorRes.data is ResponseBody) {
          throw await _streamError(Response<ResponseBody>(
            requestOptions: errorRes.requestOptions,
            statusCode: errorRes.statusCode,
            data: errorRes.data as ResponseBody,
          ));
        }
        throw _toApiException(e);
      }
    }
    final stream = res.data?.stream;
    if (res.statusCode != 200 || stream == null) {
      throw await _streamError(res);
    }
    var buffer = '';
    try {
      await for (final chunk in stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();
        for (final line in lines) {
          onLine(line);
        }
      }
      if (buffer.trim().isNotEmpty) onLine(buffer);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const ApiException(
          code: 'REQUEST_CANCELLED',
          message: 'Request cancelled',
        );
      }
      rethrow;
    }
  }

  Future<ApiException> _streamError(Response<ResponseBody> res) async {
    try {
      final bytes = <int>[];
      final stream = res.data?.stream;
      if (stream != null) {
        await for (final chunk in stream) {
          bytes.addAll(chunk);
        }
      }
      final body = jsonDecode(utf8.decode(bytes, allowMalformed: true));
      if (body is Map<String, dynamic>) {
        return _fromResponse(
          Response(
            requestOptions: res.requestOptions,
            statusCode: res.statusCode,
            data: body,
          ),
        );
      }
    } catch (_) {
      // Fall through to the generic failure below.
    }
    return ApiException(
      statusCode: res.statusCode,
      message: 'Request failed (${res.statusCode})',
    );
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
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException(
          code: 'TIMEOUT',
          message: 'Délai d\'attente dépassé.',
        );
      case DioExceptionType.connectionTimeout:
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
