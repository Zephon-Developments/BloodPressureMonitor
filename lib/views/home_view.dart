import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../viewmodels/blood_pressure_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BloodPressureViewModel(
        context.read<DatabaseService>(),
      )..loadReadings(),
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
                child: Text('No readings yet. Add your first reading!'),
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
                          'Recorded: ${DateFormat('yyyy-MM-dd HH:mm').format(reading.timestamp)}',
                        ),
                        if (reading.notes != null && reading.notes!.isNotEmpty)
                          Text('Notes: ${reading.notes}'),
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
              const SnackBar(
                content: Text('Add reading feature coming soon!'),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
