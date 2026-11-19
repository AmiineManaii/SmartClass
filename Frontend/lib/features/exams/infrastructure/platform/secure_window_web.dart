import 'package:flutter/foundation.dart';

import 'secure_window_native.dart';

export 'secure_window_native.dart'
    show SecureWindowAdapter, SecureWindowStatus;

/// The browser offers no API that blocks screenshots. Claiming otherwise
/// would be dishonest, so this adapter only reports the limitation.
class WebSecureWindowAdapter implements SecureWindowAdapter {
  @override
  Future<SecureWindowStatus> enable({
    ValueChanged<bool>? onCaptureChanged,
  }) async {
    return const SecureWindowStatus.unsupported('web');
  }

  @override
  Future<void> disable() async {}
}

SecureWindowAdapter createSecureWindowAdapter() => WebSecureWindowAdapter();
