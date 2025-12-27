import 'package:flutter/foundation.dart';
import '../models/blood_pressure_reading.dart';
import '../services/database_service.dart';

class BloodPressureViewModel extends ChangeNotifier {
  final DatabaseService _databaseService;
  List<BloodPressureReading> _readings = [];
  bool _isLoading = false;
  String? _error;

  BloodPressureViewModel(this._databaseService);

  List<BloodPressureReading> get readings => _readings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReadings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _readings = await _databaseService.getAllReadings();
    } catch (e) {
      _error = 'Failed to load readings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReading(BloodPressureReading reading) async {
    try {
      await _databaseService.insertReading(reading);
      await loadReadings();
    } catch (e) {
      _error = 'Failed to add reading: $e';
      notifyListeners();
    }
  }

  Future<void> updateReading(BloodPressureReading reading) async {
    try {
      await _databaseService.updateReading(reading);
      await loadReadings();
    } catch (e) {
      _error = 'Failed to update reading: $e';
      notifyListeners();
    }
  }

  Future<void> deleteReading(int id) async {
    try {
      await _databaseService.deleteReading(id);
      await loadReadings();
    } catch (e) {
      _error = 'Failed to delete reading: $e';
      notifyListeners();
    }
  }
}
