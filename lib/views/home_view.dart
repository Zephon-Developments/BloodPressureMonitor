import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/views/analytics/analytics_view.dart';
import 'package:blood_pressure_monitor/views/history/history_view.dart';
import 'package:blood_pressure_monitor/views/home/widgets/quick_actions.dart';
import 'package:blood_pressure_monitor/views/home/widgets/recent_readings_card.dart';
import 'package:blood_pressure_monitor/views/settings/security_settings_view.dart';
import 'package:blood_pressure_monitor/views/export_view.dart';
import 'package:blood_pressure_monitor/views/import_view.dart';
import 'package:blood_pressure_monitor/views/report_view.dart';
import 'package:blood_pressure_monitor/views/file_manager_view.dart';
import 'package:blood_pressure_monitor/views/medication/medication_list_view.dart';
import 'package:blood_pressure_monitor/views/medication/medication_history_view.dart';

/// Main home screen with navigation shell.
///
/// Provides bottom navigation to Home, History (stub), Charts (stub),
/// and Settings. Displays recent readings and quick actions.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Trigger initial load after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BloodPressureViewModel>().loadReadings();
    });
  }

  void _onNavigationTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_selectedIndex == 2)
            Consumer<AnalyticsViewModel>(
              builder: (context, viewModel, _) => IconButton(
                icon: Icon(
                  viewModel.showSleepOverlay
                      ? Icons.bedtime
                      : Icons.bedtime_outlined,
                ),
                tooltip: 'Sleep overlay',
                onPressed: () => viewModel.toggleSleepOverlay(),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: 'Security Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SecuritySettingsView(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigationTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Charts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Blood Pressure Monitor';
      case 1:
        return 'History';
      case 2:
        return 'Charts';
      case 3:
        return 'Settings';
      default:
        return 'Blood Pressure Monitor';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return const AnalyticsView();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          QuickActions(),
          SizedBox(height: 16),
          RecentReadingsCard(),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() => const HistoryView();

  Widget _buildSettingsTab() {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Security Settings'),
          subtitle: const Text('PIN, biometrics, and auto-lock'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const SecuritySettingsView(),
              ),
            );
          },
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Health Data',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.medication),
          title: const Text('Medications'),
          subtitle: const Text('Manage your medications'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const MedicationListView(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Intake History'),
          subtitle: const Text('View medication intake records'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const MedicationHistoryView(),
              ),
            );
          },
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Data & Reports',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: const Text('Doctor Report'),
          subtitle: const Text('Generate PDF report for your doctor'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ReportView(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.upload),
          title: const Text('Export Data'),
          subtitle: const Text('Backup your data to JSON or CSV'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ExportView(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Import Data'),
          subtitle: const Text('Restore data from a backup file'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ImportView(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: const Text('File Manager'),
          subtitle: const Text('Manage exports and reports'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const FileManagerView(),
              ),
            );
          },
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Reminders'),
          subtitle: Text('Coming soon'),
          enabled: false,
        ),
        const ListTile(
          leading: Icon(Icons.palette),
          title: Text('Appearance'),
          subtitle: Text('Coming soon'),
          enabled: false,
        ),
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('About'),
          subtitle: Text('Coming soon'),
          enabled: false,
        ),
      ],
    );
  }
}
