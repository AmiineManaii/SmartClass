/// Camera entry point for the exam attempt page.
///
/// - Web: real `getUserMedia` preview + `MediaRecorder` rolling buffer.
/// - Mobile: no camera plugin is compiled in this build; the native adapter
///   reports that honestly instead of faking a camera or a recording.
library;

export 'exam_camera_native.dart'
    if (dart.library.js_interop) 'exam_camera_web.dart'
    if (dart.library.html) 'exam_camera_web.dart';
export 'exam_camera_types.dart';
