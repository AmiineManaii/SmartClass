export 'secure_window_native.dart'
    if (dart.library.js_interop) 'secure_window_web.dart'
    if (dart.library.html) 'secure_window_web.dart';
