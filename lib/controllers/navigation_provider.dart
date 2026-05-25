import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_step.dart';

class NavigationProvider extends ChangeNotifier {
  String _destinationLabel = 'Chưa chọn điểm đến';
  String _etaText = '--:--';
  String _distanceText = '-';
  String _routeHint = 'Không có chỉ dẫn cho tuyến này';
  String? _searchError;
  bool _isSearching = false;
  double _heading = 0.0;
  double _bearingToDestination = 0.0;
  bool _isDrivingMode = false;
  bool _voiceEnabled = true;
  bool _isOffRoute = false;
  LatLng? _destinationLatLng;
  List<RouteStep> _currentSteps = const [];
  int _currentStepIndex = 0;
  DateTime? _lastStepAnnounceTime;
  DateTime? _lastOffRouteCheck;

  String get destinationLabel => _destinationLabel;
  String get etaText => _etaText;
  String get distanceText => _distanceText;
  String get routeHint => _routeHint;
  String? get searchError => _searchError;
  bool get isSearching => _isSearching;
  double get heading => _heading;
  double get bearingToDestination => _bearingToDestination;
  bool get isDrivingMode => _isDrivingMode;
  bool get voiceEnabled => _voiceEnabled;
  bool get isOffRoute => _isOffRoute;
  LatLng? get destinationLatLng => _destinationLatLng;
  List<RouteStep> get currentSteps => _currentSteps;
  int get currentStepIndex => _currentStepIndex;
  DateTime? get lastStepAnnounceTime => _lastStepAnnounceTime;
  DateTime? get lastOffRouteCheck => _lastOffRouteCheck;

  void setSearching(bool value) {
    if (_isSearching == value) return;
    _isSearching = value;
    notifyListeners();
  }

  void setSearchError(String? value) {
    if (_searchError == value) return;
    _searchError = value;
    notifyListeners();
  }

  void setDestinationLabel(String value) {
    if (_destinationLabel == value) return;
    _destinationLabel = value;
    notifyListeners();
  }

  void setDestinationLatLng(LatLng? value) {
    if (_destinationLatLng == value) return;
    _destinationLatLng = value;
    notifyListeners();
  }

  void setRouteSummary({
    required String etaText,
    required String distanceText,
    required String routeHint,
  }) {
    var changed = false;
    if (_etaText != etaText) {
      _etaText = etaText;
      changed = true;
    }
    if (_distanceText != distanceText) {
      _distanceText = distanceText;
      changed = true;
    }
    if (_routeHint != routeHint) {
      _routeHint = routeHint;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void setHeading(double value) {
    if (_heading == value) return;
    _heading = value;
    notifyListeners();
  }

  void setBearingToDestination(double value) {
    if (_bearingToDestination == value) return;
    _bearingToDestination = value;
    notifyListeners();
  }

  void setDrivingMode(bool value) {
    if (_isDrivingMode == value) return;
    _isDrivingMode = value;
    notifyListeners();
  }

  void setVoiceEnabled(bool value) {
    if (_voiceEnabled == value) return;
    _voiceEnabled = value;
    notifyListeners();
  }

  void setOffRoute(bool value) {
    if (_isOffRoute == value) return;
    _isOffRoute = value;
    notifyListeners();
  }

  void setSteps(List<RouteStep> steps) {
    _currentSteps = List<RouteStep>.unmodifiable(steps);
    _currentStepIndex = 0;
    _lastStepAnnounceTime = null;
    notifyListeners();
  }

  void setCurrentStepIndex(int value) {
    if (_currentStepIndex == value) return;
    _currentStepIndex = value;
    notifyListeners();
  }

  void setLastStepAnnounceTime(DateTime? value) {
    _lastStepAnnounceTime = value;
  }

  void setLastOffRouteCheck(DateTime? value) {
    _lastOffRouteCheck = value;
  }

  void resetNavigation() {
    _destinationLabel = 'Chưa chọn điểm đến';
    _etaText = '--:--';
    _distanceText = '-';
    _routeHint = 'Không có chỉ dẫn cho tuyến này';
    _searchError = null;
    _isSearching = false;
    _heading = 0.0;
    _bearingToDestination = 0.0;
    _isDrivingMode = false;
    _voiceEnabled = true;
    _isOffRoute = false;
    _destinationLatLng = null;
    _currentSteps = const [];
    _currentStepIndex = 0;
    _lastStepAnnounceTime = null;
    _lastOffRouteCheck = null;
    notifyListeners();
  }
}
