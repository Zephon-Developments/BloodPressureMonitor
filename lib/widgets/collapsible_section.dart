import 'package:flutter/material.dart';

/// A collapsible section widget designed for the History page.
///
/// Displays a section header with an icon, title, and mini-stats preview
/// when collapsed. When expanded, shows the full content with smooth animations.
///
/// This widget follows Material 3 design guidelines and includes proper
/// accessibility semantics for screen readers.
class CollapsibleSection extends StatefulWidget {
  /// Creates a collapsible section.
  ///
  /// The [title], [icon], [miniStatsPreview], and [expandedContent] parameters
  /// are required. The section is collapsed by default unless [initiallyExpanded]
  /// is set to true.
  const CollapsibleSection({
    required this.title,
    required this.icon,
    required this.miniStatsPreview,
    required this.expandedContent,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    super.key,
  });

  /// The title displayed in the section header.
  final String title;

  /// The icon displayed at the start of the section header.
  final IconData icon;

  /// Widget shown in the collapsed header to preview stats.
  final Widget miniStatsPreview;

  /// The content displayed when the section is expanded.
  final Widget expandedContent;

  /// Whether the section is initially expanded.
  final bool initiallyExpanded;

  /// Callback invoked when the expansion state changes.
  ///
  /// The boolean parameter indicates the new expanded state.
  final void Function(bool)? onExpansionChanged;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: _isExpanded ? 2 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!_isExpanded) ...[
                          const SizedBox(height: 4),
                          widget.miniStatsPreview,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                    semanticLabel:
                        _isExpanded ? 'Collapse section' : 'Expand section',
                  ),
                ],
              ),
            ),
          ),
          // Expanded Content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.expandedContent,
            ),
        ],
      ),
    );
  }
}
