import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  bool _voiceEnabled = true;
  bool _darkMode = true;

  bool get voiceEnabled => _voiceEnabled;
  bool get darkMode => _darkMode;

  void toggleVoice(bool value) {
    _voiceEnabled = value;
    notifyListeners();
  }

  void toggleTheme(bool value) {
    _darkMode = value;
    notifyListeners();
  }
}
