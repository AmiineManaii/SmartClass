import 'package:flutter/services.dart';

/// What the current platform can actually enforce. `screenshotBlocked` is
/// only true when a real operating-system mechanism is active.
class SecureWindowStatus {
  const SecureWindowStatus({
    required this.platform,
    required this.screenshotBlocked,
    required this.captureDetection,
  });

  const SecureWindowStatus.unsupported(this.platform)
    : screenshotBlocked = false,
      captureDetection = false;

  final String platform;
  final bool screenshotBlocked;
  final bool captureDetection;
}

abstract class SecureWindowAdapter {
  Future<SecureWindowStatus> enable({
    ValueChanged<bool>? onCaptureChanged,
  });
  Future<void> disable();
}

SecureWindowAdapter createSecureWindowAdapter() =>
    NativeSecureWindowAdapter();

/// Android applies `FLAG_SECURE` (real screenshot/recording blocking).
/// iOS cannot block screenshots; it reports screen-capture changes instead.
class NativeSecureWindowAdapter implements SecureWindowAdapter {
  static const MethodChannel _channel = MethodChannel(
    'com.smartclass.smartclass/secure_window',
  );

  @override
  Future<SecureWindowStatus> enable({
    ValueChanged<bool>? onCaptureChanged,
  }) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'screenCaptureChanged') {
        final captured = call.arguments == true;
        onCaptureChanged?.call(captured);
      }
      return null;
    });
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('enable');
      if (result == null) return const SecureWindowStatus.unsupported('unknown');
      return SecureWindowStatus(
        platform: (result['platform'] as String?) ?? 'unknown',
        screenshotBlocked: result['screenshotBlocked'] == true,
        captureDetection: result['captureDetection'] == true,
      );
    } on MissingPluginException {
      return const SecureWindowStatus.unsupported('unknown');
    } on PlatformException {
      return const SecureWindowStatus.unsupported('unknown');
    }
  }

  @override
  Future<void> disable() async {
    _channel.setMethodCallHandler(null);
    try {
      await _channel.invokeMethod<void>('disable');
    } on MissingPluginException {
      // Older build without the native channel: nothing was enabled.
    } on PlatformException {
      // Best effort: the page is closing anyway.
    }
  }
}
