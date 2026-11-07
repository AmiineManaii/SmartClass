import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_exception.dart';

class SseMessage {
  final String? event;
  final String data;
  final String? id;

  const SseMessage({
    this.event,
    required this.data,
    this.id,
  });

  Map<String, dynamic>? get jsonMap {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  @override
  String toString() => 'SseMessage(event: $event, data: $data, id: $id)';
}

/// Parses raw SSE lines into [SseMessage] instances according to the W3C SSE standard.
class SseParser {
  String? _currentEvent;
  String? _currentId;
  final List<String> _dataBuffer = [];

  SseMessage? processLine(String line) {
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) {
      if (_dataBuffer.isNotEmpty) {
        final message = SseMessage(
          event: _currentEvent,
          data: _dataBuffer.join('\n'),
          id: _currentId,
        );
        _currentEvent = null;
        _dataBuffer.clear();
        return message;
      }
      return null;
    }

    // Comment line (e.g. : ping)
    if (trimmed.startsWith(':')) {
      return null;
    }

    if (trimmed.startsWith('event:')) {
      _currentEvent = trimmed.substring(6).trim();
    } else if (trimmed.startsWith('data:')) {
      var dataContent = trimmed.substring(5);
      if (dataContent.startsWith(' ')) {
        dataContent = dataContent.substring(1);
      }
      _dataBuffer.add(dataContent);
    } else if (trimmed.startsWith('id:')) {
      _currentId = trimmed.substring(3).trim();
    }

    return null;
  }

  void reset() {
    _currentEvent = null;
    _currentId = null;
    _dataBuffer.clear();
  }
}

/// Long-lived SSE connection manager with auto-reconnect, exponential backoff,
/// and jitter.
///
/// Stops retrying silently after [maxConsecutiveFailures] consecutive errors
/// (default 6) to avoid spamming the console when an endpoint is unavailable.
/// Call [resume] to restart the retry cycle manually.
class SseConnectionManager {
  final ApiClient client;
  final String path;
  final Map<String, dynamic>? queryParameters;

  /// Maximum consecutive failed attempts before the manager pauses retrying.
  final int maxConsecutiveFailures;

  final Random _random;

  CancelToken? _cancelToken;
  bool _isDisposed = false;
  bool _isPaused = false;
  int _attempt = 0;
  int _consecutiveFailures = 0;
  Timer? _reconnectTimer;

  final _controller = StreamController<SseMessage>.broadcast();

  Stream<SseMessage> get stream => _controller.stream;

  SseConnectionManager({
    required this.client,
    required this.path,
    this.queryParameters,
    this.maxConsecutiveFailures = 6,
    Random? random,
  }) : _random = random ?? Random();

  void connect() {
    if (_isDisposed) return;
    _isPaused = false;
    _consecutiveFailures = 0;
    _attempt = 0;
    _startConnection();
  }

  void pause() {
    _isPaused = true;
    _cancelToken?.cancel('Paused');
    _cancelToken = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void resume() {
    if (_isDisposed) return;
    _isPaused = false;
    _attempt = 0;
    _consecutiveFailures = 0;
    _startConnection();
  }

  void dispose() {
    _isDisposed = true;
    _isPaused = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cancelToken?.cancel('Disposed');
    _cancelToken = null;
    _controller.close();
  }

  Future<void> _startConnection() async {
    if (_isDisposed || _isPaused) return;

    // Stop retrying silently once we've hit the failure cap.
    if (_consecutiveFailures >= maxConsecutiveFailures) {
      debugPrint('[SSE] $path — endpoint unreachable after $maxConsecutiveFailures attempts, giving up. Call resume() to retry.');
      return;
    }

    _reconnectTimer?.cancel();
    _cancelToken?.cancel();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final parser = SseParser();

    try {
      // Notify listeners to resync on (re)connect
      _controller.add(const SseMessage(
        event: 'resync',
        data: '{"type":"resync"}',
      ));

      await client.getStream(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onLine: (line) {
          _attempt = 0;
          _consecutiveFailures = 0;
          final message = parser.processLine(line);
          if (message != null && !_controller.isClosed) {
            _controller.add(message);
          }
        },
      );

      // Normal completion / stream close: reset failures and reconnect
      _consecutiveFailures = 0;
      _onConnectionLost();
    } catch (e) {
      if (cancelToken.isCancelled || _isDisposed || _isPaused) {
        return;
      }
      if (e is ApiException && (e.statusCode == 401 || e.code == 'AUTH_TOKEN_EXPIRED')) {
        try {
          await client.refreshSession();
        } catch (_) {}
      }
      _consecutiveFailures++;
      // Only log the first failure and every 3rd one to avoid spamming.
      if (_consecutiveFailures == 1 || _consecutiveFailures % 3 == 0) {
        debugPrint('[SSE] $path — connection error ($_consecutiveFailures/$maxConsecutiveFailures): $e');
      }
      _onConnectionLost();
    }
  }

  void _onConnectionLost() {
    if (_isDisposed || _isPaused) return;
    if (_consecutiveFailures >= maxConsecutiveFailures) {
      debugPrint('[SSE] $path — max failures reached, stopped retrying.');
      return;
    }

    _attempt++;
    // Exponential backoff capped at 30 seconds with jitter
    final baseSeconds = min(pow(2, _attempt).toInt(), 30);
    final jitterMs = _random.nextInt(1000);
    final delay = Duration(seconds: baseSeconds, milliseconds: jitterMs);

    debugPrint('[SSE] Reconnecting in ${delay.inMilliseconds}ms (attempt $_attempt)...');

    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed && !_isPaused) {
        _startConnection();
      }
    });
  }
}
