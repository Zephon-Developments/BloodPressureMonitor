import 'package:flutter/foundation.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';

class BloodPressureViewModel extends ChangeNotifier {
  final ReadingService _readingService;
  final int _profileId;
  List<Reading> _readings = [];
  bool _isLoading = false;
  String? _error;

  BloodPressureViewModel(this._readingService, {int profileId = 1})
      : _profileId = profileId;

  List<Reading> get readings => _readings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReadings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _readings = await _readingService.getReadingsByProfile(_profileId);
    } catch (e) {
      _error = 'Failed to load readings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReading(Reading reading) async {
    try {
      await _readingService.createReading(reading);
      await loadReadings();
    } catch (e) {
      _error = 'Failed to add reading: $e';
      notifyListeners();
    }
  }

  Future<void> updateReading(Reading reading) async {
    try {
      await _readingService.updateReading(reading);
      await loadReadings();
    } catch (e) {
      _error = 'Failed to update reading: $e';
      notifyListeners();
    }
  }

  Future<void> deleteReading(int id) async {
    try {
      await _readingService.deleteReading(id);
      await loadReadings();
    } catch (e) {
      _error = 'Failed to delete reading: $e';
      notifyListeners();
    }
  }
}
