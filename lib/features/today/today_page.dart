import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../services/audio_service.dart';
import '../../shared/local_day.dart';
import '../../shared/profile_avatar.dart';
import '../../shared/xp_utils.dart';
import '../../theme/app_theme.dart';
import '../avatar/avatar_repository.dart';
import '../battles/battle_service.dart';
import '../habits/habit_detail_page.dart';
import '../habits/habit_editor_page.dart';
import '../habits/habit_repository.dart';
import '../habits/schedule_picker.dart';
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
  final Set<String> _collapsingIds = <String>{};

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

  Future<void> _toggleMission(_HabitRowVm row) async {
    final wasCompleted = row.stats.completedToday;

    if (!wasCompleted) {
      setState(() {
        _collapsingIds.add(row.habit.id);
      });
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }

    await widget.repo.toggleCompletionForDay(row.habit.id, DateTime.now());
    await _refresh();
    widget.onDataChanged();

    if (!wasCompleted) {
      setState(() {
        _collapsingIds.remove(row.habit.id);
      });
      await widget.audio.play(SoundEvent.complete);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Completed.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await widget.repo.toggleCompletionForDay(
                row.habit.id,
                DateTime.now(),
              );
              await _refresh();
              widget.onDataChanged();
            },
          ),
        ),
      );
    }
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
    final tokens = Theme.of(context).extension<GameTokens>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-today',
        onPressed: _addHabit,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.surfaceContainerHigh.withValues(alpha: 0.7),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
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
                                                      : (vm.xp / vm.xpGoal)
                                                            .clamp(0.0, 1.0),
                                                  minHeight: 12,
                                                  backgroundColor:
                                                      scheme.surface,
                                                  color: scheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${vm.xp} / ${vm.xpGoal} XP '
                                                '(${((vm.xp / vm.xpGoal).clamp(0.0, 1.0) * 100).round()}%)',
                                                style: TextStyle(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        12,
                                        14,
                                        12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.surfaceContainerHigh
                                            .withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: scheme.outline.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "Today's Progress",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 18,
                                            runSpacing: 8,
                                            children: [
                                              _MiniStatLine(
                                                icon: Icons.task_alt_rounded,
                                                label:
                                                    'Quests: ${vm.questsDone} / ${vm.questsTotal}',
                                              ),
                                              _MiniStatLine(
                                                icon: Icons.bolt_rounded,
                                                label:
                                                    'XP Today: +${vm.xpToday}',
                                              ),
                                              _MiniStatLine(
                                                icon: Icons.flash_on_rounded,
                                                label:
                                                    'Boss Damage: +${vm.bossDamageToday}',
                                              ),
                                              _MiniStatLine(
                                                icon: Icons
                                                    .local_fire_department_rounded,
                                                label:
                                                    'Streak: ${vm.currentStreak} days',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Divider(
                                            height: 1,
                                            color: scheme.outline.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Keep density above 70% to defeat Weekly Boss.',
                                            style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Today's Missions (${sortedActive.length})",
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
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        12,
                                        14,
                                        10,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.military_tech_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Weekly Boss — ${vm.weeklyDaysLeft}d left',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Open Battles tab to view battle details.',
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text('View Battle →'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 2,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: vm.weeklyProgress,
                                          minHeight: 7,
                                          backgroundColor: scheme.surface,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Divider(
                                      height: 1,
                                      color: scheme.outline.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
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
                                      ...sortedActive.asMap().entries.map((
                                        entry,
                                      ) {
                                        final idx = entry.key;
                                        final row = entry.value;
                                        final xpReward = xpForHabit(
                                          row.habit,
                                          row.stats,
                                        );
                                        final urgent = isUrgent(
                                          row.habit,
                                          row.stats,
                                        );
                                        return AnimatedOpacity(
                                          opacity:
                                              _collapsingIds.contains(
                                                row.habit.id,
                                              )
                                              ? 0
                                              : 1,
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          child: AnimatedSize(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            child:
                                                _collapsingIds.contains(
                                                  row.habit.id,
                                                )
                                                ? const SizedBox.shrink()
                                                : InkWell(
                                                    onTap: () async {
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              HabitDetailPage(
                                                                repo:
                                                                    widget.repo,
                                                                habit:
                                                                    row.habit,
                                                                onDataChanged:
                                                                    widget
                                                                        .onDataChanged,
                                                              ),
                                                        ),
                                                      );
                                                      await _refresh();
                                                      widget.onDataChanged();
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.fromLTRB(
                                                            0,
                                                            0,
                                                            0,
                                                            0,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color:
                                                                idx ==
                                                                    sortedActive
                                                                            .length -
                                                                        1
                                                                ? Colors
                                                                      .transparent
                                                                : scheme.outline
                                                                      .withValues(
                                                                        alpha:
                                                                            0.2,
                                                                      ),
                                                          ),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.fromLTRB(
                                                              14,
                                                              12,
                                                              14,
                                                              12,
                                                            ),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Container(
                                                              width: 4,
                                                              height: 76,
                                                              decoration: BoxDecoration(
                                                                color: urgent
                                                                    ? scheme
                                                                          .error
                                                                    : scheme
                                                                          .primary,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      if (urgent)
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                10,
                                                                            vertical:
                                                                                4,
                                                                          ),
                                                                          decoration: BoxDecoration(
                                                                            color:
                                                                                scheme.errorContainer,
                                                                            borderRadius: BorderRadius.circular(
                                                                              999,
                                                                            ),
                                                                          ),
                                                                          child: Text(
                                                                            'URGENT',
                                                                            style: TextStyle(
                                                                              color: scheme.onErrorContainer,
                                                                              fontWeight: FontWeight.w800,
                                                                              fontSize: 11,
                                                                            ),
                                                                          ),
                                                                        )
                                                                      else
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                8,
                                                                            vertical:
                                                                                3,
                                                                          ),
                                                                          decoration: BoxDecoration(
                                                                            color:
                                                                                tokens.xpBadgeBg,
                                                                            borderRadius: BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                          ),
                                                                          child: Text(
                                                                            '+$xpReward',
                                                                            style: TextStyle(
                                                                              color: tokens.xpBadgeText,
                                                                              fontWeight: FontWeight.w800,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      const SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Expanded(
                                                                        child: Text(
                                                                          row
                                                                              .habit
                                                                              .name,
                                                                          style: const TextStyle(
                                                                            fontSize:
                                                                                18,
                                                                            fontWeight:
                                                                                FontWeight.w800,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  Text(
                                                                    'Scheduled: ${row.timeLabel} • '
                                                                    'Weekly: ${row.weekCompleted}/${row.weekScheduled} completed',
                                                                    style: TextStyle(
                                                                      color: scheme
                                                                          .onSurfaceVariant,
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            SizedBox(
                                                              height: 42,
                                                              child: ElevatedButton(
                                                                onPressed: () =>
                                                                    _toggleMission(
                                                                      row,
                                                                    ),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      scheme
                                                                          .primary,
                                                                  foregroundColor:
                                                                      scheme
                                                                          .onPrimary,
                                                                  shape:
                                                                      const StadiumBorder(),
                                                                  textStyle: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                  ),
                                                                ),
                                                                child:
                                                                    const Text(
                                                                      'Complete',
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        );
                                      }),
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
                                        _completedExpanded =
                                            !_completedExpanded;
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
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'On The Horizon',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.onOpenHabits,
                                    child: const Text('View All'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (vm.upcomingRows.isEmpty)
                                _GlassCard(
                                  child: Text(
                                    'No upcoming quests.',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                ...vm.upcomingRows
                                    .take(3)
                                    .map(
                                      (row) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: _GlassCard(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 4,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                  color: scheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  color: scheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                                child: Icon(
                                                  Icons.auto_awesome_rounded,
                                                  color: scheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      row.habit.name,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      row.subtitle,
                                                      style: TextStyle(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
  const _TopBar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
        const Spacer(),
        Text(
          'TODAY',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 42,
          height: 42,
          child: OutlinedButton(
            onPressed: onRefresh,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: BorderSide(color: scheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.open_in_new_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _MiniStatLine extends StatelessWidget {
  const _MiniStatLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHigh.withValues(alpha: 0.78),
            scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.32)),
      ),
      child: child,
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
