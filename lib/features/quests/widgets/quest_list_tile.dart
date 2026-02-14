import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/habit_icons.dart';
import '../../../theme/app_theme.dart';
import '../quests_view_model.dart';

class QuestListTile extends StatelessWidget {
  const QuestListTile({
    super.key,
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onOverflow,
    this.trailing,
  });

  final QuestUiItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onOverflow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<GameTokens>()!;
    final icon = iconForHabit(item.habit.iconId, item.habit.name);
    final iconColor = iconColorForHabit(
      item.habit.iconId,
      item.habit.name,
      scheme,
      tokens,
    );

    final accentColor = item.isAtRisk
        ? scheme.error
        : item.isScheduledToday
        ? scheme.primary
        : scheme.outline;

    final subtitleSecondary = <String>[];
    if (item.weekScheduled > 0) {
      subtitleSecondary.add(
        'This week: ${item.weekCompleted}/${item.weekScheduled}',
      );
    }
    if (item.streak.current > 0) {
      subtitleSecondary.add('Streak: ${item.streak.current}d');
    }

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 72,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 72,
                child: Center(
                  child: _IconThumb(
                    icon: icon,
                    iconColor: iconColor,
                    imagePath: item.habit.iconPath,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.habit.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.scheduleText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitleSecondary.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitleSecondary.join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.xpBadgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+${item.xpReward} XP',
                          style: TextStyle(
                            color: tokens.xpBadgeText,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (selectionMode)
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected ? scheme.primary : scheme.outline,
                        )
                      else
                        IconButton(
                          tooltip: 'More',
                          onPressed: onOverflow,
                          icon: const Icon(Icons.more_horiz_rounded),
                        ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconThumb extends StatelessWidget {
  const _IconThumb({
    required this.icon,
    required this.iconColor,
    required this.imagePath,
  });

  final IconData icon;
  final Color iconColor;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = imagePath.trim();

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: path.isNotEmpty
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(icon, color: iconColor);
                },
              )
            : Icon(icon, color: iconColor),
      ),
    );
  }
}
