// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'dart:html' as html;

/// Web recording playback: the authenticated bytes downloaded by the page are
/// wrapped in a local Blob URL; nothing is exposed publicly.
class ExamRecordingSurface extends StatefulWidget {
  const ExamRecordingSurface({
    required this.bytes,
    required this.mimeType,
    super.key,
  });

  final Uint8List bytes;
  final String mimeType;

  static bool get supported => true;

  @override
  State<ExamRecordingSurface> createState() => _ExamRecordingSurfaceState();
}

class _ExamRecordingSurfaceState extends State<ExamRecordingSurface> {
  static int _viewCounter = 0;

  late final String _viewType;
  late final String _url;
  html.VideoElement? _video;

  @override
  void initState() {
    super.initState();
    _viewType = 'smartclass-exam-recording-${_viewCounter++}';
    final blob = html.Blob(<Object>[widget.bytes], widget.mimeType);
    _url = html.Url.createObjectUrlFromBlob(blob);
    final video = html.VideoElement()
      ..src = _url
      ..controls = true
      ..autoplay = false
      ..preload = 'metadata'
      ..style.width = '100%'
      ..style.borderRadius = '12px'
      ..style.backgroundColor = '#000000';
    _video = video;
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => video,
    );
  }

  @override
  void dispose() {
    try {
      _video?.pause();
      _video?.src = '';
    } catch (_) {}
    html.Url.revokeObjectUrl(_url);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
