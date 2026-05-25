import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  bool _voiceEnabled = true;
  bool _darkMode = true;
  bool _isEnglish = false;

  bool get voiceEnabled => _voiceEnabled;
  bool get darkMode => _darkMode;
  bool get isEnglish => _isEnglish;

  void toggleVoice(bool value) {
    _voiceEnabled = value;
    notifyListeners();
  }

  void toggleTheme(bool value) {
    _darkMode = value;
    notifyListeners();
  }

  void toggleLanguage(bool value) {
    _isEnglish = value;
    notifyListeners();
  }
}

