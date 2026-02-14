import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../services/audio_service.dart';
import '../../shared/local_day.dart';
import '../../shared/profile_avatar.dart';
import '../../shared/xp_utils.dart';
import '../../theme/app_theme.dart';
import '../avatar/avatar_repository.dart';
import '../battles/battle_service.dart';
import '../habits/habit_editor_page.dart';
import '../habits/habit_repository.dart';
import '../habits/schedule_picker.dart';
import '../quests/quests_view_model.dart';
import '../quests/widgets/quest_list_tile.dart';
import '../settings/settings_repository.dart';

enum _MissionSort { urgency, xpReward, streakRisk, manual }

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
    required this.onOpenBattles,
  });

  final HabitRepository repo;
  final AudioService audio;
  final AvatarRepository avatarRepo;
  final SettingsRepository settingsRepo;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;
  final VoidCallback onOpenHabits;
  final VoidCallback onOpenBattles;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _HabitRowVm {
  const _HabitRowVm({
    required this.habit,
    required this.stats,
    required this.timeLabel,
    required this.weekCompleted,
    required this.weekScheduled,
    required this.manualOrder,
  });

  final Habit habit;
  final StreakStats stats;
  final String timeLabel;
  final int weekCompleted;
  final int weekScheduled;
  final int manualOrder;
}

class _UpcomingRowVm {
  const _UpcomingRowVm({
    required this.habit,
    required this.subtitle,
    required this.manualOrder,
  });

  final Habit habit;
  final String subtitle;
  final int manualOrder;
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
    required this.questsDone,
    required this.questsTotal,
    required this.xpToday,
    required this.bossDamageToday,
    required this.weeklyDaysLeft,
    required this.weeklyProgress,
  });

  final List<_HabitRowVm> rows;
  final List<_UpcomingRowVm> upcomingRows;
  final int xp;
  final int xpGoal;
  final int xpToNext;
  final int gold;
  final int currentStreak;
  final int bestStreak;
  final int level;
  final UserSetting settings;
  final Map<String, String> equipped;
  final int questsDone;
  final int questsTotal;
  final int xpToday;
  final int bossDamageToday;
  final int weeklyDaysLeft;
  final double weeklyProgress;
}

class _TodayPageState extends State<TodayPage> {
  late Future<_HabitsDashboardVm> _dashboardFuture;
  int? _lastLevel;
  late final VoidCallback _dataListener;
  _MissionSort _sort = _MissionSort.urgency;
  bool _completedExpanded = true;

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
    final now = DateTime.now();
    final habits = await widget.repo.listActiveHabits();
    final dayStatuses = await widget.repo.getHabitsForDate(now);
    final statusById = {for (final s in dayStatuses) s.habit.id: s};
    final settings = await widget.settingsRepo.getSettings();
    final equipped = await widget.avatarRepo.getEquipped();
    final statsById = await widget.repo.getStreakStatsForHabits(habits);

    final weekStart = startOfLocalDay(
      now,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final habitIds = habits.map((h) => h.id).toList();
    final weekCompletions = await widget.repo.getCompletionDaysForRangeByHabit(
      weekStart,
      weekEnd,
      habitIds: habitIds,
    );

    final rows = <_HabitRowVm>[];
    final upcomingRows = <_UpcomingRowVm>[];

    var bestCurrent = 0;
    var bestStreak = 0;
    var questsDone = 0;
    var questsTotal = 0;
    var xpToday = 0;
    var bossDamageToday = 0;

    for (var i = 0; i < habits.length; i++) {
      final habit = habits[i];
      final stats =
          statsById[habit.id] ??
          const StreakStats(
            current: 0,
            longest: 0,
            totalCompletions: 0,
            lastLocalDay: null,
            completedToday: false,
          );

      if (stats.current > bestCurrent) bestCurrent = stats.current;
      if (stats.longest > bestStreak) bestStreak = stats.longest;

      final status =
          statusById[habit.id] ??
          HabitDayStatus(habit: habit, scheduled: false, completed: false);

      if (status.scheduled) {
        final weeklyDone = _countWeeklyDone(
          habit,
          weekStart,
          weekEnd,
          weekCompletions[habit.id] ?? const <String>{},
        );
        final weeklyScheduled = _countWeeklyScheduled(
          habit,
          weekStart,
          weekEnd,
        );

        rows.add(
          _HabitRowVm(
            habit: habit,
            stats: stats,
            timeLabel: _timeLabel(habit.timeOfDay),
            weekCompleted: weeklyDone,
            weekScheduled: weeklyScheduled,
            manualOrder: i,
          ),
        );

        questsTotal += 1;
        if (stats.completedToday) {
          questsDone += 1;
          xpToday += xpForHabit(habit, stats);
          bossDamageToday += _baseDamageForHabit(habit.baseXp);
        }
      } else {
        upcomingRows.add(
          _UpcomingRowVm(
            habit: habit,
            subtitle: _nextScheduleLabel(now, habit),
            manualOrder: i,
          ),
        );
      }
    }

    final totalCompletions = await widget.repo.getTotalCompletionsCount();
    final xp = await widget.repo.computeTotalXp();
    final xpGoal = xpGoalFor(xp);
    final gold = totalCompletions * 10 + 250;
    final level = levelForXp(xp);

    if (_lastLevel != null && level > _lastLevel!) {
      await widget.audio.play(SoundEvent.levelUp);
    }
    _lastLevel = level;

    final weeklyBattle = await BattleService(
      widget.repo,
      widget.avatarRepo,
    ).computeWeekly();

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
      questsDone: questsDone,
      questsTotal: questsTotal,
      xpToday: xpToday,
      bossDamageToday: bossDamageToday,
      weeklyDaysLeft: weeklyBattle.daysLeft,
      weeklyProgress: weeklyBattle.progressPct,
    );
  }

  int _countWeeklyScheduled(
    Habit habit,
    DateTime start,
    DateTime endExclusive,
  ) {
    var total = 0;
    for (
      var d = start;
      d.isBefore(endExclusive);
      d = d.add(const Duration(days: 1))
    ) {
      if (_isScheduled(d, habit.scheduleMask)) {
        total += 1;
      }
    }
    return total;
  }

  int _countWeeklyDone(
    Habit habit,
    DateTime start,
    DateTime endExclusive,
    Set<String> completed,
  ) {
    var total = 0;
    for (
      var d = start;
      d.isBefore(endExclusive);
      d = d.add(const Duration(days: 1))
    ) {
      if (!_isScheduled(d, habit.scheduleMask)) continue;
      if (completed.contains(localDay(d))) {
        total += 1;
      }
    }
    return total;
  }

  bool _isScheduled(DateTime date, int? scheduleMask) {
    if (scheduleMask == null) return true;
    if (scheduleMask == 0) return false;
    final bit = 1 << (date.weekday - 1);
    return (scheduleMask & bit) != 0;
  }

  int _baseDamageForHabit(int baseXp) {
    final dmg = 8 + (baseXp ~/ 5);
    if (dmg < 8) return 8;
    if (dmg > 14) return 14;
    return dmg;
  }

  String _timeLabel(String value) {
    switch (value) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'evening':
        return 'Evening';
      default:
        return 'Anytime';
    }
  }

  String _nextScheduleLabel(DateTime now, Habit habit) {
    final period = _timeLabel(habit.timeOfDay);
    for (var offset = 0; offset <= 14; offset++) {
      final day = startOfLocalDay(now).add(Duration(days: offset));
      if (_isScheduled(day, habit.scheduleMask)) {
        if (offset == 0) return 'Later Today $period';
        if (offset == 1) return 'Tomorrow $period';
        if (offset <= 6) return '${_weekday(day.weekday)} $period';
        return 'Soon $period';
      }
    }
    return 'Unscheduled';
  }

  String _weekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Soon';
    }
  }

  String _displayName() {
    // TODO: Replace with persisted profile name when available.
    return 'Adventurer';
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  Future<void> _addHabit() async {
    final id = 'h-${DateTime.now().millisecondsSinceEpoch}';
    final result = await _showHabitEditor(draftId: id);

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

  Future<HabitEditorResult?> _showHabitEditor({Habit? habit, String? draftId}) {
    return Navigator.of(context).push<HabitEditorResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => HabitEditorPage(habit: habit, draftId: draftId),
      ),
    );
  }

  Future<void> _toggleMission(_HabitRowVm row) async {
    final wasCompleted = row.stats.completedToday;

    await widget.repo.toggleCompletionForDay(row.habit.id, DateTime.now());
    await _refresh();
    widget.onDataChanged();

    if (!wasCompleted) {
      await widget.audio.play(SoundEvent.complete);
    }
  }

  QuestUiItem _questItemForRow(_HabitRowVm row) {
    return QuestUiItem(
      habit: row.habit,
      streak: row.stats,
      isScheduledToday: true,
      isCompletedToday: row.stats.completedToday,
      isAtRisk: isUrgent(row.habit, row.stats),
      isBacklog: row.habit.scheduleMask == 0,
      timeOfDay: row.habit.timeOfDay,
      weekCompleted: row.weekCompleted,
      weekScheduled: row.weekScheduled,
      xpReward: xpForHabit(row.habit, row.stats),
      nextDueDate: null,
      scheduleText: QuestsViewModel.humanScheduleText(
        row.habit.scheduleMask,
        _timeLabel(row.habit.timeOfDay),
      ),
      manualOrder: row.manualOrder,
      isArchived: false,
      createdAt: row.habit.createdAt,
    );
  }

  Future<void> _editHabit(Habit habit) async {
    final result = await _showHabitEditor(habit: habit);
    if (result == null) return;
    if (result.action == HabitEditorAction.archive) {
      await _archiveHabit(habit);
      return;
    }
    if (result.action != HabitEditorAction.save) return;

    if (result.name.trim() != habit.name) {
      await widget.repo.renameHabit(habit.id, result.name.trim());
    }
    final nextMask = ScheduleMask.maskFromDays(result.days);
    if (nextMask != habit.scheduleMask) {
      await widget.repo.updateScheduleMask(habit.id, nextMask);
    }
    if (result.timeOfDay != habit.timeOfDay) {
      await widget.repo.updateTimeOfDay(habit.id, result.timeOfDay);
    }
    if (result.iconId != habit.iconId || result.iconPath != habit.iconPath) {
      if (result.iconId == 'custom') {
        await widget.repo.updateHabitCustomIcon(habit.id, result.iconPath);
      } else {
        await widget.repo.updateHabitIcon(habit.id, result.iconId);
      }
    }

    await _refresh();
    widget.onDataChanged();
  }

  Future<void> _archiveHabit(Habit habit) async {
    await widget.repo.archiveHabit(habit.id);
    await _refresh();
    widget.onDataChanged();
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete quest?'),
        content: const Text('This removes the quest and its history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await widget.repo.deleteHabit(habit.id);
    await _refresh();
    widget.onDataChanged();
  }

  Future<void> _showMissionActions(_HabitRowVm row) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              ListTile(
                leading: const Icon(Icons.archive_rounded),
                title: const Text('Archive'),
                onTap: () => Navigator.of(context).pop('archive'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded),
                title: const Text('Delete'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'edit':
        await _editHabit(row.habit);
        break;
      case 'archive':
        await _archiveHabit(row.habit);
        break;
      case 'delete':
        await _deleteHabit(row.habit);
        break;
    }
  }

  List<Widget> _buildTodayMissionRows(List<_HabitRowVm> rows) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<GameTokens>()!;

    return rows
        .map(
          (row) => Container(
            key: ValueKey('today-quest-${row.habit.id}-${row.manualOrder}'),
            child: QuestListTile(
              item: _questItemForRow(row),
              selected: false,
              selectionMode: false,
              onTap: () {},
              onLongPress: () => _showMissionActions(row),
              onOverflow: () => _showMissionActions(row),
              trailing: Column(
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
                      '+${xpForHabit(row.habit, row.stats)} XP',
                      style: TextStyle(
                        color: tokens.xpBadgeText,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () => _toggleMission(row),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      child: const Text('Complete'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  List<_HabitRowVm> _sortRows(List<_HabitRowVm> rows) {
    final sorted = List<_HabitRowVm>.from(rows);
    switch (_sort) {
      case _MissionSort.urgency:
        sorted.sort((a, b) {
          final aUrgent = isUrgent(a.habit, a.stats) ? 0 : 1;
          final bUrgent = isUrgent(b.habit, b.stats) ? 0 : 1;
          if (aUrgent != bUrgent) return aUrgent.compareTo(bUrgent);
          return xpForHabit(
            b.habit,
            b.stats,
          ).compareTo(xpForHabit(a.habit, a.stats));
        });
        break;
      case _MissionSort.xpReward:
        sorted.sort(
          (a, b) => xpForHabit(
            b.habit,
            b.stats,
          ).compareTo(xpForHabit(a.habit, a.stats)),
        );
        break;
      case _MissionSort.streakRisk:
        sorted.sort((a, b) => a.stats.current.compareTo(b.stats.current));
        break;
      case _MissionSort.manual:
        sorted.sort((a, b) => a.manualOrder.compareTo(b.manualOrder));
        break;
    }
    return sorted;
  }

  Future<void> _showSortSheet() async {
    final next = await showModalBottomSheet<_MissionSort>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        ListTile tile(_MissionSort value, String label) {
          final selected = _sort == value;
          return ListTile(
            title: Text(label),
            trailing: selected
                ? Icon(Icons.check_rounded, color: scheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop(value),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile(_MissionSort.urgency, 'Urgency'),
              tile(_MissionSort.xpReward, 'XP Reward'),
              tile(_MissionSort.streakRisk, 'Streak Risk'),
              tile(_MissionSort.manual, 'Manual'),
            ],
          ),
        );
      },
    );

    if (next != null) {
      setState(() => _sort = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                width: width < 440 ? width : 440,
                height: height,
                child: FutureBuilder<_HabitsDashboardVm>(
                  future: _dashboardFuture,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final vm = snap.data!;
                    final completedRows = vm.rows
                        .where((r) => r.stats.completedToday)
                        .toList();
                    final activeRows = vm.rows
                        .where((r) => !r.stats.completedToday)
                        .toList();
                    final sortedActive = _sortRows(activeRows);
                    final bossHpProgress = (1 - vm.weeklyProgress).clamp(
                      0.0,
                      1.0,
                    );

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
                            const _TopBar(),
                            const SizedBox(height: 14),
                            _GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _AvatarLevelBadge(
                                        settings: vm.settings,
                                        equipped: vm.equipped,
                                        level: vm.level,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _displayName(),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: LinearProgressIndicator(
                                                value: vm.xpGoal == 0
                                                    ? 0
                                                    : (vm.xp / vm.xpGoal).clamp(
                                                        0.0,
                                                        1.0,
                                                      ),
                                                minHeight: 12,
                                                backgroundColor: scheme.surface,
                                                color: scheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${vm.xp} / ${vm.xpGoal} XP',
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _InlineStatsBar(
                                    currentStreak: vm.currentStreak,
                                    xpToday: vm.xpToday,
                                    questsDone: vm.questsDone,
                                    questsTotal: vm.questsTotal,
                                  ),
                                  const SizedBox(height: 14),
                                  _WeeklyBossCard(
                                    daysLeft: vm.weeklyDaysLeft,
                                    hpProgress: bossHpProgress,
                                    onViewBattle: widget.onOpenBattles,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Today's Quests (${sortedActive.length})",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Sort',
                                  onPressed: _showSortSheet,
                                  icon: const Icon(Icons.sort_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _GlassCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  if (sortedActive.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'No active quests scheduled today.',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    ..._buildTodayMissionRows(sortedActive),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _GlassCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () => setState(() {
                                      _completedExpanded = !_completedExpanded;
                                    }),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        12,
                                        14,
                                        12,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Completed Today (${completedRows.length})',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            _completedExpanded
                                                ? Icons.expand_less_rounded
                                                : Icons.expand_more_rounded,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_completedExpanded &&
                                      completedRows.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        0,
                                        14,
                                        12,
                                      ),
                                      child: Column(
                                        children: completedRows
                                            .map(
                                              (row) => Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      row.habit.name,
                                                      style: TextStyle(
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Undo',
                                                    onPressed: () =>
                                                        _toggleMission(row),
                                                    icon: const Icon(
                                                      Icons.undo_rounded,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  if (_completedExpanded &&
                                      completedRows.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        0,
                                        14,
                                        12,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Complete a quest to earn XP.',
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
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

class _AvatarLevelBadge extends StatelessWidget {
  const _AvatarLevelBadge({
    required this.settings,
    required this.equipped,
    required this.level,
  });

  final UserSetting settings;
  final Map<String, String> equipped;
  final int level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const SizedBox(height: 80),
          Positioned(
            top: 0,
            child: ProfileAvatar(
              settings: settings,
              equipped: equipped,
              size: 72,
              borderWidth: 3,
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.primaryContainer.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LVL $level',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const SizedBox(width: 42, height: 42),
        const Spacer(),
        const SizedBox(width: 42, height: 42),
        const Spacer(),
        SizedBox(
          width: 42,
          height: 42,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: BorderSide(color: scheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.notifications_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _WeeklyBossCard extends StatelessWidget {
  const _WeeklyBossCard({
    required this.daysLeft,
    required this.hpProgress,
    required this.onViewBattle,
  });

  final int daysLeft;
  final double hpProgress;
  final VoidCallback onViewBattle;

  @override
  Widget build(BuildContext context) {
    final daysLabel = daysLeft == 1 ? '1 day left' : '$daysLeft days left';
    final hpPct = (hpProgress * 100).round();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 14,
            compact ? 12 : 14,
            compact ? 12 : 14,
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF5A3124), Color(0xFF8D5630), Color(0xFF2B211D)],
            ),
            border: Border.all(
              color: const Color(0xFFE9D5B7).withValues(alpha: 0.65),
              width: 1.4,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const RadialGradient(
                      center: Alignment(0.8, -0.35),
                      radius: 0.95,
                      colors: [Color(0x66FFC86A), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: compact ? -26 : -22,
                bottom: compact ? -28 : -18,
                child: Icon(
                  Icons.whatshot_rounded,
                  size: compact ? 118 : 132,
                  color: const Color(0x77FF8E35),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: compact ? 34 : 40,
                        height: compact ? 34 : 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD63E2A), Color(0xFFAC1F11)],
                          ),
                        ),
                        child: Icon(
                          Icons.whatshot_rounded,
                          color: Colors.white,
                          size: compact ? 19 : 22,
                        ),
                      ),
                      SizedBox(width: compact ? 8 : 10),
                      Expanded(
                        child: Text(
                          'Weekly Boss • $daysLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFF8EFE2),
                            fontSize: compact ? 15 : 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onViewBattle,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFDE5BF),
                          textStyle: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 12 : 14,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 6 : 10,
                            vertical: compact ? 4 : 6,
                          ),
                        ),
                        child: const Text('View Battle'),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  Text(
                    'Boss HP: $hpPct%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 16 : 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: hpProgress,
                      minHeight: compact ? 11 : 14,
                      backgroundColor: const Color(
                        0xFFE7D9C4,
                      ).withValues(alpha: 0.82),
                      color: const Color(0xFFC8642A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InlineStatsBar extends StatelessWidget {
  const _InlineStatsBar({
    required this.currentStreak,
    required this.xpToday,
    required this.questsDone,
    required this.questsTotal,
  });

  final int currentStreak;
  final int xpToday;
  final int questsDone;
  final int questsTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            12,
            compact ? 8 : 10,
            12,
            compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _InlineStatItem(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFE06B29),
                  label: compact
                      ? '${currentStreak}d Streak'
                      : '$currentStreak Day Streak',
                  compact: compact,
                ),
              ),
              Container(
                width: 1,
                height: compact ? 20 : 24,
                color: scheme.outline.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineStatItem(
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFF42B86A),
                  label: compact ? '+$xpToday XP' : '+$xpToday XP Today',
                  compact: compact,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 1,
                height: compact ? 20 : 24,
                color: scheme.outline.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineStatItem(
                  icon: Icons.task_alt_rounded,
                  iconColor: scheme.primary,
                  label: compact
                      ? '$questsDone/$questsTotal Quests'
                      : 'Quests $questsDone/$questsTotal',
                  compact: compact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InlineStatItem extends StatelessWidget {
  const _InlineStatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: compact ? 20 : 22, color: iconColor),
        SizedBox(width: compact ? 6 : 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

int xpForHabit(Habit habit, StreakStats stats) {
  var base = 20;
  if (habit.scheduleMask == null || habit.scheduleMask == 0x7f) {
    base += 10;
  }
  base += (stats.current ~/ 5) * 5;
  return base.clamp(20, 60);
}

bool isUrgent(Habit habit, StreakStats stats) {
  if (stats.completedToday) return false;
  return stats.current == 0;
}
