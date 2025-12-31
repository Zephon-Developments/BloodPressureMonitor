import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displaying information about the application and Zephon Developments.
///
/// Shows the Zephon branding, app version, license information, and links to
/// external resources such as the website and GitHub repository.
class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  String _appVersion = '';
  String _buildNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
        _buildNumber = 'Unknown';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot open this link'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open link: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Zephon Logo
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'Assets/ZephonDevelopmentsLogo.jpg',
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.business,
                          size: 120,
                          color: colorScheme.primary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    'HyperTrack',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Version Info
                  Text(
                    'Version $_appVersion (Build $_buildNumber)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Description Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About HyperTrack',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'A private, offline health data logger for tracking blood pressure, '
                            'medications, weight, and sleep. Your health data stays on your '
                            'device with optional encryption for maximum privacy.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Developer Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developed by Zephon Developments',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLinkTile(
                            context,
                            icon: Icons.language,
                            title: 'Website',
                            subtitle: 'zephondevelopments.com',
                            url: 'https://zephondevelopments.com',
                          ),
                          const Divider(),
                          _buildLinkTile(
                            context,
                            icon: Icons.code,
                            title: 'GitHub',
                            subtitle: 'View source code',
                            url: 'https://github.com/zephondevelopments',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // License Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'License',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This application is open source and available under the MIT License.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => _showLicenses(),
                            icon: const Icon(Icons.description),
                            label: const Text('View Open Source Licenses'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Copyright
                  Text(
                    '© 2025 Zephon Developments',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.open_in_new, color: colorScheme.onSurfaceVariant),
      onTap: () => _launchUrl(url),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'HyperTrack',
      applicationVersion: '$_appVersion (Build $_buildNumber)',
      applicationIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'Assets/ZephonDevelopmentsIcon.png',
          height: 48,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.health_and_safety, size: 48);
          },
        ),
      ),
      applicationLegalese: '© 2025 Zephon Developments',
    );
  }
}
