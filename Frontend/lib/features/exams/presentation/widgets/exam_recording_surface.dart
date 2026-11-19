/// Plays a downloaded exam recording on the platforms that can.
///
/// Recordings are only available when the teacher clicks "load": the page
/// never assumes a video exists.
library;

export 'exam_recording_surface_native.dart'
    if (dart.library.html) 'exam_recording_surface_web.dart';
