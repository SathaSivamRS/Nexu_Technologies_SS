import 'package:flutter/foundation.dart';

class ClockService extends ChangeNotifier {
  DateTime? _simulatedBaseTime;
  DateTime? _simulatedSetAtRealTime;

  ClockService({DateTime? initialSimulatedTime}) {
    if (initialSimulatedTime != null) {
      setSimulatedTime(initialSimulatedTime);
    }
  }

  bool get isSimulated => _simulatedBaseTime != null;

  DateTime? get simulatedBaseTime => _simulatedBaseTime;

  DateTime now() {
    if (_simulatedBaseTime != null && _simulatedSetAtRealTime != null) {
      final elapsed = DateTime.now().difference(_simulatedSetAtRealTime!);
      return _simulatedBaseTime!.add(elapsed);
    }
    return DateTime.now();
  }

  void setSimulatedTime(DateTime time) {
    _simulatedBaseTime = time;
    _simulatedSetAtRealTime = DateTime.now();
    notifyListeners();
  }

  void resetToActualTime() {
    _simulatedBaseTime = null;
    _simulatedSetAtRealTime = null;
    notifyListeners();
  }
}
