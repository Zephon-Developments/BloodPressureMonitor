import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:blood_pressure_monitor/services/pdf_report_service.dart';

/// ViewModel for managing PDF report generation and sharing.
class ReportViewModel extends ChangeNotifier {
  final PdfReportService _pdfReportService;

  ReportViewModel({required PdfReportService pdfReportService})
      : _pdfReportService = pdfReportService;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _lastReportPath;
  String? get lastReportPath => _lastReportPath;

  String? _error;
  String? get error => _error;

  /// Generates a PDF report.
  Future<void> generateReport({
    required int profileId,
    required String profileName,
    required DateTime startDate,
    required DateTime endDate,
    List<Uint8List>? chartImages,
  }) async {
    _setGenerating(true);
    _error = null;
    try {
      final file = await _pdfReportService.generateReport(
        profileId: profileId,
        profileName: profileName,
        startDate: startDate,
        endDate: endDate,
        chartImages: chartImages,
      );
      _lastReportPath = file.path;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setGenerating(false);
    }
  }

  /// Shares the last generated report.
  Future<void> shareLastReport() async {
    if (_lastReportPath == null) return;
    try {
      await _pdfReportService.shareReport(File(_lastReportPath!));
    } catch (e) {
      _error = 'Failed to share report: $e';
      notifyListeners();
    }
  }

  void _setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
