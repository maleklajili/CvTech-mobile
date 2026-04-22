import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays short notification/message sounds using programmatically generated
/// WAV data – no external asset files required.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _kNotifKey = 'sound_notifications';
  static const _kMsgKey = 'sound_messages';

  bool _notifEnabled = true;
  bool _msgEnabled = true;
  bool _loaded = false;

  bool get notifEnabled => _notifEnabled;
  bool get msgEnabled => _msgEnabled;

  /// Load persisted preferences once at startup.
  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    _notifEnabled = prefs.getBool(_kNotifKey) ?? true;
    _msgEnabled = prefs.getBool(_kMsgKey) ?? true;
  }

  Future<void> setNotifEnabled(bool value) async {
    _notifEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifKey, value);
  }

  Future<void> setMsgEnabled(bool value) async {
    _msgEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMsgKey, value);
  }

  /// Play incoming-message sound (single short beep, 180 ms).
  Future<void> playMessage() async {
    if (!_msgEnabled) return;
    await _play(_buildWav(660.0, 0.18));
  }

  /// Play notification sound (two ascending beeps).
  Future<void> playNotification() async {
    if (!_notifEnabled) return;
    await _play(_buildWav(880.0, 0.12));
    await Future.delayed(const Duration(milliseconds: 140));
    await _play(_buildWav(1040.0, 0.15));
  }

  /// Legacy alias kept so existing callers don't break.
  Future<void> playNotificationSound() => playNotification();
  Future<void> playCommentSound() => playNotification();

  Future<void> _play(Uint8List bytes) async {
    try {
      final player = AudioPlayer();
      await player.play(BytesSource(bytes));
      await Future.delayed(const Duration(milliseconds: 350));
      await player.dispose();
    } catch (_) {
      // Silently ignore audio errors (e.g. web policy restrictions).
    }
  }

  // ── Minimal WAV PCM generator ──────────────────────────────────────────
  /// Generates a mono 16-bit PCM WAV sine-wave tone with 10 ms fade envelope.
  static Uint8List _buildWav(
    double freqHz,
    double durationSec, {
    int sampleRate = 22050,
    double amplitude = 0.35,
  }) {
    final numSamples = (sampleRate * durationSec).toInt();
    final dataBytes = numSamples * 2;
    final bd = ByteData(44 + dataBytes);

    // RIFF header
    bd.setUint8(0, 0x52); bd.setUint8(1, 0x49);
    bd.setUint8(2, 0x46); bd.setUint8(3, 0x46);
    bd.setUint32(4, 36 + dataBytes, Endian.little);
    bd.setUint8(8, 0x57); bd.setUint8(9, 0x41);
    bd.setUint8(10, 0x56); bd.setUint8(11, 0x45);
    // fmt chunk
    bd.setUint8(12, 0x66); bd.setUint8(13, 0x6D);
    bd.setUint8(14, 0x74); bd.setUint8(15, 0x20);
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);        // PCM
    bd.setUint16(22, 1, Endian.little);        // mono
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    // data chunk
    bd.setUint8(36, 0x64); bd.setUint8(37, 0x61);
    bd.setUint8(38, 0x74); bd.setUint8(39, 0x61);
    bd.setUint32(40, dataBytes, Endian.little);

    const fadeSec = 0.010;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      double env = 1.0;
      if (t < fadeSec) env = t / fadeSec;
      if (t > durationSec - fadeSec) env = (durationSec - t) / fadeSec;
      final sample = sin(2 * pi * freqHz * t) * amplitude * env;
      final pcm = (sample * 32767).round().clamp(-32768, 32767);
      bd.setInt16(44 + i * 2, pcm, Endian.little);
    }
    return bd.buffer.asUint8List();
  }

  void dispose() {}
}

