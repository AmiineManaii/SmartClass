import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/videoconference_providers.dart';
import '../../domain/entities/session_event.dart';
import '../../domain/entities/session_phase.dart';
import '../../domain/entities/video_session.dart';
import '../widgets/session_phase_badge.dart';

class LobbyPage extends ConsumerStatefulWidget {
  final String sessionId;

  const LobbyPage({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends ConsumerState<LobbyPage> {
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _isLoading = false;
  bool _isCameraInitializing = false;
  String? _errorMessage;

  lk.LocalVideoTrack? _previewCameraTrack;

  @override
  void initState() {
    super.initState();
    _listenToSessionStarted();
    // Initialize preview camera if camera is initially enabled
    _initPreviewCamera();
  }

  @override
  void dispose() {
    _stopCameraPreview();
    super.dispose();
  }

  Future<void> _initPreviewCamera() async {
    if (!_cameraEnabled) return;
    setState(() => _isCameraInitializing = true);
    try {
      final track = await lk.LocalVideoTrack.createCameraTrack(
        const lk.CameraCaptureOptions(
          maxFrameRate: 30,
          params: lk.VideoParametersPresets.h720_169,
        ),
      );
      if (mounted && _cameraEnabled) {
        setState(() {
          _previewCameraTrack = track;
          _isCameraInitializing = false;
        });
      } else {
        await track.stop();
        await track.dispose();
      }
    } catch (e) {
      debugPrint('[LobbyPage] Failed to start preview camera: $e');
      if (mounted) {
        setState(() {
          _cameraEnabled = false;
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _stopCameraPreview() async {
    final track = _previewCameraTrack;
    _previewCameraTrack = null;
    if (track != null) {
      try {
        await track.stop();
        await track.dispose();
      } catch (_) {}
    }
  }

  Future<void> _toggleCamera() async {
    final next = !_cameraEnabled;
    setState(() => _cameraEnabled = next);

    if (next) {
      await _initPreviewCamera();
    } else {
      await _stopCameraPreview();
      if (mounted) setState(() {});
    }
  }

  Future<void> _flipCamera() async {
    final track = _previewCameraTrack;
    if (track == null) return;
    try {
      final opts = track.currentOptions;
      if (opts is lk.CameraCaptureOptions) {
        final newPos = opts.cameraPosition == lk.CameraPosition.front
            ? lk.CameraPosition.back
            : lk.CameraPosition.front;
        await track.restartTrack(opts.copyWith(cameraPosition: newPos));
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('[LobbyPage] Failed to flip camera: $e');
    }
  }

  void _listenToSessionStarted() {
    ref.listenManual<AsyncValue<SessionEvent>>(liveEventsStreamProvider, (_, next) {
      final event = next.valueOrNull;
      if (event == null || event.sessionId != widget.sessionId) return;
      if (event.type == 'session.started') {
        _enterRoom();
      }
    });
  }

  Future<void> _enterRoom() async {
    if (!mounted) return;
    // Release preview camera track before opening the meeting room
    await _stopCameraPreview();
    if (!mounted) return;

    context.pushReplacement(
      '/videoconference/${widget.sessionId}/room?mic=$_micEnabled&cam=$_cameraEnabled',
      extra: {
        'initialMic': _micEnabled,
        'initialCamera': _cameraEnabled,
      },
    );
  }

  Future<void> _handleStartSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final actions = ref.read(sessionActionsNotifierProvider.notifier);
      await actions.startSession(widget.sessionId);
      if (mounted) {
        _enterRoom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('ApiException: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(videoconferenceRepositoryProvider);
    final role = ref.watch(authStateProvider).valueOrNull?.role?.toLowerCase();
    final isTeacher = role == 'teacher' || role == 'admin';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                  : const Color(0xFFE2E8F0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Sas de prévisualisation',
          style: TextStyle(
            fontFamily: 'Inter',
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<VideoSession>(
        future: repo.getSession(widget.sessionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SmartLoader.medium(message: 'Préparation du sas...'),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Color(0xFFEF4444)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final session = snapshot.data!;
          final phase = phaseOf(session, DateTime.now());
          final isLive = session.status == VideoSessionStatus.inProgress;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Class badge + Phase badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (session.className != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                                  : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                                    : const Color(0xFFC7D2FE),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 13,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  session.className!,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        SessionPhaseBadge(phase: phase),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Session title
                    Text(
                      session.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (session.subject != null && session.subject!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        session.subject!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Camera/Mic Preview Box
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131B2E) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _cameraEnabled
                              ? const Color(0xFF10B981).withValues(alpha: 0.5)
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Video feed or Camera off placeholder
                          if (_cameraEnabled && _previewCameraTrack != null)
                            Positioned.fill(
                              child: lk.VideoTrackRenderer(
                                _previewCameraTrack!,
                                fit: lk.VideoViewFit.cover,
                              ),
                            )
                          else if (_cameraEnabled && _isCameraInitializing)
                            const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2.5),
                                  SizedBox(height: 12),
                                  Text(
                                    'Initialisation de la caméra...',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF475569)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.videocam_off_rounded,
                                      size: 32,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Caméra désactivée',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Activez la caméra pour prévisualiser votre image',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Top-right camera flip button (when camera is on)
                          if (_cameraEnabled && _previewCameraTrack != null)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Tooltip(
                                message: 'Changer de caméra',
                                child: InkWell(
                                  onTap: _flipCamera,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.flip_camera_ios_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Bottom Media Controls Overlay Pill
                          Positioned(
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.70),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Mic Toggle Button
                                  Tooltip(
                                    message: _micEnabled ? 'Couper le micro' : 'Activer le micro',
                                    child: InkWell(
                                      onTap: () => setState(() => _micEnabled = !_micEnabled),
                                      borderRadius: BorderRadius.circular(24),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _micEnabled
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_micEnabled
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFFEF4444))
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          _micEnabled
                                              ? Icons.mic_rounded
                                              : Icons.mic_off_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Camera Toggle Button
                                  Tooltip(
                                    message: _cameraEnabled ? 'Couper la caméra' : 'Activer la caméra',
                                    child: InkWell(
                                      onTap: _toggleCamera,
                                      borderRadius: BorderRadius.circular(24),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _cameraEnabled
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_cameraEnabled
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFFEF4444))
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          _cameraEnabled
                                              ? Icons.videocam_rounded
                                              : Icons.videocam_off_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Readiness status indicators card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131B2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _micEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _micEnabled ? 'Micro activé' : 'Micro coupé',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 20,
                            width: 1,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _cameraEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _cameraEnabled ? 'Caméra active' : 'Caméra coupée',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Helpful hint
                    Text(
                      '💡 Vous pourrez modifier vos paramètres audio et vidéo à tout moment pendant la séance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Action buttons depending on role and phase
                    if (isTeacher && !isLive) ...[
                      InkWell(
                        onTap: _isLoading ? null : _handleStartSession,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr('start_session'),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ] else if (isLive || isTeacher) ...[
                      InkWell(
                        onTap: _isLoading ? null : _enterRoom,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr('join_room'),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ] else ...[
                      // Student waiting for host
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131B2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                context.tr('waiting_for_host'),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
