import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service pour gérer les sons de notification (style Facebook)
class SoundService {
  static SoundService? _instance;
  final AudioPlayer _player = AudioPlayer();
  bool _hasAsset = false;
  bool _assetChecked = false;
  bool _playerConfigured = false;

  SoundService._internal();

  static SoundService get instance {
    _instance ??= SoundService._internal();
    return _instance!;
  }

  /// Vérifier si l'asset son existe
  Future<bool> _checkAsset() async {
    if (_assetChecked) return _hasAsset;
    try {
      await rootBundle.load('assets/sounds/notification.mp3');
      _hasAsset = true;
    } catch (_) {
      _hasAsset = false;
    }
    _assetChecked = true;
    return _hasAsset;
  }

  /// Jouer le son de notification pour un nouveau commentaire
  Future<void> playCommentSound() async {
    try {
      if (!_playerConfigured) {
        await _player.setReleaseMode(ReleaseMode.stop);
        _playerConfigured = true;
      }

      final hasLocal = await _checkAsset();
      if (hasLocal) {
        await _player.play(
          AssetSource('sounds/notification.mp3'),
          volume: 0.5,
        );
      } else {
        // Fallback fiable sur Android/iOS quand l'asset n'existe pas.
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      if (kDebugMode) print('🔊 [Sound] Error playing comment sound: $e');
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {
        // Ignore fallback errors.
      }
    }
  }

  /// Jouer le son de notification générique
  Future<void> playNotificationSound() async {
    await playCommentSound();
  }

  void dispose() {
    _player.dispose();
    _instance = null;
  }
}
