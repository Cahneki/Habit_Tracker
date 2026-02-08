import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../db/app_db.dart';
import '../../services/audio_service.dart';
import '../../shared/habit_utils.dart';
import '../../shared/habit_icons.dart';
import '../../shared/xp_utils.dart';
import '../../shared/profile_avatar.dart';
import '../../theme/app_theme.dart';
import '../habits/habit_editor_page.dart';
import '../habits/habit_detail_page.dart';
import '../habits/habit_repository.dart';
import '../habits/schedule_picker.dart';
import '../avatar/avatar_repository.dart';
import '../settings/settings_repository.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.repo,
    required this.audio,
    required this.avatarRepo,
    required this.settingsRepo,
    required this.dataVersion,
    required this.onDataChanged,
    required this.onOpenHabits,
  });
  final HabitRepository repo;
  final AudioService audio;
  final AvatarRepository avatarRepo;
  final SettingsRepository settingsRepo;
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
    required this.settings,
    required this.equipped,
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
  final UserSetting settings;
  final Map<String, String> equipped;
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
    final settings = await widget.settingsRepo.getSettings();
    final equipped = await widget.avatarRepo.getEquipped();

    final rows = <_HabitRowVm>[];
    final upcomingRows = <_HabitRowVm>[];
    var bestCurrent = 0;
    var bestStreak = 0;

    final statsById = await widget.repo.getStreakStatsForHabits(habits);

    for (final h in habits) {
      final stats = statsById[h.id] ??
          const StreakStats(
            current: 0,
            longest: 0,
            totalCompletions: 0,
            lastLocalDay: null,
            completedToday: false,
          );
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

    final totalCompletions = await widget.repo.getTotalCompletionsCount();
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
      settings: settings,
      equipped: equipped,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  Future<void> _addHabit() async {
    final id = 'h-${DateTime.now().millisecondsSinceEpoch}';
    final result = await Navigator.of(context).push<HabitEditorResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => HabitEditorPage(draftId: id),
      ),
    );

    if (result == null) return;
    if (result.action != HabitEditorAction.save) return;
    if (result.name.isEmpty || result.days.isEmpty) return;

    final scheduleMask = ScheduleMask.maskFromDays(result.days);
    await widget.repo.createHabit(
      id: id,
      name: result.name,
      scheduleMask: scheduleMask,
      timeOfDay: result.timeOfDay,
      iconId: result.iconId,
      iconPath: result.iconPath,
    );
    await _refresh();
    widget.onDataChanged();
  }

  Future<void> _pickIconForHabit(Habit habit) async {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<GameTokens>()!;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      builder: (_) {
        final options = habitIconOptions;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose icon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = habit.iconId == option.id;
                    final color = toneColor(option.tone, scheme, tokens);
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context, option.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? scheme.primary : scheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(option.icon, color: color),
                            const SizedBox(height: 6),
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == habit.iconId) return;
    if (selected == 'custom') {
      await _pickCustomIcon(habit);
      return;
    }
    await widget.repo.updateHabitIcon(habit.id, selected);
    await _refresh();
    widget.onDataChanged();
  }

  Future<void> _pickCustomIcon(Habit habit) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(path);
    final targetDir = p.join(dir.path, 'custom_icons');
    await Directory(targetDir).create(recursive: true);
    final targetPath = p.join(targetDir, '${habit.id}$ext');
    await File(path).copy(targetPath);
    await widget.repo.updateHabitCustomIcon(habit.id, targetPath);
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
                            Builder(
                              builder: (context) {
                                final rankTitle = rankTitleForLevel(vm.level);
                                final rankSubtitle = '$rankTitle Tier Rank';
                                return _ProfileHeader(
                                  level: vm.level,
                                  rankTitle: rankTitle,
                                  rankSubtitle: rankSubtitle,
                                  rankIcon: rankIconForLevel(vm.level),
                                  settings: vm.settings,
                                  equipped: vm.equipped,
                                );
                              },
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
                                    onIconTap: () => _pickIconForHabit(row.habit),
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
                                    onIconTap: () => _pickIconForHabit(row.habit),
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
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Quest Board',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        _IconCircleButton(
          icon: Icons.refresh_rounded,
          onPressed: onRefresh,
          tooltip: 'Refresh',
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
    required this.rankIcon,
    required this.settings,
    required this.equipped,
  });

  final int level;
  final String rankTitle;
  final String rankSubtitle;
  final IconData rankIcon;
  final UserSetting settings;
  final Map<String, String> equipped;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ProfileAvatar(
              settings: settings,
              equipped: equipped,
              size: 86,
              borderWidth: 3,
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
                'Sir Questalot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
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
                      rankIcon,
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
    required this.onIconTap,
  });

  final _HabitRowVm row;
  final int xpReward;
  final String statusLabel;
  final bool urgent;
  final VoidCallback? onComplete;
  final String? actionLabel;
  final VoidCallback onTap;
  final VoidCallback onIconTap;

  @override
  Widget build(BuildContext context) {
    final icon = iconForHabit(row.habit.iconId, row.habit.name);
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<GameTokens>()!;
    final iconColor = iconColorForHabit(
      row.habit.iconId,
      row.habit.name,
      scheme,
      tokens,
    );
    final customPath = row.habit.iconPath;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.xpBadgeBg,
                    borderRadius: BorderRadius.circular(12),
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
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: onIconTap,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: scheme.outline),
                          ),
                          child: _HabitIcon(
                            icon: icon,
                            iconColor: iconColor,
                            imagePath: customPath,
                          ),
                        ),
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

class _HabitIcon extends StatelessWidget {
  const _HabitIcon({
    required this.icon,
    required this.iconColor,
    required this.imagePath,
  });

  final IconData icon;
  final Color iconColor;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim() ?? '';
    if (path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            return Icon(icon, size: 30, color: iconColor);
          },
        ),
      );
    }
    return Icon(icon, size: 30, color: iconColor);
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

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
          child: tooltip == null
              ? Icon(icon, size: 22, color: scheme.onSurface)
              : Tooltip(
                  message: tooltip!,
                  waitDuration: const Duration(milliseconds: 400),
                  child: Icon(icon, size: 22, color: scheme.onSurface),
                ),
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

IconData rankIconForLevel(int level) {
  if (level <= 5) return Icons.emoji_events_rounded; // Bronze
  if (level <= 10) return Icons.shield_rounded; // Silver
  if (level <= 20) return Icons.star_rounded; // Gold
  if (level <= 30) return Icons.workspace_premium_rounded; // Platinum
  if (level <= 45) return Icons.auto_awesome_rounded; // Diamond
  return Icons.whatshot_rounded; // Mythic
}
