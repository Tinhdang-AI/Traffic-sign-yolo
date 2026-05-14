import 'package:flutter_tts/flutter_tts.dart';

class VoiceGuidanceService {
  static final VoiceGuidanceService _instance =
      VoiceGuidanceService._internal();

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
      // Set language to Vietnamese
      await _tts.setLanguage('vi-VN');

      // Set pitch and rate for better clarity
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.8);

      // Set volume
      await _tts.setVolume(_volumeLevel);

      _isInitialized = true;
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  /// Announce a turn instruction
  Future<void> speakInstruction(String instruction) async {
    if (!_isInitialized) await init();

    if (_isSpeaking) {
      await _tts.stop();
    }

    try {
      _isSpeaking = true;
      await _tts.speak(instruction);
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
      await _tts.speak(message);
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
      await _tts.speak('Bạn đã đến điểm đích');
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
      await _tts.speak('Bạn đã rời khỏi tuyến đường. Đang tính toán lại...');
    } catch (e) {
      print('Error speaking off-route: $e');
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
