import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/services/analytics_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';

/// Service for generating PDF doctor reports.
class PdfReportService {
  final AnalyticsService _analyticsService;
  final ReadingService _readingService;
  final MedicationService _medicationService;

  PdfReportService({
    required AnalyticsService analyticsService,
    required ReadingService readingService,
    required MedicationService medicationService,
  })  : _analyticsService = analyticsService,
        _readingService = readingService,
        _medicationService = medicationService;

  /// Generates a PDF report for a profile and date range.
  ///
  /// Parameters:
  /// - [profileId]: ID of the profile.
  /// - [profileName]: Name of the profile.
  /// - [startDate]: Start of the report range.
  /// - [endDate]: End of the report range.
  /// - [chartImages]: Optional list of pre-rendered chart images.
  Future<File> generateReport({
    required int profileId,
    required String profileName,
    required DateTime startDate,
    required DateTime endDate,
    List<Uint8List>? chartImages,
  }) async {
    final pdf = pw.Document();

    // Fetch data
    final stats = await _analyticsService.calculateStats(
      profileId: profileId,
      startDate: startDate,
      endDate: endDate,
    );

    final readings = await _readingService.getReadingsInTimeRange(
      profileId,
      startDate,
      endDate,
    );

    final medications = await _medicationService.listMedicationsByProfile(
      profileId,
      includeInactive: false,
    );

    // Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(profileName, startDate, endDate),
            pw.SizedBox(height: 20),
            _buildSummaryStats(stats),
            pw.SizedBox(height: 20),
            if (chartImages != null && chartImages.isNotEmpty)
              _buildCharts(chartImages),
            pw.SizedBox(height: 20),
            _buildMedications(medications),
            pw.SizedBox(height: 20),
            _buildReadingsTable(readings),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final filename = 'bp_report_${profileName.replaceAll(' ', '_')}_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(String name, DateTime start, DateTime end) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'HyperTrack - Doctor Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Patient: $name'),
        pw.Text(
          'Period: ${DateFormats.dateOnly.format(start.toLocal())} to '
          '${DateFormats.dateOnly.format(end.toLocal())}',
        ),
        pw.Text(
          'Generated: ${DateFormats.standardDateTime.format(DateTime.now().toLocal())}',
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSummaryStats(HealthStats stats) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary Statistics',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem('Avg Systolic', '${stats.avgSystolic.round()} mmHg'),
            _buildStatItem(
              'Avg Diastolic',
              '${stats.avgDiastolic.round()} mmHg',
            ),
            _buildStatItem('Avg Pulse', '${stats.avgPulse.round()} bpm'),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              'Min BP',
              '${stats.minSystolic}/${stats.minDiastolic}',
            ),
            _buildStatItem(
              'Max BP',
              '${stats.maxSystolic}/${stats.maxDiastolic}',
            ),
            _buildStatItem('Total Readings', '${stats.totalReadings}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildCharts(List<Uint8List> images) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Trends',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        for (final img in images)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Image(pw.MemoryImage(img), height: 200),
          ),
      ],
    );
  }

  pw.Widget _buildMedications(List<Medication> medications) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Current Medications',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        if (medications.isEmpty)
          pw.Text('No active medications recorded.')
        else
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Dosage', 'Frequency'],
            data: medications
                .map((m) => [m.name, m.dosage ?? '-', m.frequency ?? '-'])
                .toList(),
          ),
      ],
    );
  }

  pw.Widget _buildReadingsTable(List<Reading> readings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Readings',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Date/Time', 'BP (mmHg)', 'Pulse', 'Notes'],
          data: readings.take(50).map((r) {
            return [
              r.takenAt.toLocal().toString().split('.')[0],
              '${r.systolic}/${r.diastolic}',
              '${r.pulse}',
              r.note ?? '',
            ];
          }).toList(),
        ),
        if (readings.length > 50)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: pw.Text('... showing first 50 readings only'),
          ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'DISCLAIMER: This report is for informational purposes only and does not constitute medical advice. '
          'Please consult with a healthcare professional for diagnosis and treatment.',
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Shares a file using the platform share sheet.
  Future<void> shareReport(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Blood Pressure Report');
  }
}
