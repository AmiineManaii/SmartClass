import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service responsible for playing instant, audible chime sounds and haptics
/// for classroom interactions like raising a hand / waving.
class SoundEffectService {
  static final SoundEffectService instance = SoundEffectService._();
  SoundEffectService._();

  AudioPlayer? _player;
  static const MethodChannel _platformChannel =
      MethodChannel('com.smartclass.smartclass/alert');

  AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Plays a crisp, audible chime whenever a user clicks the hand raise icon
  /// or when any attendee raises their hand.
  Future<void> playHandRaiseSound() async {
    // 1. Haptic feedback for physical feel
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    // 2. Built-in system sound
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    // 3. Native Android Ringtone / ToneGenerator fallback
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _platformChannel.invokeMethod('playAlertChime');
      } catch (_) {}
    }

    // 4. Audioplayers high-definition chime playback
    try {
      final player = _audioPlayer;
      await player.stop();
      await player.setVolume(1.0);
      await player.play(AssetSource('sounds/hand_raise_chime.wav'));
    } catch (e) {
      debugPrint('[SoundEffectService] Error playing alert sound: $e');
    }
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
