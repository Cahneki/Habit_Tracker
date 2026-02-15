import 'package:flutter/material.dart';

import '../../../data/daily_actions/daily_free_action_model.dart';

class EmptyTodayPanel extends StatelessWidget {
  const EmptyTodayPanel({
    super.key,
    required this.intentSelected,
    required this.completedActions,
    required this.savingActions,
    required this.onPerformAction,
    required this.onAddQuest,
    this.onEditSchedule,
  });

  final bool intentSelected;
  final Set<DailyFreeActionType> completedActions;
  final Set<DailyFreeActionType> savingActions;
  final ValueChanged<DailyFreeActionType> onPerformAction;
  final VoidCallback onAddQuest;
  final VoidCallback? onEditSchedule;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actions = DailyFreeActionType.values;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No Quests Scheduled',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a quick action to keep momentum.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!intentSelected) ...[
            const SizedBox(height: 8),
            Text(
              'Choose a Daily Intent to begin today\'s run.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 380) {
                return Column(
                  children: actions
                      .map((action) => _buildActionTile(context, action))
                      .toList(),
                );
              }
              return Row(
                children: actions
                    .map(
                      (action) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: action == actions.last ? 0 : 8,
                          ),
                          child: _buildActionTile(context, action),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddQuest,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Quest'),
                ),
              ),
              if (onEditSchedule != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onEditSchedule,
                  child: const Text('Edit Schedule'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, DailyFreeActionType action) {
    final scheme = Theme.of(context).colorScheme;
    final done = completedActions.contains(action);
    final busy = savingActions.contains(action);
    final enabled = intentSelected && !done && !busy;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? () => onPerformAction(action) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              Text(action.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        color: done
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.description,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                )
              else if (done)
                Icon(Icons.check_circle_rounded, color: scheme.primary)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
