// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:js' as js;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'exam_camera_types.dart';

/// Real browser camera: `getUserMedia` preview plus a `MediaRecorder` rolling
/// buffer and real-time client-side face & gaze anti-fraud analysis via MediaPipe.
class WebExamCameraSession implements ExamCameraSession {
  static int _viewCounter = 0;

  html.MediaStream? _stream;
  html.MediaRecorder? _recorder;
  html.VideoElement? _video;
  final List<_BufferedChunk> _chunks = <_BufferedChunk>[];
  late final String _viewType;
  String _mimeType = 'video/webm';
  String? _errorKey;
  String? _errorDetail;
  Timer? _analysisTimer;
  void Function(int faceCount, bool gazeOffScreen)? _onAnalysis;

  @override
  Future<ExamCameraStatus> start() async {
    try {
      final devices = html.window.navigator.mediaDevices;
      if (devices == null) {
        _errorKey = 'exam_camera_unavailable';
        return _status(supported: false, active: false, recording: false);
      }
      final stream = await devices.getUserMedia(<String, dynamic>{
        'audio': false,
        'video': <String, dynamic>{
          'width': <String, dynamic>{'ideal': 640},
          'height': <String, dynamic>{'ideal': 480},
          'facingMode': 'user',
        },
      });
      _stream = stream;
      _attachPreview(stream);
      _startRecorder(stream);
      _errorKey = null;
      _errorDetail = null;
      return _status(
        supported: true,
        active: true,
        recording: _recorder != null,
      );
    } on html.DomException catch (error) {
      _errorKey = _isPermission(error)
          ? 'exam_camera_permission_denied'
          : 'exam_camera_unavailable';
      _errorDetail = error.message;
      return _status(supported: true, active: false, recording: false);
    } catch (error) {
      _errorKey = 'exam_camera_unavailable';
      _errorDetail = error.toString();
      return _status(supported: false, active: false, recording: false);
    }
  }

  bool _isPermission(html.DomException error) {
    final name = error.name.toLowerCase();
    return name.contains('notallowed') || name.contains('permission');
  }

  void _attachPreview(html.MediaStream stream) {
    _viewType = 'smartclass-exam-camera-${_viewCounter++}';
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..srcObject = stream
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)'
      ..style.willChange = 'transform'
      ..style.setProperty('contain', 'none');
    video.setAttribute('playsinline', 'true');
    _video = video;
    video.play().catchError((_) {});
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => video,
    );
  }

  void _startRecorder(html.MediaStream stream) {
    String? selected;
    for (final candidate in const <String>[
      'video/webm;codecs=vp9',
      'video/webm;codecs=vp8',
      'video/webm',
    ]) {
      try {
        if (html.MediaRecorder.isTypeSupported(candidate)) {
          selected = candidate;
          break;
        }
      } catch (_) {
        // isTypeSupported may be missing on older browsers.
      }
    }
    try {
      final recorder = selected == null
          ? html.MediaRecorder(stream)
          : html.MediaRecorder(stream, <String, dynamic>{'mimeType': selected});
      recorder.addEventListener('dataavailable', (event) {
        if (event is! html.BlobEvent) return;
        final blob = event.data;
        if (blob == null || blob.size == 0) return;
        _chunks.add(_BufferedChunk(DateTime.now(), blob));
        _pruneChunks();
      });
      recorder.start(1000);
      _recorder = recorder;
      _mimeType = (recorder.mimeType ?? selected ?? 'video/webm');
    } catch (_) {
      _recorder = null;
    }
  }

  void _pruneChunks() {
    if (_chunks.length <= 2) return;
    final cutoff = DateTime.now().subtract(const Duration(seconds: 20));
    // The first chunk carries the container header: always keep it.
    _chunks.removeWhere(
      (chunk) => chunk != _chunks.first && chunk.at.isBefore(cutoff),
    );
  }

  @override
  Widget buildPreview(BuildContext context) {
    if (_video == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: HtmlElementView(viewType: _viewType),
    );
  }

  @override
  Future<ExamCameraClip?> captureClip() async {
    final recorder = _recorder;
    if (recorder == null || _chunks.isEmpty) return null;
    try {
      if (recorder.state == 'recording') recorder.requestData();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_chunks.isEmpty) return null;

    final cutoff = DateTime.now().subtract(const Duration(seconds: 10));
    final header = _chunks.first;
    final selected = <html.Blob>[
      header.blob,
      for (final chunk in _chunks.skip(1))
        if (!chunk.at.isBefore(cutoff)) chunk.blob,
    ];
    final firstAt = _chunks
        .firstWhere((chunk) => !chunk.at.isBefore(cutoff), orElse: () => header)
        .at;
    final lastAt = _chunks.last.at;
    final blob = html.Blob(selected, _mimeType.split(';').first);
    final bytes = await _readBytes(blob);
    if (bytes == null || bytes.isEmpty) return null;
    return ExamCameraClip(
      bytes: bytes,
      mimeType: _mimeType.split(';').first,
      durationMs: lastAt.difference(firstAt).inMilliseconds.abs(),
    );
  }

  Future<Uint8List?> _readBytes(html.Blob blob) {
    final completer = Completer<Uint8List?>();
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(result);
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  @override
  void setFaceAnalysisListener(void Function(int faceCount, bool gazeOffScreen)? onAnalysis) {
    _onAnalysis = onAnalysis;
    _analysisTimer?.cancel();
    if (onAnalysis == null) return;

    _analysisTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      final video = _video;
      if (video == null || video.readyState < 2) return;
      try {
        if (js.context.hasProperty('_smartclassDetectFace')) {
          final res = js.context.callMethod('_smartclassDetectFace', [video]);
          if (res != null) {
            final int count = (res['faceCount'] as num?)?.toInt() ?? 1;
            final bool gazeOff = res['gazeOffScreen'] == true;
            _onAnalysis?.call(count, gazeOff);
          }
        }
      } catch (_) {}
    });
  }

  @override
  Future<void> stop() async {
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _onAnalysis = null;
    try {
      if (_recorder != null && _recorder!.state != 'inactive') {
        _recorder!.stop();
      }
    } catch (_) {}
    _recorder = null;
    _chunks.clear();
    final stream = _stream;
    if (stream != null) {
      final tracks = stream.getTracks();
      for (var i = 0; i < tracks.length; i++) {
        try {
          tracks[i].stop();
        } catch (_) {}
      }
    }
    _stream = null;
    final video = _video;
    if (video != null) {
      try {
        video.pause();
        video.srcObject = null;
      } catch (_) {}
    }
    _video = null;
  }

  ExamCameraStatus _status({
    required bool supported,
    required bool active,
    required bool recording,
  }) {
    return ExamCameraStatus(
      supported: supported,
      active: active,
      recording: recording,
      errorKey: _errorKey,
      errorDetail: _errorDetail,
    );
  }
}

class _BufferedChunk {
  const _BufferedChunk(this.at, this.blob);

  final DateTime at;
  final html.Blob blob;
}

ExamCameraSession createExamCameraSession() => WebExamCameraSession();
