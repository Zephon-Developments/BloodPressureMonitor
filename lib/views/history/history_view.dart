import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/history.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/viewmodels/history_viewmodel.dart';
import 'package:blood_pressure_monitor/views/history/history_widgets.dart';
import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';

typedef DateRangePickerBuilder = Future<DateTimeRange?> Function(
  BuildContext context,
  DateTimeRange initialRange,
);

typedef TagEditorBuilder = Future<Set<String>?> Function(
  BuildContext context,
  Set<String> currentTags,
);

/// Main history tab content rendering averaged and raw views.
class HistoryView extends StatefulWidget {
  const HistoryView({
    super.key,
    this.dateRangePicker,
    this.tagEditor,
  });

  final DateRangePickerBuilder? dateRangePicker;
  final TagEditorBuilder? tagEditor;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HistoryViewModel>().loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final viewModel = context.read<HistoryViewModel>();
    if (!viewModel.hasMore || viewModel.isLoadingMore) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      viewModel.loadMore();
    }
  }

  Future<void> _handleRefresh() {
    return context.read<HistoryViewModel>().refresh();
  }

  Future<void> _handleCustomRange() async {
    final viewModel = context.read<HistoryViewModel>();
    final initialStart = viewModel.filters.startDate ?? DateTime.now().toUtc();
    final initialEnd = viewModel.filters.endDate ?? DateTime.now().toUtc();
    final initialRange = DateTimeRange(
      start: initialStart.toLocal(),
      end: initialEnd.toLocal(),
    );
    final picker = widget.dateRangePicker ?? _showDateRangePicker;
    final picked = await picker(context, initialRange);
    if (picked != null && mounted) {
      await viewModel.setCustomRange(picked.start, picked.end);
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _handleEditTags() async {
    final viewModel = context.read<HistoryViewModel>();
    final editor = widget.tagEditor ?? _showTagEditor;
    final result = await editor(context, viewModel.filters.tags);

    if (result != null && mounted) {
      await viewModel.updateTags(result);
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _handleModeChanged(HistoryViewMode mode) async {
    await context.read<HistoryViewModel>().setViewMode(mode);
    if (!mounted) return;
    _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();
    return Column(
      children: [
        HistoryFilterBar(
          filters: viewModel.filters,
          activePreset: viewModel.activePreset,
          onPresetSelected: (preset) async {
            if (preset == HistoryRangePreset.custom) {
              await _handleCustomRange();
            } else {
              await viewModel.applyPreset(preset);
              _scrollController.jumpTo(0);
            }
          },
          onCustomRange: _handleCustomRange,
          onEditTags: _handleEditTags,
          onModeChanged: _handleModeChanged,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _buildBody(viewModel),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(HistoryViewModel viewModel) {
    final isAveraged = viewModel.filters.viewMode == HistoryViewMode.averaged;
    final groups = viewModel.groups;
    final readings = viewModel.rawReadings;
    final items = isAveraged ? groups : readings;

    if (viewModel.isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null && items.isEmpty) {
      return _ErrorState(
        message: viewModel.error!,
        onRetry: () => viewModel.loadInitial(),
      );
    }

    if (items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          HistoryEmptyState(
            onAddReading: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AddReadingView(),
                ),
              );
            },
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: items.length + (viewModel.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (isAveraged) {
          final item = groups[index];
          final groupId = item.group.id;
          return HistoryGroupTile(
            item: item,
            onToggle: groupId == null
                ? () {}
                : () => viewModel.toggleGroupExpansion(groupId),
          );
        }

        final reading = readings[index];
        return _RawReadingTile(reading: reading);
      },
    );
  }

  Future<DateTimeRange?> _showDateRangePicker(
    BuildContext context,
    DateTimeRange initialRange,
  ) {
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initialRange,
    );
  }

  Future<Set<String>?> _showTagEditor(
    BuildContext context,
    Set<String> currentTags,
  ) async {
    final controller = TextEditingController(text: currentTags.join(', '));
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by tags'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g. fasting, stressed',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final tags = controller.text
                    .split(',')
                    .map((tag) => tag.trim().toLowerCase())
                    .where((tag) => tag.isNotEmpty)
                    .toSet();
                Navigator.of(context).pop(tags);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }
}

/// Standalone history screen used when launched from quick actions.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Pressure History')),
      body: const HistoryView(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawReadingTile extends StatelessWidget {
  const _RawReadingTile({required this.reading});

  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.favorite, color: theme.colorScheme.error),
        title: Text('${reading.systolic}/${reading.diastolic}'),
        subtitle: Text(
          'Pulse ${reading.pulse} • '
          '${DateFormats.shortDateTime.format(reading.takenAt)}',
        ),
        trailing: reading.tags == null
            ? null
            : Icon(
                Icons.label,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
      ),
    );
  }
}
