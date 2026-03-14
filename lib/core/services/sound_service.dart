import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service pour gérer les sons de notification (style Facebook)
class SoundService {
  static SoundService? _instance;
  final AudioPlayer _player = AudioPlayer();
  bool _hasAsset = false;
  bool _assetChecked = false;

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
      final hasLocal = await _checkAsset();
      if (hasLocal) {
        await _player.play(
          AssetSource('sounds/notification.mp3'),
          volume: 0.5,
        );
      } else {
        // Fallback: son de notification en ligne (court pop sound)
        await _player.play(
          UrlSource(
            'https://cdn.pixabay.com/audio/2024/11/27/audio_8dca6ab66a.mp3',
          ),
          volume: 0.5,
        );
      }
    } catch (e) {
      if (kDebugMode) print('🔊 [Sound] Error playing comment sound: $e');
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
