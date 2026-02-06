import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../services/audio_service.dart';
import '../../shared/habit_utils.dart';
import '../../shared/xp_utils.dart';
import '../../theme/app_theme.dart';
import '../habits/habit_detail_page.dart';
import '../habits/habit_repository.dart';
import '../habits/schedule_picker.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.repo,
    required this.audio,
    required this.dataVersion,
    required this.onDataChanged,
    required this.onOpenHabits,
  });
  final HabitRepository repo;
  final AudioService audio;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;
  final VoidCallback onOpenHabits;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _HabitRowVm {
  const _HabitRowVm({
    required this.habit,
    required this.stats,
    required this.subtitle,
  });

  final Habit habit;
  final StreakStats stats;
  final String subtitle;
}

class _HabitsDashboardVm {
  const _HabitsDashboardVm({
    required this.rows,
    required this.upcomingRows,
    required this.xp,
    required this.xpGoal,
    required this.xpToNext,
    required this.gold,
    required this.currentStreak,
    required this.bestStreak,
    required this.level,
  });

  final List<_HabitRowVm> rows;
  final List<_HabitRowVm> upcomingRows;
  final int xp;
  final int xpGoal;
  final int xpToNext;
  final int gold;
  final int currentStreak;
  final int bestStreak;
  final int level;
}

class _TodayPageState extends State<TodayPage> {
  late Future<_HabitsDashboardVm> _dashboardFuture;
  int? _lastLevel;
  late final VoidCallback _dataListener;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
    _dataListener = _refresh;
    widget.dataVersion.addListener(_dataListener);
  }

  @override
  void dispose() {
    widget.dataVersion.removeListener(_dataListener);
    super.dispose();
  }

  Future<_HabitsDashboardVm> _loadDashboard() async {
    final habits = await widget.repo.listActiveHabits();
    final dayStatuses = await widget.repo.getHabitsForDate(DateTime.now());
    final statusById = {for (final s in dayStatuses) s.habit.id: s};

    final rows = <_HabitRowVm>[];
    final upcomingRows = <_HabitRowVm>[];
    var bestCurrent = 0;
    var bestStreak = 0;

    for (final h in habits) {
      final stats = await widget.repo.getStreakStats(h.id);
      if (stats.current > bestCurrent) bestCurrent = stats.current;
      if (stats.longest > bestStreak) bestStreak = stats.longest;

      final schedule = formatScheduleSummary(h.scheduleMask);
      final subtitle = '$schedule · Streak ${stats.current}d';

      final status = statusById[h.id] ??
          HabitDayStatus(habit: h, scheduled: false, completed: false);
      if (!status.scheduled) {
        upcomingRows.add(_HabitRowVm(habit: h, stats: stats, subtitle: subtitle));
        continue;
      }
      rows.add(_HabitRowVm(habit: h, stats: stats, subtitle: subtitle));
    }

    final totalCompletions = await widget.repo.getTotalCompletions();
    final xp = await widget.repo.computeTotalXp();
    final xpGoal = xpGoalFor(xp);
    final gold = totalCompletions * 10 + 250;
    final level = levelForXp(xp);

    if (_lastLevel != null && level > _lastLevel!) {
      widget.audio.play(SoundEvent.levelUp);
    }
    _lastLevel = level;

    return _HabitsDashboardVm(
      rows: rows,
      upcomingRows: upcomingRows,
      xp: xp,
      xpGoal: xpGoal,
      xpToNext: xpGoal - xp,
      gold: gold,
      currentStreak: bestCurrent,
      bestStreak: bestStreak,
      level: level,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  Future<void> _addHabit() async {
    final controller = TextEditingController();
    final selectedDays = <int>{};

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final canCreate =
              controller.text.trim().isNotEmpty && selectedDays.isNotEmpty;
          return AlertDialog(
            title: const Text('Add quest'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Quest name'),
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Schedule',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                SchedulePicker(
                  activeDays: selectedDays,
                  onChanged: (days) => setState(() {
                    selectedDays
                      ..clear()
                      ..addAll(days);
                  }),
                ),
                if (selectedDays.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Pick at least one day',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: canCreate ? () => Navigator.pop(context, true) : null,
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    if (created != true) return;

    final name = controller.text.trim();
    if (name.isEmpty || selectedDays.isEmpty) return;

    final id = 'h-${DateTime.now().millisecondsSinceEpoch}';
    final scheduleMask = ScheduleMask.maskFromDays(selectedDays);
    await widget.repo.createHabit(id: id, name: name, scheduleMask: scheduleMask);
    await _refresh();
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-today',
        onPressed: _addHabit,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Center(
              child: SizedBox(
                width: width < 430 ? width : 430,
                height: height,
                child: FutureBuilder<_HabitsDashboardVm>(
                  future: _dashboardFuture,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final vm = snap.data!;

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      color: scheme.primary,
                      backgroundColor: scheme.surface,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopBar(onRefresh: _refresh),
                            const SizedBox(height: 14),
                            _ProfileHeader(
                              level: vm.level,
                              rankTitle: rankTitleForLevel(vm.level),
                              rankSubtitle: 'Gold Tier Rank',
                            ),
                            const SizedBox(height: 16),
                            _ExperienceCard(
                              xp: vm.xp,
                              xpGoal: vm.xpGoal,
                              xpToNext: vm.xpToNext,
                            ),
                            const SizedBox(height: 16),
                            _StatsRow(gold: vm.gold, streak: vm.currentStreak),
                            const SizedBox(height: 24),
                            _SectionHeader(
                              title: 'Active Quests',
                              actionLabel: 'Manage',
                              onAction: widget.onOpenHabits,
                            ),
                            const SizedBox(height: 12),
                            if (vm.rows.isEmpty)
                              _EmptyState(
                                onAdd: _addHabit,
                                title: 'No quests scheduled today',
                                subtitle: 'Edit schedules or add a new quest.',
                              )
                            else
                              ...vm.rows.map(
                                (row) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _QuestCard(
                                    row: row,
                                    xpReward: xpForHabit(row.habit, row.stats),
                                    statusLabel:
                                        statusLabelFor(row.habit, row.stats),
                                    urgent: isUrgent(row.habit, row.stats),
                                    onComplete: () async {
                                      final wasCompleted =
                                          row.stats.completedToday;
                                      await widget.repo.toggleCompletionForDay(
                                        row.habit.id,
                                        DateTime.now(),
                                      );
                                      await _refresh();
                                      widget.onDataChanged();
                                      if (!wasCompleted) {
                                        widget.audio.play(SoundEvent.complete);
                                      }
                                    },
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HabitDetailPage(
                                            repo: widget.repo,
                                            habit: row.habit,
                                            onDataChanged: widget.onDataChanged,
                                          ),
                                        ),
                                      );
                                      await _refresh();
                                      widget.onDataChanged();
                                    },
                                  ),
                                ),
                              ),
                            if (vm.upcomingRows.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Upcoming',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Not scheduled today',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              ...vm.upcomingRows.map(
                                (row) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _QuestCard(
                                    row: row,
                                    xpReward: xpForHabit(row.habit, row.stats),
                                    statusLabel: 'Not scheduled today',
                                    urgent: false,
                                    onComplete: null,
                                    actionLabel: 'Not today',
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HabitDetailPage(
                                            repo: widget.repo,
                                            habit: row.habit,
                                            onDataChanged: widget.onDataChanged,
                                          ),
                                        ),
                                      );
                                      await _refresh();
                                      widget.onDataChanged();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary, width: 2),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.imgur.com/4Z7wG2x.png'),
            backgroundColor: scheme.surface,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Quest Board',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        _IconCircleButton(
          icon: Icons.notifications_rounded,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.level,
    required this.rankTitle,
    required this.rankSubtitle,
  });

  final int level;
  final String rankTitle;
  final String rankSubtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: scheme.outline, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
                image: const DecorationImage(
                  image: NetworkImage('https://i.imgur.com/Q7R4N7f.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: scheme.onPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LVL $level',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sir Habitalot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                rankTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.tertiary,
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: scheme.onTertiary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rankSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.xp,
    required this.xpGoal,
    required this.xpToNext,
  });

  final int xp;
  final int xpGoal;
  final int xpToNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<GameTokens>()!;
    final progress = xpGoal == 0 ? 0.0 : (xp / xpGoal).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Experience',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.xpBadgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$xp / $xpGoal XP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tokens.xpBadgeText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: scheme.surface,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$xpToNext XP TO LEVEL ${levelForXp(xp) + 1}',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.gold, required this.streak});

  final int gold;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Gold',
            value: gold.toString(),
            icon: Icons.monetization_on_rounded,
            iconColor: scheme.tertiary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Streak',
            value: '$streak Days',
            icon: Icons.local_fire_department_rounded,
            iconColor: scheme.error,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.row,
    required this.xpReward,
    required this.statusLabel,
    required this.urgent,
    required this.onComplete,
    this.actionLabel,
    required this.onTap,
  });

  final _HabitRowVm row;
  final int xpReward;
  final String statusLabel;
  final bool urgent;
  final VoidCallback? onComplete;
  final String? actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = iconForHabit(row.habit.name);
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<GameTokens>()!;
    final iconColor = iconColorForHabit(row.habit.name, tokens);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.xpBadgeBg,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      topRight: Radius.circular(20),
                    ),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Text(
                    '+$xpReward XP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: tokens.xpBadgeText,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: scheme.outline),
                        ),
                        child: Icon(icon, size: 30, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.habit.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              row.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (urgent) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tokens.urgentDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: tokens.urgentText,
                          ),
                        ),
                      ] else ...[
                        Icon(Icons.schedule_rounded,
                            size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            disabledBackgroundColor:
                                scheme.primary.withValues(alpha: 0.35),
                            disabledForegroundColor:
                                scheme.onPrimary.withValues(alpha: 0.7),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 6,
                            ),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(
                            actionLabel ??
                                (row.stats.completedToday ? 'Undo' : 'Complete'),
                          ),
                        ),
                      ),
                    ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAdd,
    this.title = 'No quests yet',
    this.subtitle = 'Create your first quest to start earning XP.',
  });

  final VoidCallback onAdd;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                child: const Text('Create Quest'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: scheme.onSurface),
        ),
      ),
    );
  }
}

int xpForHabit(Habit habit, StreakStats stats) {
  var base = 20;
  if (isDailySchedule(habit.scheduleMask)) base += 10;
  base += (stats.current ~/ 5) * 5;
  return base.clamp(20, 60);
}

String statusLabelFor(Habit habit, StreakStats stats) {
  if (stats.completedToday) return 'Completed';
  if (isDailySchedule(habit.scheduleMask)) return 'Daily Reset';
  final schedule = formatScheduleSummary(habit.scheduleMask);
  return schedule.replaceFirst('Schedule: ', '');
}

bool isUrgent(Habit habit, StreakStats stats) {
  if (stats.completedToday) return false;
  return stats.current == 0;
}

IconData iconForHabit(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('run') || lower.contains('cardio')) {
    return Icons.directions_run_rounded;
  }
  if (lower.contains('water') || lower.contains('hydrate')) {
    return Icons.water_drop_rounded;
  }
  if (lower.contains('read') || lower.contains('book')) {
    return Icons.menu_book_rounded;
  }
  if (lower.contains('medit') || lower.contains('yoga')) {
    return Icons.self_improvement_rounded;
  }
  if (lower.contains('sleep')) return Icons.bedtime_rounded;
  if (lower.contains('lift') || lower.contains('gym') || lower.contains('workout')) {
    return Icons.fitness_center_rounded;
  }
  return Icons.auto_awesome_rounded;
}

Color iconColorForHabit(String name, GameTokens tokens) {
  final lower = name.toLowerCase();
  if (lower.contains('water') || lower.contains('hydrate')) {
    return tokens.habitWater;
  }
  if (lower.contains('read') || lower.contains('book')) {
    return tokens.habitRead;
  }
  if (lower.contains('sleep')) return tokens.habitSleep;
  if (lower.contains('run') || lower.contains('cardio')) {
    return tokens.habitRun;
  }
  if (lower.contains('lift') || lower.contains('gym') || lower.contains('workout')) {
    return tokens.habitLift;
  }
  return tokens.habitDefault;
}
