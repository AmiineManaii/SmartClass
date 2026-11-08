// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'live_speech_recorder_models.dart';

class LiveSpeechRecorder {
  LiveSpeechRecorder._();
  static final LiveSpeechRecorder instance = LiveSpeechRecorder._();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  String _preferredLanguage = 'auto';
  String get preferredLanguage => _preferredLanguage;

  DateTime? _startedAt;
  String _speakerName = 'Enseignant';
  final List<CapturedSpeechSegment> _segments = [];
  String _detectedLang = 'auto';

  String? _sessionId;
  String? _authToken;
  String? _backendUrl;

  js.JsObject? _speechRecognition;
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _mediaChunks = [];
  final List<html.MediaStream> _activeStreams = [];
  String _recordedMimeType = 'video/webm';

  // Canvas Compositor for Zoom/Teams Meeting Recording
  html.CanvasElement? _canvas;
  html.CanvasRenderingContext2D? _ctx;
  html.VideoElement? _cameraVideo;
  html.VideoElement? _screenVideo;
  bool _isScreenSharing = false;
  Timer? _renderTimer;

  void setPreferredLanguage(String lang) {
    _preferredLanguage = lang;
    if (_isRecording && _speechRecognition != null) {
      try {
        final resolved = _resolveRecognitionLang(lang);
        _speechRecognition!['lang'] = resolved;
      } catch (_) {}
    }
  }

  void updateCameraTrack(dynamic track) {
    if (_cameraVideo == null) return;
    _attachTrackToVideo(_cameraVideo!, track);
  }

  void updateScreenShareTrack(dynamic track, [bool isSharing = true]) {
    _isScreenSharing = (track != null && isSharing);
    if (_screenVideo == null) return;
    _attachTrackToVideo(_screenVideo!, track);
    debugPrint('[LiveSpeechRecorder] Screen share track updated: isSharing=$_isScreenSharing');
  }

  void _attachTrackToVideo(html.VideoElement video, dynamic track) {
    if (track == null) {
      video.srcObject = null;
      return;
    }
    try {
      dynamic actualTrack = track;
      try {
        if (actualTrack.mediaStream != null) {
          final ms = actualTrack.mediaStream;
          try {
            if (ms.jsStream != null) {
              actualTrack = ms.jsStream;
            } else {
              actualTrack = ms;
            }
          } catch (_) {
            actualTrack = ms;
          }
        }
      } catch (_) {}
      try {
        if (actualTrack.mediaStreamTrack != null) {
          final mst = actualTrack.mediaStreamTrack;
          try {
            if (mst.jsTrack != null) {
              actualTrack = mst.jsTrack;
            } else {
              actualTrack = mst;
            }
          } catch (_) {
            actualTrack = mst;
          }
        }
      } catch (_) {}
      try {
        if (actualTrack.jsTrack != null) {
          actualTrack = actualTrack.jsTrack;
        }
      } catch (_) {}

      if (actualTrack is html.MediaStream) {
        video.srcObject = actualTrack;
      } else if (actualTrack is html.MediaStreamTrack) {
        final stream = html.MediaStream([actualTrack]);
        video.srcObject = stream;
      } else {
        final win = js.context;
        final jsMediaStream = win['MediaStream'] as js.JsFunction;
        final stream = js.JsObject(jsMediaStream, [
          js.JsArray.from([actualTrack]),
        ]);
        final jsVideo = js.JsObject.fromBrowserObject(video);
        jsVideo['srcObject'] = stream;
      }
      video.muted = true;
      video.setAttribute('playsinline', 'true');
      video.play().catchError((_) {});
    } catch (e) {
      debugPrint('[LiveSpeechRecorder] _attachTrackToVideo error: $e');
    }
  }

  String _resolveRecognitionLang(String lang) {
    switch (lang) {
      case 'ar-TN':
        return 'ar-TN';
      case 'ar':
        return 'ar-SA';
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      default:
        final navLang = html.window.navigator.language.toLowerCase();
        if (navLang.startsWith('ar')) return 'ar-TN';
        if (navLang.startsWith('en')) return 'en-US';
        return 'fr-FR';
    }
  }

  Future<void> start({
    String speakerName = 'Enseignant',
    String language = 'auto',
    String? sessionId,
    String? authToken,
    String? backendUrl,
    dynamic initialCameraTrack,
    dynamic initialScreenTrack,
  }) async {
    _isRecording = true;
    _startedAt = DateTime.now();
    _speakerName = speakerName;
    _preferredLanguage = language;
    _sessionId = sessionId;
    _authToken = authToken;
    _backendUrl = backendUrl;
    _segments.clear();
    _mediaChunks.clear();
    _activeStreams.clear();
    _detectedLang = language;

    _startSpeechRecognition();
    await _startCompositorRecorder(
      initialCameraTrack: initialCameraTrack,
      initialScreenTrack: initialScreenTrack,
    );
  }

  void _startSpeechRecognition() {
    try {
      final hasSpeech = js.context.hasProperty('SpeechRecognition') ||
          js.context.hasProperty('webkitSpeechRecognition');
      if (!hasSpeech) return;

      final ctor = js.context.hasProperty('SpeechRecognition')
          ? js.context['SpeechRecognition']
          : js.context['webkitSpeechRecognition'];

      final recognition = js.JsObject(ctor as js.JsFunction, const []);
      _speechRecognition = recognition;

      recognition['continuous'] = true;
      recognition['interimResults'] = false;
      recognition['lang'] = _resolveRecognitionLang(_preferredLanguage);

      recognition['onresult'] = (dynamic event) {
        try {
          final results = event['results'];
          final int resultIndex = event['resultIndex'] ?? 0;
          final int length = results['length'] ?? 0;
          for (var i = resultIndex; i < length; i++) {
            final res = results[i];
            final bool isFinal = res['isFinal'] == true;
            if (isFinal) {
              final alt = res[0];
              final transcript = (alt['transcript'] as String? ?? '').trim();
              if (transcript.isNotEmpty) {
                final now = DateTime.now();
                final elapsed = _startedAt != null
                    ? now.difference(_startedAt!).inMilliseconds / 1000.0
                    : 0.0;
                final estDuration =
                    (transcript.split(RegExp(r'\s+')).length * 0.45)
                        .clamp(1.5, 18.0);
                final startSec = (elapsed - estDuration).clamp(0.0, elapsed);
                final detected = _inferLanguageFromText(transcript);
                if (detected != 'auto') {
                  _detectedLang = detected;
                }
                _segments.add(
                  CapturedSpeechSegment(
                    startSeconds: double.parse(startSec.toStringAsFixed(1)),
                    endSeconds: double.parse(elapsed.toStringAsFixed(1)),
                    text: transcript,
                    speaker: _speakerName,
                    language: detected,
                  ),
                );
              }
            }
          }
        } catch (e) {
          debugPrint('[LiveSpeechRecorder] onresult error: $e');
        }
      };

      recognition['onend'] = (dynamic _) {
        if (_isRecording && _speechRecognition != null) {
          try {
            _speechRecognition!.callMethod('start', const []);
          } catch (_) {}
        }
      };

      recognition.callMethod('start', const []);
    } catch (e) {
      debugPrint('[LiveSpeechRecorder] SpeechRecognition init error: $e');
    }
  }

  String _inferLanguageFromText(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(text)) {
      final tunisianMarkers = RegExp(
        r'(باش|علاش|كيفاش|وقتاش|شنوة|شنو|برشا|توا|ملخر|يعطيك|خاطر|متاع|اكثر|نجمو|نشوفو)',
      );
      if (tunisianMarkers.hasMatch(text)) return 'ar-TN';
      return 'ar';
    }
    final arabiziMarkers = RegExp(
      r'\b(bch|bech|3lech|kifech|wa9tech|chnoua|barcha|tawa|5ater|mte3|najmou|nchoufou|3aslema|chabeb|lyoum|fama)\b',
      caseSensitive: false,
    );
    if (arabiziMarkers.hasMatch(text)) return 'ar-TN';
    if (_preferredLanguage != 'auto') return _preferredLanguage;
    return 'fr';
  }

  Future<void> _startCompositorRecorder({
    dynamic initialCameraTrack,
    dynamic initialScreenTrack,
  }) async {
    try {
      // 1. Setup Offscreen Canvas (1280x720, 16:9 standard HD)
      final canvas = html.CanvasElement(width: 1280, height: 720);
      _canvas = canvas;
      _ctx = canvas.context2D;

      // 2. Setup Offscreen Video Elements (attached to DOM so Chrome video decoders remain active)
      final camVideo = html.VideoElement()
        ..autoplay = true
        ..muted = true;
      camVideo.setAttribute('playsinline', 'true');
      camVideo.style
        ..position = 'fixed'
        ..left = '-9999px'
        ..top = '-9999px'
        ..width = '320px'
        ..height = '180px'
        ..opacity = '0.01'
        ..pointerEvents = 'none'
        ..zIndex = '-9999';
      html.document.body?.append(camVideo);
      _cameraVideo = camVideo;

      final scrVideo = html.VideoElement()
        ..autoplay = true
        ..muted = true;
      scrVideo.setAttribute('playsinline', 'true');
      scrVideo.style
        ..position = 'fixed'
        ..left = '-9999px'
        ..top = '-9999px'
        ..width = '320px'
        ..height = '180px'
        ..opacity = '0.01'
        ..pointerEvents = 'none'
        ..zIndex = '-9999';
      html.document.body?.append(scrVideo);
      _screenVideo = scrVideo;

      if (initialCameraTrack != null) {
        _attachTrackToVideo(camVideo, initialCameraTrack);
      }
      if (initialScreenTrack != null) {
        _isScreenSharing = true;
        _attachTrackToVideo(scrVideo, initialScreenTrack);
      }

      // If no initial camera track provided, fallback to browser getUserMedia camera
      if (initialCameraTrack == null) {
        try {
          final camStream = await html.window.navigator.mediaDevices?.getUserMedia({
            'video': {'width': 1280, 'height': 720, 'frameRate': 30},
            'audio': false,
          });
          if (camStream != null) {
            _activeStreams.add(camStream);
            camVideo.srcObject = camStream;
            camVideo.play().catchError((_) {});
          }
        } catch (_) {}
      }

      // 3. Acquire Microphone Stream with Acoustic Echo Cancellation
      html.MediaStream? micStream;
      try {
        final mediaDevices = html.window.navigator.mediaDevices;
        if (mediaDevices != null) {
          micStream = await mediaDevices.getUserMedia({
            'audio': {
              'echoCancellation': true,
              'noiseSuppression': true,
              'autoGainControl': true,
            },
            'video': false,
          });
        }
      } catch (e) {
        debugPrint('[LiveSpeechRecorder] getUserMedia mic error: $e');
      }

      // 4. Start 30 fps Compositor Render Loop
      _renderTimer?.cancel();
      _renderTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
        _drawCompositeFrame();
      });

      // 5. Capture Stream from Canvas + Microphone Audio
      final jsCanvas = js.JsObject.fromBrowserObject(canvas);
      html.MediaStream compositeStream;
      if (jsCanvas.hasProperty('captureStream')) {
        final rawStream = jsCanvas.callMethod('captureStream', [30]);
        compositeStream = rawStream as html.MediaStream;
      } else {
        compositeStream = canvas.captureStream(30);
      }

      if (micStream != null) {
        _activeStreams.add(micStream);
        for (final track in micStream.getAudioTracks()) {
          compositeStream.addTrack(track);
        }
      }
      _activeStreams.add(compositeStream);

      // 6. MediaRecorder initialization
      String mimeType = 'video/webm;codecs=vp8,opus';
      if (!html.MediaRecorder.isTypeSupported(mimeType)) {
        mimeType = 'video/webm';
      }
      if (!html.MediaRecorder.isTypeSupported(mimeType)) {
        mimeType = '';
      }
      _recordedMimeType = mimeType.isNotEmpty ? mimeType : 'video/webm';

      _mediaRecorder = mimeType.isNotEmpty
          ? html.MediaRecorder(compositeStream, {'mimeType': mimeType})
          : html.MediaRecorder(compositeStream);

      _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _mediaChunks.add(blobEvent.data!);
        }
      });

      _mediaRecorder!.start(1000);
      debugPrint('[LiveSpeechRecorder] Compositor MediaRecorder started ($_recordedMimeType)');
    } catch (e) {
      debugPrint('[LiveSpeechRecorder] Compositor init error: $e');
    }
  }

  void _drawCompositeFrame() {
    if (!_isRecording || _ctx == null || _canvas == null) return;
    final ctx = _ctx!;
    const double w = 1280.0;
    const double h = 720.0;

    final hasScreen = _isScreenSharing &&
        _screenVideo != null &&
        (_screenVideo!.readyState >= 1 || _screenVideo!.videoWidth > 0);
    final hasCamera = _cameraVideo != null &&
        (_cameraVideo!.readyState >= 1 || _cameraVideo!.videoWidth > 0);

    if (hasScreen) {
      // 1. Draw screen share (PowerPoint/Presentation/Desktop) full frame 1280x720
      ctx.fillStyle = '#0F172A';
      ctx.fillRect(0, 0, w, h);
      ctx.drawImageScaled(_screenVideo!, 0, 0, w, h);

      // 2. Picture-in-Picture for teacher camera in bottom-right corner (Zoom/Teams style)
      if (hasCamera) {
        const double pipW = 280.0;
        const double pipH = 158.0;
        const double pipX = w - pipW - 24.0;
        const double pipY = h - pipH - 24.0;
        const double r = 12.0;

        ctx.save();
        ctx.shadowColor = 'rgba(0, 0, 0, 0.6)';
        ctx.shadowBlur = 14;
        ctx.shadowOffsetX = 0;
        ctx.shadowOffsetY = 6;

        ctx.beginPath();
        ctx.moveTo(pipX + r, pipY);
        ctx.lineTo(pipX + pipW - r, pipY);
        ctx.arcTo(pipX + pipW, pipY, pipX + pipW, pipY + r, r);
        ctx.lineTo(pipX + pipW, pipY + pipH - r);
        ctx.arcTo(pipX + pipW, pipY + pipH, pipX + pipW - r, pipY + pipH, r);
        ctx.lineTo(pipX + r, pipY + pipH);
        ctx.arcTo(pipX, pipY + pipH, pipX, pipY + pipH - r, r);
        ctx.lineTo(pipX, pipY + r);
        ctx.arcTo(pipX, pipY, pipX + r, pipY, r);
        ctx.closePath();
        ctx.clip();

        ctx.drawImageScaled(_cameraVideo!, pipX, pipY, pipW, pipH);
        ctx.restore();

        // Crisp SmartClass border around PiP
        ctx.save();
        ctx.strokeStyle = '#3B82F6';
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.moveTo(pipX + r, pipY);
        ctx.lineTo(pipX + pipW - r, pipY);
        ctx.arcTo(pipX + pipW, pipY, pipX + pipW, pipY + r, r);
        ctx.lineTo(pipX + pipW, pipY + pipH - r);
        ctx.arcTo(pipX + pipW, pipY + pipH, pipX + pipW - r, pipY + pipH, r);
        ctx.lineTo(pipX + r, pipY + pipH);
        ctx.arcTo(pipX, pipY + pipH, pipX, pipY + pipH - r, r);
        ctx.lineTo(pipX, pipY + r);
        ctx.arcTo(pipX, pipY, pipX + r, pipY, r);
        ctx.closePath();
        ctx.stroke();

        // Speaker name pill inside PiP
        ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
        ctx.fillRect(pipX + 8, pipY + pipH - 24, 120, 18);
        ctx.fillStyle = '#FFFFFF';
        ctx.font = 'bold 11px Inter, sans-serif';
        ctx.fillText(_speakerName, pipX + 14, pipY + pipH - 10);
        ctx.restore();
      }
    } else if (hasCamera) {
      // Draw camera full frame
      ctx.fillStyle = '#0F172A';
      ctx.fillRect(0, 0, w, h);
      ctx.drawImageScaled(_cameraVideo!, 0, 0, w, h);
    } else {
      // SmartClass Lecture presentation card (when camera muted)
      ctx.fillStyle = '#0F172A';
      ctx.fillRect(0, 0, w, h);

      final gradient = ctx.createRadialGradient(w / 2, h / 2, 50, w / 2, h / 2, 450);
      gradient.addColorStop(0, '#1E293B');
      gradient.addColorStop(1, '#0A0F1D');
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, w, h);

      // Central avatar circle
      ctx.beginPath();
      ctx.arc(w / 2, h / 2 - 40, 56, 0, 6.283);
      ctx.fillStyle = '#2563EB';
      ctx.fill();
      ctx.strokeStyle = '#3B82F6';
      ctx.lineWidth = 3;
      ctx.stroke();

      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 40px Inter, sans-serif';
      ctx.textAlign = 'center';
      final initial = _speakerName.isNotEmpty ? _speakerName[0].toUpperCase() : 'P';
      ctx.fillText(initial, w / 2, h / 2 - 25);

      ctx.font = 'bold 22px Inter, sans-serif';
      ctx.fillText(_speakerName, w / 2, h / 2 + 45);

      ctx.fillStyle = '#94A3B8';
      ctx.font = '15px Inter, sans-serif';
      ctx.fillText('SmartClass • Enregistrement en direct', w / 2, h / 2 + 75);
      ctx.textAlign = 'start';
    }
  }

  Future<LiveRecordingCaptureResult> stop() async {
    _isRecording = false;
    _renderTimer?.cancel();
    _renderTimer = null;

    try {
      if (_speechRecognition != null) {
        _speechRecognition!.callMethod('stop', const []);
        _speechRecognition = null;
      }
    } catch (_) {}

    try {
      if (_mediaRecorder != null && _mediaRecorder!.state != 'inactive') {
        final completer = Completer<void>();
        _mediaRecorder!.addEventListener('stop', (_) {
          if (!completer.isCompleted) completer.complete();
        });
        _mediaRecorder!.stop();
        await completer.future.timeout(
          const Duration(seconds: 4),
          onTimeout: () {},
        );
      }
    } catch (e) {
      debugPrint('[LiveSpeechRecorder] MediaRecorder stop error: $e');
    }

    // Stop and release all tracks
    for (final stream in _activeStreams) {
      for (final track in stream.getTracks()) {
        try {
          track.stop();
        } catch (_) {}
      }
    }
    _activeStreams.clear();

    if (_cameraVideo != null) {
      _cameraVideo!.srcObject = null;
      _cameraVideo!.remove();
      _cameraVideo = null;
    }
    if (_screenVideo != null) {
      _screenVideo!.srcObject = null;
      _screenVideo!.remove();
      _screenVideo = null;
    }
    _canvas = null;
    _ctx = null;

    String? mediaBase64;
    // Direct binary upload to backend
    if (_mediaChunks.isNotEmpty && _sessionId != null && _backendUrl != null) {
      try {
        final fullBlob = html.Blob(_mediaChunks, _recordedMimeType);
        debugPrint(
          '[LiveSpeechRecorder] Uploading recorded blob (${fullBlob.size} bytes) to backend...',
        );
        if (fullBlob.size > 500) {
          final uploadUrl =
              '$_backendUrl/api/v1/videoconference/sessions/$_sessionId/recording/media';
          final req = html.HttpRequest();
          req.open('POST', uploadUrl);
          if (_authToken != null && _authToken!.isNotEmpty) {
            req.setRequestHeader('Authorization', 'Bearer $_authToken');
          }
          req.setRequestHeader('Content-Type', _recordedMimeType);

          final completer = Completer<void>();
          req.onLoadEnd.listen((_) {
            debugPrint(
              '[LiveSpeechRecorder] Media upload finished with status ${req.status}',
            );
            if (!completer.isCompleted) completer.complete();
          });
          req.onError.listen((e) {
            debugPrint('[LiveSpeechRecorder] Media upload error: $e');
            if (!completer.isCompleted) completer.complete();
          });

          req.send(fullBlob);
          await completer.future.timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              debugPrint('[LiveSpeechRecorder] Media upload timed out after 45s');
            },
          );

          if (fullBlob.size <= 30 * 1024 * 1024) {
            mediaBase64 = await _blobToBase64(fullBlob);
          }
        }
      } catch (e) {
        debugPrint('[LiveSpeechRecorder] Blob direct upload failed: $e');
      }
    }

    _mediaRecorder = null;
    _mediaChunks.clear();

    final fullText = _segments.map((s) => s.text).join(' ').trim();
    return LiveRecordingCaptureResult(
      spokenTranscript: fullText,
      detectedLanguage: _detectedLang,
      capturedSegments: List<CapturedSpeechSegment>.from(_segments),
      mediaBase64: mediaBase64,
      mimeType: _recordedMimeType,
    );
  }

  Future<String?> _blobToBase64(html.Blob blob) async {
    final completer = Completer<String?>();
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is String) {
        final commaIdx = result.indexOf(',');
        completer.complete(
          commaIdx >= 0 ? result.substring(commaIdx + 1) : result,
        );
      } else if (result is List<int>) {
        completer.complete(base64Encode(result));
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    reader.readAsDataUrl(blob);
    return completer.future;
  }
}
