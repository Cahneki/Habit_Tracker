import 'package:flutter/material.dart';

import '../quests_view_model.dart';

class QuestsSummaryStrip extends StatelessWidget {
  const QuestsSummaryStrip({
    super.key,
    required this.counts,
    required this.activeFilter,
    required this.onSelectFilter,
    required this.showClear,
    required this.onClear,
  });

  final QuestsSummaryCounts counts;
  final QuestSummaryFilter? activeFilter;
  final ValueChanged<QuestSummaryFilter?> onSelectFilter;
  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    InputChip chip(String label, int count, QuestSummaryFilter filter) {
      final selected = activeFilter == filter;
      return InputChip(
        label: Text('$label $count'),
        selected: selected,
        onSelected: (_) => onSelectFilter(selected ? null : filter),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('Active', counts.active, QuestSummaryFilter.active),
            chip(
              'Scheduled Today',
              counts.scheduledToday,
              QuestSummaryFilter.scheduledToday,
            ),
            chip('At Risk', counts.atRisk, QuestSummaryFilter.atRisk),
            chip('Backlog', counts.backlog, QuestSummaryFilter.backlog),
            chip('Archived', counts.archived, QuestSummaryFilter.archived),
          ],
        ),
        if (showClear)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClear,
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
