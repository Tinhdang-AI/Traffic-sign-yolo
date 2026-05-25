import 'package:flutter/services.dart';

class TtsSettingsHelper {
  static const MethodChannel _channel = MethodChannel('traffic_detect/tts');

  /// Opens the platform TTS settings page (Android). Returns true on success.
  static Future<bool> openTtsSettings() async {
    try {
      final res = await _channel.invokeMethod('openTtsSettings');
      return res == true;
    } on PlatformException catch (e) {
      print('TTS Settings open failed: ${e.message}');
      return false;
    }
  }
}
