import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceGuidanceService {
  static final VoiceGuidanceService _instance =
      VoiceGuidanceService._internal();
  static const MethodChannel _channel = MethodChannel('traffic_detect/tts');

  factory VoiceGuidanceService() {
    return _instance;
  }

  VoiceGuidanceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  double _volumeLevel = 0.8;
  bool _isSpeaking = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('🎤 [TTS] Initializing Voice Guidance...');

      // Wait for completion before returning from speak()
      await _tts.awaitSpeakCompletion(true);

      if (Platform.isAndroid) {
        await _tts.setAudioAttributesForNavigation();
      }

      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
      }

      // Note: newer flutter_tts versions may not expose setCompletionHandler/setErrorHandler
      // We rely on `awaitSpeakCompletion(true)` and awaiting `speak()` calls to know when
      // speaking has finished and to reset `_isSpeaking`.

      // Try Vietnamese first, then a fallback locale, then keep the engine default.
      final languageCandidates = <String>['vi-VN', 'vi', 'en-US'];
      for (final language in languageCandidates) {
        try {
          final isAvailable = await _tts.isLanguageAvailable(language);
          if (isAvailable == true) {
            await _tts.setLanguage(language);
            print('🎤 [TTS] language set successfully: $language');
            break;
          }
        } catch (e) {
          print('🎤 [TTS] language check failed for $language: $e');
        }
      }

      // Set pitch and rate for better clarity
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.8);

      // Set volume
      await _tts.setVolume(_volumeLevel);

      _isInitialized = true;
      print('🎤 [TTS] Initialization complete');
    } catch (e) {
      print('🎤 [TTS] Error initializing TTS: $e');
    }
  }

  /// Check if a language is available on the device TTS engine
  Future<bool> isLanguageAvailable(String lang) async {
    try {
      return await _tts.isLanguageAvailable(lang) == true;
    } catch (e) {
      print('🎤 [TTS] Error checking language availability: $e');
      return false;
    }
  }

  /// Return list of installed TTS engines (platform dependent)
  Future<List<dynamic>> getInstalledEngines() async {
    try {
      final engines = await _tts.getEngines;
      return engines ?? <dynamic>[];
    } catch (e) {
      print('🎤 [TTS] Error getting engines: $e');
      return <dynamic>[];
    }
  }

  bool get isInitialized => _isInitialized;

  /// Announce a turn instruction
  Future<void> speakInstruction(String instruction) async {
    if (!_isInitialized) await init();

    if (_isSpeaking) {
      await _tts.stop();
    }

    try {
      _isSpeaking = true;
      await _tts.speak(instruction, focus: Platform.isAndroid);
      _isSpeaking = false;
    } catch (e) {
      print('Error speaking: $e');
      _isSpeaking = false;
    }
  }

  /// Announce ETA information
  Future<void> speakETA(String eta, String distance) async {
    if (!_isInitialized) await init();

    if (_isSpeaking) {
      await _tts.stop();
    }

    try {
      final message = 'Còn $distance, khoảng $eta';
      _isSpeaking = true;
      await _tts.speak(message, focus: Platform.isAndroid);
      _isSpeaking = false;
    } catch (e) {
      print('Error speaking ETA: $e');
      _isSpeaking = false;
    }
  }

  /// Announce arrival at destination
  Future<void> speakArrival() async {
    if (!_isInitialized) await init();

    if (_isSpeaking) {
      await _tts.stop();
    }

    try {
      _isSpeaking = true;
      await _tts.speak('Bạn đã đến điểm đích', focus: Platform.isAndroid);
      _isSpeaking = false;
    } catch (e) {
      print('Error speaking arrival: $e');
      _isSpeaking = false;
    }
  }

  /// Announce off-route
  Future<void> speakOffRoute() async {
    if (!_isInitialized) await init();

    if (_isSpeaking) {
      await _tts.stop();
    }

    try {
      _isSpeaking = true;
      await _tts.speak(
        'Bạn đã rời khỏi tuyến đường. Đang tính toán lại...',
        focus: Platform.isAndroid,
      );
      _isSpeaking = false;
    } catch (e) {
      print('Error speaking off-route: $e');
      _isSpeaking = false;
    }
  }

  /// Announce traffic sign warning
  Future<void> speakTrafficSign(String signLabel) async {
    if (!_isInitialized) await init();

    print('🎤 [TTS] Request to speak: $signLabel');

    if (_isSpeaking) {
      await _tts.stop();
    }

    try {
      _isSpeaking = true;
      print('🎤 [TTS] Speaking: Chú ý biển báo: $signLabel');
      await _tts.speak('Chú ý biển báo: $signLabel', focus: Platform.isAndroid);
      _isSpeaking = false;
    } catch (e) {
      print('🎤 [TTS] Error speaking traffic sign: $e');
      _isSpeaking = false;
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  /// Set volume level (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volumeLevel = volume.clamp(0.0, 1.0);
    if (_isInitialized) {
      await _tts.setVolume(_volumeLevel);
    }
  }

  /// Open platform TTS settings page. Returns true on success.
  Future<bool> openPlatformSettings() async {
    try {
      final res = await _channel.invokeMethod('openTtsSettings');
      return res == true;
    } on PlatformException catch (e) {
      print('TTS Settings open failed: ${e.message}');
      return false;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (e) {
      print('Error disposing TTS: $e');
    }
  }

  bool get isSpeaking => _isSpeaking;
}
