import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          BloodPressureViewModel(context.read<ReadingService>())
            ..loadReadings(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blood Pressure Monitor'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Consumer<BloodPressureViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Text(
                  viewModel.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (viewModel.readings.isEmpty) {
              return const Center(
                child: Text(
                    'No readings yet Louise. But we will add readings soon!'),
              );
            }

            return ListView.builder(
              itemCount: viewModel.readings.length,
              itemBuilder: (context, index) {
                final reading = viewModel.readings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: Text(
                      '${reading.systolic}/${reading.diastolic}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pulse: ${reading.pulse} bpm'),
                        Text(
                          'Recorded: ${DateFormats.standardDateTime.format(reading.takenAt)}',
                        ),
                        if (reading.note != null && reading.note!.isNotEmpty)
                          Text('Notes: ${reading.note}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to add reading screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add reading feature coming soon!')),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
