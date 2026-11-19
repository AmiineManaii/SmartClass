// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import '../../../../core/network/api_config.dart';
import '../../domain/entities/exam_monitoring.dart';
import 'exam_guard_types.dart';

/// Web guard built on real browser events.
///
/// What it actually does:
/// - measures `visibilitychange` / `blur` durations and reports them;
/// - blocks copy, paste, cut, context menu, text selection and the usual
///   keyboard shortcuts as far as a browser allows;
/// - reports PrintScreen presses and online/offline transitions;
/// - leaves through `navigator.sendBeacon` on `pagehide`/`beforeunload`.
///
/// It cannot block OS or browser screenshots. No such claim is made.
class WebExamGuard implements ExamGuard {
  static const _selectionStyleId = 'smartclass-exam-no-select';
  static const _occlusionOverlayId = 'smartclass-exam-occlusion-overlay';

  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];
  html.Element? _styleElement;
  html.Element? _overlayElement;
  void Function(ExamGuardSignal signal)? _onSignal;
  String? _examId;
  DateTime? _hiddenAt;
  DateTime? _blurredAt;
  bool _fullscreenRequested = false;

  void _showOcclusionOverlay() {
    if (_overlayElement != null) return;
    final overlay = html.DivElement()
      ..id = _occlusionOverlayId
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100vw'
      ..style.height = '100vh'
      ..style.backgroundColor = '#0b1120'
      ..style.color = '#ffffff'
      ..style.zIndex = '9999999'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.fontFamily = 'sans-serif'
      ..style.userSelect = 'none';

    final card = html.DivElement()
      ..style.textAlign = 'center'
      ..style.maxWidth = '500px'
      ..style.padding = '24px'
      ..style.borderRadius = '16px'
      ..style.background = 'rgba(15, 23, 42, 0.95)'
      ..style.border = '1px solid rgba(239, 68, 68, 0.4)';

    final emoji = html.DivElement()
      ..style.fontSize = '48px'
      ..style.marginBottom = '16px'
      ..text = '⚠️';

    final title = html.HeadingElement.h2()
      ..style.fontSize = '20px'
      ..style.fontWeight = 'bold'
      ..style.marginBottom = '8px'
      ..style.color = '#ef4444'
      ..text = "Fenêtre d'Examen Inactive / Capture Détectée";

    final desc = html.ParagraphElement()
      ..style.fontSize = '14px'
      ..style.color = '#94a3b8'
      ..style.lineHeight = '1.5'
      ..text =
          "Le contenu de l'épreuve est masqué par sécurité. Cliquez à l'intérieur de cette fenêtre pour reprendre votre examen.";

    card
      ..append(emoji)
      ..append(title)
      ..append(desc);
    overlay.append(card);
    html.document.body?.append(overlay);
    _overlayElement = overlay;
    html.document.body?.append(overlay);
    _overlayElement = overlay;
  }

  Timer? _overlayAutoHideTimer;

  void _hideOcclusionOverlay() {
    _overlayAutoHideTimer?.cancel();
    _overlayAutoHideTimer = null;
    _overlayElement?.remove();
    _overlayElement = null;
  }

  @override
  Future<void> start({
    required String examId,
    required void Function(ExamGuardSignal signal) onSignal,
  }) async {
    await stop();
    _onSignal = onSignal;
    _examId = examId;
    _fullscreenRequested = false;
    _installSelectionBlocker();
    _listenVisibility();
    _listenFocus();
    _listenClipboard();
    _listenKeyboard();
    _listenNetwork();
    _listenFullscreen();
    _listenUnload();
  }

  @override
  Future<void> stop() async {
    _hideOcclusionOverlay();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _styleElement?.remove();
    _styleElement = null;
    _onSignal = null;
    _examId = null;
    _hiddenAt = null;
    _blurredAt = null;
    _fullscreenRequested = false;
  }

  @override
  Future<bool> enterFullscreen() async {
    final root = html.document.documentElement;
    if (root == null) return false;
    try {
      await root.requestFullscreen();
      _fullscreenRequested = true;
      return html.document.fullscreenElement != null;
    } catch (_) {
      return false;
    }
  }

  void _installSelectionBlocker() {
    final style = html.StyleElement()
      ..id = _selectionStyleId
      ..text =
          '* { -webkit-user-select: none !important; user-select: none !important; '
          '-webkit-touch-callout: none !important; }';
    html.document.head?.append(style);
    _styleElement = style;
  }

  void _listenVisibility() {
    _subscriptions.add(
      html.document.onVisibilityChange.listen((_) {
        if (html.document.hidden == true) {
          _hiddenAt ??= DateTime.now();
          _showOcclusionOverlay();
          return;
        }
        _hideOcclusionOverlay();
        final startedAt = _hiddenAt;
        _hiddenAt = null;
        if (startedAt == null) return;
        _emit(
          ExamGuardSignal(
            type: ExamEventType.tabHidden,
            durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          ),
        );
      }),
    );
  }

  void _listenFocus() {
    _subscriptions.add(
      html.window.onBlur.listen((_) {
        _blurredAt ??= DateTime.now();
        _showOcclusionOverlay();
      }),
    );
    _subscriptions.add(
      html.window.onFocus.listen((_) {
        _hideOcclusionOverlay();
        final startedAt = _blurredAt;
        _blurredAt = null;
        if (startedAt == null) return;
        _emit(
          ExamGuardSignal(
            type: ExamEventType.focusLost,
            durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          ),
        );
      }),
    );
  }

  void _listenClipboard() {
    _subscriptions.add(
      html.document.onCopy.listen((event) {
        event.preventDefault();
        _emit(const ExamGuardSignal(type: ExamEventType.copyAttempt));
      }),
    );
    _subscriptions.add(
      html.document.onPaste.listen((event) {
        event.preventDefault();
        _emit(const ExamGuardSignal(type: ExamEventType.pasteAttempt));
      }),
    );
    _subscriptions.add(
      html.document.onCut.listen((event) {
        event.preventDefault();
        _emit(const ExamGuardSignal(type: ExamEventType.cutAttempt));
      }),
    );
    _subscriptions.add(
      html.document.onContextMenu.listen((event) {
        event.preventDefault();
        _emit(const ExamGuardSignal(type: ExamEventType.contextMenu));
      }),
    );
    _subscriptions.add(
      html.document.onSelectStart.listen((event) {
        event.preventDefault();
      }),
    );
  }

  void _listenKeyboard() {
    _subscriptions.add(
      html.document.onKeyDown.listen((event) {
        final key = event.key?.toLowerCase() ?? '';
        final isPrintScreen = key == 'printscreen' ||
            key == 'snapshot' ||
            event.keyCode == 44;
        final isWinShiftS =
            (event.shiftKey == true || event.metaKey == true) && key == 's';

        if (isPrintScreen || isWinShiftS) {
          _showOcclusionOverlay();
          _overlayAutoHideTimer?.cancel();
          _overlayAutoHideTimer = Timer(const Duration(seconds: 2), () {
            if (html.document.hidden != true) _hideOcclusionOverlay();
          });
          _emit(const ExamGuardSignal(type: ExamEventType.screenshotAttempt));
          return;
        }
        final modifier = event.ctrlKey == true || event.metaKey == true;
        if (!modifier) return;
        if (key == 'a' || key == 's' || key == 'p' || key == 'u') {
          event.preventDefault();
        }
      }),
    );
    _subscriptions.add(
      html.document.onKeyUp.listen((event) {
        final key = event.key?.toLowerCase() ?? '';
        if (key == 'printscreen' || key == 'snapshot' || event.keyCode == 44) {
          _showOcclusionOverlay();
          _overlayAutoHideTimer?.cancel();
          _overlayAutoHideTimer = Timer(const Duration(seconds: 2), () {
            if (html.document.hidden != true) _hideOcclusionOverlay();
          });
        }
      }),
    );
  }

  void _listenNetwork() {
    _subscriptions.add(
      html.window.onOffline.listen(
        (_) => _emit(const ExamGuardSignal(type: ExamEventType.networkLost)),
      ),
    );
    _subscriptions.add(
      html.window.onOnline.listen(
        (_) => _emit(const ExamGuardSignal(type: ExamEventType.networkRestored)),
      ),
    );
  }

  void _listenFullscreen() {
    _subscriptions.add(
      html.document.onFullscreenChange.listen((_) {
        if (!_fullscreenRequested) return;
        if (html.document.fullscreenElement != null) return;
        _fullscreenRequested = false;
        _emit(const ExamGuardSignal(type: ExamEventType.fullscreenExit));
      }),
    );
  }

  void _listenUnload() {
    _subscriptions.add(
      html.window.onPageHide.listen((_) {
        _sendBeacon(ExamEventType.pageLeave);
      }),
    );
    _subscriptions.add(
      html.window.onBeforeUnload.listen((_) {
        _sendBeacon(ExamEventType.pageRefresh);
      }),
    );
  }

  void _emit(ExamGuardSignal signal) {
    _onSignal?.call(signal);
  }

  /// The page is unloading: only a beacon can still reach the backend.
  /// The access token is read synchronously from LocalStorage so no async
  /// work is needed while the document is being destroyed.
  void _sendBeacon(ExamEventType type) {
    final examId = _examId;
    if (examId == null) return;
    try {
      final token = _readToken();
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/exams/$examId/attempt/events',
      ).replace(queryParameters: token == null ? null : {'token': token});
      final body = jsonEncode(<String, dynamic>{
        'type': type.wire,
        'source': 'web',
        'clientOccurredAt': DateTime.now().toUtc().toIso8601String(),
      });
      final blob = html.Blob(<Object>[body], 'application/json');
      html.window.navigator.sendBeacon(url.toString(), blob);
    } catch (_) {
      // Best effort only: the event is not fabricated locally, and if the
      // beacon cannot be delivered it is simply not recorded.
    }
  }

  String? _readToken() {
    final storage = html.window.localStorage;
    final candidates = <String>[
      'flutter.${ApiConfig.accessTokenKey}',
      ApiConfig.accessTokenKey,
    ];
    for (final key in candidates) {
      final value = storage[key];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}

ExamGuard createExamGuard() => WebExamGuard();
