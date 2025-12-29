import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/views/home/widgets/quick_actions.dart';
import 'package:blood_pressure_monitor/views/home/widgets/recent_readings_card.dart';
import 'package:blood_pressure_monitor/views/settings/security_settings_view.dart';

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
        return _buildHistoryStub();
      case 2:
        return _buildChartsStub();
      case 3:
        return _buildSettingsStub();
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

  Widget _buildHistoryStub() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.5,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'History',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming in Phase 7',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsStub() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.5,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Charts & Analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming in Phase 8',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsStub() {
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
