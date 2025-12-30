import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/report_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';
// For date range selection if needed

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  final GlobalKey _chartKey = GlobalKey();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Report'),
      ),
      body: Consumer2<ReportViewModel, AnalyticsViewModel>(
        builder: (context, reportVm, analyticsVm, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Generate a comprehensive PDF report of your blood pressure readings, medications, and trends to share with your healthcare provider.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                _buildDateRangePicker(context),
                const SizedBox(height: 24),
                const Text(
                  'Report Preview (Charts)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                // We use a RepaintBoundary to capture the chart
                RepaintBoundary(
                  key: _chartKey,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Chart Preview Area\n(Will be captured for PDF)',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (reportVm.isGenerating)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton.icon(
                    onPressed: () => _generateReport(reportVm),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate & Share PDF Report'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                if (reportVm.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    reportVm.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (reportVm.lastReportPath != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Report generated successfully!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => reportVm.shareLastReport(),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Again'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date Range:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(
                      'From: ${_startDate.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(
                      'To: ${_endDate.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport(ReportViewModel reportVm) async {
    // Get active profile from ActiveProfileViewModel before async operations
    final activeProfile = context.read<ActiveProfileViewModel>();

    // 1. Capture the chart as an image
    Uint8List? chartImage;
    try {
      // Add null safety check for context
      final chartContext = _chartKey.currentContext;
      if (chartContext == null) {
        reportVm.clearError();
        // Set a user-friendly error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chart not ready. Please wait a moment and try again.',
            ),
          ),
        );
        return;
      }

      final boundary =
          chartContext.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to capture chart. Please try again.',
            ),
          ),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      chartImage = byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing chart: $e');
    }

    // 2. Generate the report
    await reportVm.generateReport(
      profileId: activeProfile.activeProfileId,
      profileName: activeProfile.activeProfileName,
      startDate: _startDate,
      endDate: _endDate,
      chartImages: chartImage != null ? [chartImage] : null,
    );

    // 3. Share automatically if successful
    if (reportVm.lastReportPath != null) {
      await reportVm.shareLastReport();
    }
  }
}
