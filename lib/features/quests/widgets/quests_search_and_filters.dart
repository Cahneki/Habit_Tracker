import 'package:flutter/material.dart';

import '../quests_view_model.dart';

class QuestsSearchAndFilters extends StatelessWidget {
  const QuestsSearchAndFilters({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.activeFilters,
    required this.onToggleFilter,
    required this.showClear,
    required this.onClearFilters,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final Set<QuestQuickFilter> activeFilters;
  final ValueChanged<QuestQuickFilter> onToggleFilter;
  final bool showClear;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    FilterChip chip(QuestQuickFilter filter, String label) {
      final isAll = filter == QuestQuickFilter.all;
      final selected = isAll
          ? activeFilters.isEmpty
          : activeFilters.contains(filter);
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onToggleFilter(filter),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search quests',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip(QuestQuickFilter.all, 'All'),
              const SizedBox(width: 8),
              chip(QuestQuickFilter.today, 'Today'),
              const SizedBox(width: 8),
              chip(QuestQuickFilter.urgent, 'Urgent/At Risk'),
              const SizedBox(width: 8),
              chip(QuestQuickFilter.morning, 'Morning'),
              const SizedBox(width: 8),
              chip(QuestQuickFilter.highXp, 'High XP'),
              const SizedBox(width: 8),
              chip(QuestQuickFilter.notScheduled, 'Not scheduled'),
              const SizedBox(width: 8),
              chip(QuestQuickFilter.archived, 'Archived'),
            ],
          ),
        ),
        if (showClear)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClearFilters,
                child: Text(
                  'Clear filters',
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
