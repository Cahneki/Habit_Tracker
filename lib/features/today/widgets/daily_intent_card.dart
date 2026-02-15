import 'package:flutter/material.dart';

import '../../../data/daily_intent/daily_intent_model.dart';

class DailyIntentCard extends StatelessWidget {
  const DailyIntentCard({
    super.key,
    required this.loading,
    required this.saving,
    required this.selection,
    required this.pendingIntent,
    required this.editMode,
    required this.onSelect,
    this.error,
    this.onRetry,
  });

  final bool loading;
  final bool saving;
  final Object? error;
  final DailyIntentSelection? selection;
  final DailyIntentType? pendingIntent;
  final bool editMode;
  final ValueChanged<DailyIntentType> onSelect;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedIntent = selection?.intent;
    final locked = selectedIntent != null;

    Widget content;
    if (loading) {
      content = Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading daily intent...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (error != null) {
      content = Row(
        children: [
          Expanded(
            child: Text(
              'Could not load daily intent.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
    } else if (locked) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected: ${selectedIntent.label}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedIntent.selectedDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.primary),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Locked for today',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        selectedIntent.icon,
                        color: scheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedIntent.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      final highlighted = pendingIntent ?? selectedIntent;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedIntent == null
                ? 'Choose your stance for today\'s run.'
                : 'Selected: ${selectedIntent.label}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: DailyIntentType.values.map((intent) {
              final selected = intent == highlighted;
              return _IntentOption(
                intent: intent,
                highlighted: selected,
                enabled: !saving,
                onTap: () => onSelect(intent),
              );
            }).toList(),
          ),
          if (saving) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Committing intent...',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Intent',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }
}

class _IntentOption extends StatelessWidget {
  const _IntentOption({
    required this.intent,
    required this.highlighted,
    required this.enabled,
    required this.onTap,
  });

  final DailyIntentType intent;
  final bool highlighted;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final selectedBg = scheme.primary.withValues(alpha: 0.16);
    final baseBg = scheme.surfaceContainerHigh.withValues(alpha: 0.55);
    final borderColor = highlighted ? scheme.primary : scheme.outlineVariant;
    final iconColor = highlighted ? scheme.primary : scheme.onSurfaceVariant;
    final labelColor = highlighted ? scheme.onSurface : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: highlighted,
      label: '${intent.label}. ${intent.summaryDescription}',
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: highlighted ? 1.03 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: highlighted ? selectedBg : baseBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: enabled ? onTap : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(intent.icon, size: 16, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        intent.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
