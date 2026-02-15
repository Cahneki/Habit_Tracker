import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/daily_actions/daily_free_action_model.dart';
import '../../data/daily_actions/daily_free_action_repository.dart';
import '../../data/daily_intent/daily_intent_model.dart';
import '../../data/daily_intent/daily_intent_repository.dart';
import '../../data/quests/quest_completion_model.dart';
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
import 'today_view_model.dart';
import 'widgets/daily_intent_card.dart';
import 'widgets/empty_today_panel.dart';
import 'widgets/quest_action_modal.dart';

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
    required this.completion,
    required this.timeLabel,
    required this.weekCompleted,
    required this.weekScheduled,
    required this.manualOrder,
  });

  final Habit habit;
  final StreakStats stats;
  final QuestCompletionRecord? completion;
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

class _TodayActionLogItemVm {
  const _TodayActionLogItemVm({
    required this.title,
    required this.detail,
    required this.performedAt,
  });

  final String title;
  final String detail;
  final DateTime performedAt;
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
    required this.storedPower,
    required this.scoutedToday,
    required this.freeActions,
    required this.totalCompletions,
    required this.lifetimeBossDamage,
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
  final int storedPower;
  final bool scoutedToday;
  final List<DailyFreeActionRecord> freeActions;
  final int totalCompletions;
  final int lifetimeBossDamage;
  final int weeklyDaysLeft;
  final double weeklyProgress;
}

class _TodayPageState extends State<TodayPage> {
  late Future<_HabitsDashboardVm> _dashboardFuture;
  late final TodayViewModel _todayViewModel;
  late final DailyFreeActionRepository _dailyFreeActionRepository;
  int? _lastLevel;
  late final VoidCallback _dataListener;
  late final VoidCallback _intentListener;
  _MissionSort _sort = _MissionSort.urgency;
  bool _completedExpanded = true;
  bool _intentEditorOpen = false;

  @override
  void initState() {
    super.initState();
    _dailyFreeActionRepository = DailyFreeActionRepository(widget.repo.db);
    _dashboardFuture = _loadDashboard();
    _todayViewModel = TodayViewModel(
      dailyIntentRepository: DailyIntentRepository(widget.repo.db),
      dailyFreeActionRepository: _dailyFreeActionRepository,
    );
    _todayViewModel.loadTodayState();
    _intentListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _todayViewModel.addListener(_intentListener);
    _dataListener = _refresh;
    widget.dataVersion.addListener(_dataListener);
  }

  @override
  void dispose() {
    widget.dataVersion.removeListener(_dataListener);
    _todayViewModel.removeListener(_intentListener);
    _todayViewModel.dispose();
    super.dispose();
  }

  Future<_HabitsDashboardVm> _loadDashboard() async {
    final now = DateTime.now();
    final habits = await widget.repo.listActiveHabits();
    final freeActions = await _dailyFreeActionRepository.listForDate(now);
    final dayStatuses = await widget.repo.getHabitsForDate(now);
    final statusById = {for (final s in dayStatuses) s.habit.id: s};
    final completionByHabit = await widget.repo.getCompletionRecordsForDate(
      now,
    );
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
    final allTimeCompletions = await widget.repo
        .getCompletionDaysForRangeByHabit(
          DateTime(1970, 1, 1),
          startOfLocalDay(now).add(const Duration(days: 1)),
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
    var storedPower = 0;
    var scoutedToday = false;
    var lifetimeBossDamage = 0;

    for (final action in freeActions) {
      switch (action.actionType) {
        case DailyFreeActionType.scout:
          scoutedToday = true;
          break;
        case DailyFreeActionType.train:
          xpToday += 5;
          break;
        case DailyFreeActionType.prepare:
          storedPower += 1;
          break;
      }
    }

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
        final completion = completionByHabit[habit.id];
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
            completion: completion,
            timeLabel: _timeLabel(habit.timeOfDay),
            weekCompleted: weeklyDone,
            weekScheduled: weeklyScheduled,
            manualOrder: i,
          ),
        );

        questsTotal += 1;
        if (completion != null) {
          questsDone += 1;
          xpToday += xpForHabit(habit, stats);
          if (completion.actionType == QuestActionType.attack) {
            bossDamageToday += _baseDamageForHabit(habit.baseXp);
          }
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

      final lifetimeDoneCount =
          (allTimeCompletions[habit.id] ?? const <String>{}).length;
      lifetimeBossDamage +=
          lifetimeDoneCount * _baseDamageForHabit(habit.baseXp);
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
      storedPower: storedPower,
      scoutedToday: scoutedToday,
      freeActions: freeActions,
      totalCompletions: totalCompletions,
      lifetimeBossDamage: lifetimeBossDamage,
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

  String _displayName(UserSetting settings) {
    final name = settings.profileName.trim();
    return name.isEmpty ? 'Adventurer' : name;
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
    await _todayViewModel.loadTodayState();
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

  Future<void> _completeMissionWithAction(_HabitRowVm row) async {
    if (row.completion != null) return;

    final action = await showQuestActionModal(context);
    if (!mounted || action == null) return;

    final lootSuccess = action == QuestActionType.loot
        ? Random().nextBool()
        : null;
    final completed = await widget.repo.completeHabitWithAction(
      row.habit.id,
      DateTime.now(),
      action,
      lootSuccess: lootSuccess,
    );
    if (!completed) return;

    await _refresh();
    widget.onDataChanged();
    await widget.audio.play(SoundEvent.complete);
  }

  Future<void> _performFreeAction(DailyFreeActionType action) async {
    if (!_todayViewModel.hasSelectedIntent) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a Daily Intent first.')),
      );
      return;
    }
    final performed = await _todayViewModel.performFreeAction(action);
    if (!performed) return;

    await _refresh();
    widget.onDataChanged();
    await widget.audio.play(SoundEvent.complete);
  }

  _TodayActionLogItemVm _questActionLogItem(_HabitRowVm row) {
    return _TodayActionLogItemVm(
      title: row.habit.name,
      detail:
          '${row.completion!.actionType.emoji} ${row.completion!.actionType.label}',
      performedAt: row.completion!.completedAt,
    );
  }

  _TodayActionLogItemVm _freeActionLogItem(DailyFreeActionRecord action) {
    return _TodayActionLogItemVm(
      title: action.actionType.title,
      detail: '${action.actionType.emoji} ${action.actionType.logLabel}',
      performedAt: action.performedAt,
    );
  }

  QuestUiItem _questItemForRow(_HabitRowVm row) {
    return QuestUiItem(
      habit: row.habit,
      streak: row.stats,
      isScheduledToday: true,
      isCompletedToday: row.completion != null,
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

  List<Widget> _buildTodayMissionRows(
    List<_HabitRowVm> rows, {
    required bool canComplete,
  }) {
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
                      onPressed: canComplete
                          ? () => _completeMissionWithAction(row)
                          : null,
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

  List<Widget> _buildUpcomingRows(List<_UpcomingRowVm> rows) {
    final scheme = Theme.of(context).colorScheme;

    return rows
        .map(
          (row) => InkWell(
            key: ValueKey('today-upcoming-${row.habit.id}-${row.manualOrder}'),
            onTap: () => _editHabit(row.habit),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
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
                        .where((r) => r.completion != null)
                        .toList();
                    final activeRows = vm.rows
                        .where((r) => r.completion == null)
                        .toList();
                    final actionLogs = <_TodayActionLogItemVm>[
                      ...completedRows.map(_questActionLogItem),
                      ...vm.freeActions.map(_freeActionLogItem),
                    ]..sort((a, b) => b.performedAt.compareTo(a.performedAt));
                    final lastAction = actionLogs.isEmpty
                        ? null
                        : actionLogs.first;
                    final sortedActive = _sortRows(activeRows);
                    final sortedUpcoming = List<_UpcomingRowVm>.from(
                      vm.upcomingRows,
                    )..sort((a, b) => a.manualOrder.compareTo(b.manualOrder));
                    final bossHpProgress = (1 - vm.weeklyProgress).clamp(
                      0.0,
                      1.0,
                    );
                    final intentSelected = _todayViewModel.hasSelectedIntent;
                    final selectedIntent = _todayViewModel.selectedIntentType;
                    final showDailyIntentCard =
                        !intentSelected || _intentEditorOpen;
                    final completedFreeActions = <DailyFreeActionType>{
                      ...vm.freeActions.map((action) => action.actionType),
                      ..._todayViewModel.completedFreeActions,
                    };

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
                                              _displayName(vm.settings),
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
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${vm.xp} / ${vm.xpGoal} XP',
                                                    style: TextStyle(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (selectedIntent != null) ...[
                                                  const SizedBox(width: 8),
                                                  _IntentInlineChip(
                                                    intent: selectedIntent,
                                                    onTap: () {
                                                      setState(() {
                                                        _intentEditorOpen =
                                                            !_intentEditorOpen;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ],
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
                                    bossDamageToday: vm.bossDamageToday,
                                    bestStreak: vm.bestStreak,
                                    totalCompletions: vm.totalCompletions,
                                    lifetimeBossDamage: vm.lifetimeBossDamage,
                                    level: vm.level,
                                    xp: vm.xp,
                                    xpGoal: vm.xpGoal,
                                    todayQuestItems: vm.rows
                                        .map(
                                          (row) => _DailySummaryQuestItem(
                                            name: row.habit.name,
                                            completed: row.completion != null,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 14),
                                  _WeeklyBossCard(
                                    daysLeft: vm.weeklyDaysLeft,
                                    hpProgress: bossHpProgress,
                                    todayIntent: selectedIntent,
                                    actionsTakenToday: actionLogs.length,
                                    lastAction: lastAction,
                                    scoutedToday: vm.scoutedToday,
                                    storedPower: vm.storedPower,
                                    onViewBattle: widget.onOpenBattles,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (showDailyIntentCard) ...[
                              AnimatedBuilder(
                                animation: _todayViewModel,
                                builder: (context, _) {
                                  return DailyIntentCard(
                                    loading: _todayViewModel.loadingIntent,
                                    saving: _todayViewModel.savingIntent,
                                    selection: _todayViewModel.todayIntent,
                                    pendingIntent:
                                        _todayViewModel.pendingIntent,
                                    editMode: _intentEditorOpen,
                                    error: _todayViewModel.intentError,
                                    onRetry: _todayViewModel.loadTodayIntent,
                                    onSelect: (intent) async {
                                      await _todayViewModel.selectIntent(
                                        intent,
                                      );
                                      if (!mounted) return;
                                      setState(() {
                                        _intentEditorOpen = false;
                                      });
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (!intentSelected && sortedActive.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Choose a Daily Intent to begin today\'s run.',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            Opacity(
                              opacity: intentSelected ? 1 : 0.6,
                              child: Row(
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
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: intentSelected ? 1 : 0.6,
                              child: _GlassCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    if (sortedActive.isEmpty)
                                      EmptyTodayPanel(
                                        intentSelected: intentSelected,
                                        completedActions: completedFreeActions,
                                        savingActions:
                                            _todayViewModel.savingFreeActions,
                                        onPerformAction: (action) {
                                          _performFreeAction(action);
                                        },
                                        onAddQuest: _addHabit,
                                        onEditSchedule: widget.onOpenHabits,
                                      )
                                    else
                                      ..._buildTodayMissionRows(
                                        sortedActive,
                                        canComplete: intentSelected,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (sortedUpcoming.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Up Next (${sortedUpcoming.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _GlassCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: _buildUpcomingRows(sortedUpcoming),
                                ),
                              ),
                            ],
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
                                              'Actions Taken (${actionLogs.length})',
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
                                      actionLogs.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        0,
                                        14,
                                        12,
                                      ),
                                      child: Column(
                                        children: actionLogs
                                            .map(
                                              (item) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.title,
                                                      style: TextStyle(
                                                        color: scheme.onSurface,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          item.detail,
                                                          style: TextStyle(
                                                            color: scheme
                                                                .onSurfaceVariant,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          TimeOfDay.fromDateTime(
                                                            item.performedAt,
                                                          ).format(context),
                                                          style: TextStyle(
                                                            color: scheme
                                                                .onSurfaceVariant
                                                                .withValues(
                                                                  alpha: 0.7,
                                                                ),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  if (_completedExpanded && actionLogs.isEmpty)
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
                                          'Complete a quest or take a free action.',
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

class _IntentInlineChip extends StatelessWidget {
  const _IntentInlineChip({required this.intent, required this.onTap});

  final DailyIntentType intent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(intent.icon, size: 14, color: scheme.primary),
              const SizedBox(width: 5),
              Text(
                intent.label,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyBossCard extends StatelessWidget {
  const _WeeklyBossCard({
    required this.daysLeft,
    required this.hpProgress,
    required this.todayIntent,
    required this.actionsTakenToday,
    required this.lastAction,
    required this.scoutedToday,
    required this.storedPower,
    required this.onViewBattle,
  });

  final int daysLeft;
  final double hpProgress;
  final DailyIntentType? todayIntent;
  final int actionsTakenToday;
  final _TodayActionLogItemVm? lastAction;
  final bool scoutedToday;
  final int storedPower;
  final VoidCallback onViewBattle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysLabel = daysLeft == 1 ? '1 day left' : '$daysLeft days left';
    final hpPct = (hpProgress * 100).clamp(0, 100).round();
    final statusLabel = _statusFor(hpPct);
    final canEngage = todayIntent != null;
    final ctaLabel = hpPct == 0 ? 'View Results' : 'Engage Boss';
    final threatLine = _threatCopy(actionsTakenToday, DateTime.now());
    final nextAction = _nextActionFor(todayIntent);
    final bonusLine = _bonusCopy(todayIntent);
    final lastLine = lastAction == null
        ? 'Last: None yet today'
        : 'Last: ${lastAction!.detail} (${TimeOfDay.fromDateTime(lastAction!.performedAt).format(context)})';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final card = Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 14,
            compact ? 12 : 14,
            compact ? 12 : 14,
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                scheme.surfaceContainerHigh,
                scheme.surfaceContainer,
                scheme.surfaceContainerLowest,
              ],
            ),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      center: Alignment(0.8, -0.35),
                      radius: 0.95,
                      colors: [
                        scheme.primary.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
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
                  color: scheme.primary.withValues(alpha: 0.2),
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
                          color: scheme.primaryContainer,
                        ),
                        child: Icon(
                          Icons.whatshot_rounded,
                          color: scheme.onPrimaryContainer,
                          size: compact ? 19 : 22,
                        ),
                      ),
                      SizedBox(width: compact ? 8 : 10),
                      Expanded(
                        child: Text(
                          'Encounter: Weekly Boss',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: compact ? 15 : 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        daysLabel,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  Text(
                    'Status: $statusLabel',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: compact ? 16 : 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: hpProgress,
                      minHeight: compact ? 10 : 12,
                      backgroundColor: scheme.surface,
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Text(
                    threatLine,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 12 : 13,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    'Actions taken today: $actionsTakenToday',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 13 : 14,
                    ),
                  ),
                  Text(
                    'Next action: $nextAction',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 12 : 13,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  if (storedPower > 0)
                    Text(
                      'Stored power: $storedPower',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  if (scoutedToday)
                    Text(
                      'Weakness revealed: Morning quests hit harder',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  if (storedPower > 0 || scoutedToday)
                    SizedBox(height: compact ? 6 : 8),
                  if (todayIntent != null) ...[
                    Row(
                      children: [
                        Icon(
                          todayIntent!.icon,
                          size: compact ? 14 : 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Today\'s Intent: ${todayIntent!.label}',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                    if (bonusLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        bonusLine,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 12 : 13,
                        ),
                      ),
                    ],
                  ] else
                    Text(
                      'Today\'s Intent: Not selected',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    lastLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 12 : 13,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  Tooltip(
                    message: canEngage ? '' : 'Choose a Daily Intent first.',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: canEngage
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Choose a Daily Intent first.'),
                                ),
                              );
                            },
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: canEngage ? onViewBattle : null,
                          child: Text(ctaLabel),
                        ),
                      ),
                    ),
                  ),
                  if (!canEngage) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Choose a Daily Intent first.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
        return card;
      },
    );
  }

  String _statusFor(int hpPct) {
    if (hpPct <= 0) return 'Defeated';
    if (hpPct <= 19) return 'Near Defeat';
    if (hpPct <= 49) return 'Staggering';
    if (hpPct <= 79) return 'Wounded';
    return 'Unharmed';
  }

  String _threatCopy(int actionsTakenToday, DateTime now) {
    if (actionsTakenToday == 0 && now.hour >= 18) {
      return 'Threat: Boss is gathering strength tonight';
    }
    if (actionsTakenToday == 0) {
      return 'Threat: Rewards weaken if you skip today';
    }
    return 'Threat: Maintain pressure to keep advantage';
  }

  String _nextActionFor(DailyIntentType? intent) {
    switch (intent) {
      case DailyIntentType.power:
        return 'Attack Boss';
      case DailyIntentType.growth:
        return 'Charge Power';
      case DailyIntentType.safety:
        return 'Guard';
      case DailyIntentType.loot:
        return 'Loot Roll';
      case null:
        return 'Choose Daily Intent';
    }
  }

  String? _bonusCopy(DailyIntentType? intent) {
    switch (intent) {
      case DailyIntentType.power:
        return 'Bonus: Attack focus increased';
      case DailyIntentType.growth:
        return 'Bonus: XP on resolve emphasized';
      case DailyIntentType.safety:
        return 'Bonus: Guard stance reinforced';
      case DailyIntentType.loot:
        return 'Bonus: Loot quality improved';
      case null:
        return null;
    }
  }
}

enum _StatsAnimationPhase { none, xp, streak, hp }

class _StatDescriptor {
  const _StatDescriptor({
    required this.id,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.color,
    this.hero = false,
  });

  final String id;
  final String label;
  final String tooltip;
  final IconData icon;
  final Color color;
  final bool hero;

  _StatDescriptor copyWith({String? label}) {
    return _StatDescriptor(
      id: id,
      label: label ?? this.label,
      tooltip: tooltip,
      icon: icon,
      color: color,
      hero: hero,
    );
  }
}

class _DailySummaryQuestItem {
  const _DailySummaryQuestItem({required this.name, required this.completed});

  final String name;
  final bool completed;
}

class _InlineStatsBar extends StatefulWidget {
  const _InlineStatsBar({
    required this.currentStreak,
    required this.bestStreak,
    required this.xpToday,
    required this.questsDone,
    required this.questsTotal,
    required this.bossDamageToday,
    required this.totalCompletions,
    required this.lifetimeBossDamage,
    required this.level,
    required this.xp,
    required this.xpGoal,
    required this.todayQuestItems,
  });

  final int currentStreak;
  final int bestStreak;
  final int xpToday;
  final int questsDone;
  final int questsTotal;
  final int bossDamageToday;
  final int totalCompletions;
  final int lifetimeBossDamage;
  final int level;
  final int xp;
  final int xpGoal;
  final List<_DailySummaryQuestItem> todayQuestItems;

  @override
  State<_InlineStatsBar> createState() => _InlineStatsBarState();
}

class _InlineStatsBarState extends State<_InlineStatsBar> {
  static const _xpAnimDuration = Duration(milliseconds: 180);
  static const _streakPulseDuration = Duration(milliseconds: 170);
  static const _hpFlashDuration = Duration(milliseconds: 180);

  late int _xpFrom;
  late int _xpTo;
  int _xpAnimSeed = 0;
  bool _streakPulse = false;
  bool _hpFlash = false;
  int _phaseToken = 0;
  _StatsAnimationPhase _phase = _StatsAnimationPhase.none;

  @override
  void initState() {
    super.initState();
    _xpFrom = widget.xpToday;
    _xpTo = widget.xpToday;
  }

  @override
  void didUpdateWidget(covariant _InlineStatsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final xpChanged = widget.xpToday != oldWidget.xpToday;
    final streakIncreased = widget.currentStreak > oldWidget.currentStreak;
    final hpChanged = widget.bossDamageToday != oldWidget.bossDamageToday;

    if (xpChanged) {
      _startXpAnimation(from: oldWidget.xpToday, to: widget.xpToday);
      return;
    }

    _xpFrom = widget.xpToday;
    _xpTo = widget.xpToday;

    if (streakIncreased) {
      _startStreakPulse();
      return;
    }

    if (hpChanged) {
      _startHpFlash();
    }
  }

  void _startXpAnimation({required int from, required int to}) {
    final token = ++_phaseToken;
    setState(() {
      _phase = _StatsAnimationPhase.xp;
      _xpFrom = from;
      _xpTo = to;
      _xpAnimSeed++;
      _streakPulse = false;
      _hpFlash = false;
    });

    Future.delayed(_xpAnimDuration + const Duration(milliseconds: 40), () {
      _finishAnimation(token, _StatsAnimationPhase.xp);
    });
  }

  void _startStreakPulse() {
    final token = ++_phaseToken;
    setState(() {
      _phase = _StatsAnimationPhase.streak;
      _streakPulse = true;
      _hpFlash = false;
      _xpFrom = widget.xpToday;
      _xpTo = widget.xpToday;
    });

    Future.delayed(_streakPulseDuration, () {
      if (!mounted || token != _phaseToken) return;
      setState(() {
        _streakPulse = false;
      });
    });

    Future.delayed(_streakPulseDuration + const Duration(milliseconds: 40), () {
      _finishAnimation(token, _StatsAnimationPhase.streak);
    });
  }

  void _startHpFlash() {
    final token = ++_phaseToken;
    setState(() {
      _phase = _StatsAnimationPhase.hp;
      _hpFlash = true;
      _streakPulse = false;
      _xpFrom = widget.xpToday;
      _xpTo = widget.xpToday;
    });

    Future.delayed(_hpFlashDuration, () {
      if (!mounted || token != _phaseToken) return;
      setState(() {
        _hpFlash = false;
      });
    });

    Future.delayed(_hpFlashDuration + const Duration(milliseconds: 40), () {
      _finishAnimation(token, _StatsAnimationPhase.hp);
    });
  }

  void _finishAnimation(int token, _StatsAnimationPhase phase) {
    if (!mounted || token != _phaseToken || _phase != phase) return;
    setState(() {
      _phase = _StatsAnimationPhase.none;
    });
  }

  Future<void> _openDailySummary() async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.36),
        barrierLabel: 'Daily Summary',
        transitionDuration: const Duration(milliseconds: 140),
        reverseTransitionDuration: const Duration(milliseconds: 120),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _DailySummaryScreen(
              xpToday: widget.xpToday,
              currentStreak: widget.currentStreak,
              bestStreak: widget.bestStreak,
              questsDone: widget.questsDone,
              questsTotal: widget.questsTotal,
              bossDamageToday: widget.bossDamageToday,
              totalCompletions: widget.totalCompletions,
              lifetimeBossDamage: widget.lifetimeBossDamage,
              level: widget.level,
              xp: widget.xp,
              xpGoal: widget.xpGoal,
              questItems: widget.todayQuestItems,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final scale = Tween<double>(begin: 0.98, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final xpColor =
            Color.lerp(const Color(0xFF2F9E63), scheme.primary, 0.35) ??
            scheme.primary;
        final streakColor =
            Color.lerp(const Color(0xFFB87735), scheme.tertiary, 0.5) ??
            scheme.tertiary;
        final secondaryColor = scheme.onSurfaceVariant.withValues(alpha: 0.68);
        final damageColor =
            Color.lerp(const Color(0xFF3DAF69), scheme.primary, 0.45) ??
            scheme.primary;

        final streak = _StatDescriptor(
          id: 'streak',
          label: 'Day ${widget.currentStreak} streak',
          tooltip: 'Current consecutive-day streak across scheduled quests.',
          icon: Icons.local_fire_department_rounded,
          color: streakColor,
        );

        final xp = _StatDescriptor(
          id: 'xp_today',
          label: '+${widget.xpToday} XP today',
          tooltip: 'Total XP earned from quests completed today.',
          icon: Icons.bolt_rounded,
          color: xpColor,
          hero: true,
        );

        final secondaryStats = <_StatDescriptor>[
          if (widget.questsTotal > 0)
            _StatDescriptor(
              id: 'quests_today',
              label: '${widget.questsDone} of ${widget.questsTotal} quests',
              tooltip: 'Progress across quests scheduled for today.',
              icon: Icons.task_alt_rounded,
              color: secondaryColor,
            ),
          if (widget.bossDamageToday > 0)
            _StatDescriptor(
              id: 'damage_dealt_today',
              label: '${widget.bossDamageToday} HP dealt',
              tooltip: 'Damage dealt to the boss from attack actions today.',
              icon: Icons.whatshot_rounded,
              color: damageColor,
            ),
        ];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openDailySummary,
            child: Container(
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
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrimaryStatsRow(
                    streak: streak,
                    xp: xp,
                    compact: compact,
                    streakScale: _streakPulse ? 1.06 : 1.0,
                    xpFrom: _xpFrom,
                    xpTo: _xpTo,
                    xpAnimSeed: _xpAnimSeed,
                    animateXp: _phase == _StatsAnimationPhase.xp,
                  ),
                  if (secondaryStats.isNotEmpty) ...[
                    SizedBox(height: compact ? 8 : 10),
                    _SecondaryStatsRow(
                      descriptors: secondaryStats,
                      compact: compact,
                      hpFlash: _hpFlash,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrimaryStatsRow extends StatelessWidget {
  const _PrimaryStatsRow({
    required this.streak,
    required this.xp,
    required this.compact,
    required this.streakScale,
    required this.xpFrom,
    required this.xpTo,
    required this.xpAnimSeed,
    required this.animateXp,
  });

  final _StatDescriptor streak;
  final _StatDescriptor xp;
  final bool compact;
  final double streakScale;
  final int xpFrom;
  final int xpTo;
  final int xpAnimSeed;
  final bool animateXp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _StatUnit(
              descriptor: streak,
              compact: compact,
              scale: streakScale,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              key: ValueKey<int>(xpAnimSeed),
              tween: Tween<double>(
                begin: xpFrom.toDouble(),
                end: xpTo.toDouble(),
              ),
              duration: animateXp
                  ? const Duration(milliseconds: 180)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final animated = xp.copyWith(
                  label: '+${value.round()} XP today',
                );
                return _StatUnit(descriptor: animated, compact: compact);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryStatsRow extends StatelessWidget {
  const _SecondaryStatsRow({
    required this.descriptors,
    required this.compact,
    required this.hpFlash,
  });

  final List<_StatDescriptor> descriptors;
  final bool compact;
  final bool hpFlash;

  @override
  Widget build(BuildContext context) {
    final visible = descriptors.take(2).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    if (visible.length == 1) {
      return Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStat(visible.first),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(child: SizedBox()),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildStat(visible[0]),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildStat(visible[1]),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(_StatDescriptor descriptor) {
    final highlight = hpFlash && descriptor.id == 'boss_hp_lost';
    return _StatUnit(
      descriptor: descriptor,
      compact: compact,
      backgroundColor: highlight
          ? descriptor.color.withValues(alpha: 0.18)
          : null,
    );
  }
}

class _StatUnit extends StatelessWidget {
  const _StatUnit({
    required this.descriptor,
    required this.compact,
    this.backgroundColor,
    this.scale = 1.0,
  });

  final _StatDescriptor descriptor;
  final bool compact;
  final Color? backgroundColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final uniformFontSize = compact ? 13.0 : 14.0;
    final textStyle = TextStyle(
      color: descriptor.color,
      fontSize: uniformFontSize,
      fontWeight: descriptor.hero ? FontWeight.w800 : FontWeight.w700,
      height: 1.15,
    );
    final iconSize = compact ? 15.0 : 16.0;

    return AnimatedScale(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      scale: scale,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(descriptor.hero ? 14 : 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(descriptor.icon, size: iconSize, color: descriptor.color),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(descriptor.label, maxLines: 1, style: textStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SummaryRange { today, lifetime }

class _DailySummaryScreen extends StatefulWidget {
  const _DailySummaryScreen({
    required this.xpToday,
    required this.currentStreak,
    required this.bestStreak,
    required this.questsDone,
    required this.questsTotal,
    required this.bossDamageToday,
    required this.totalCompletions,
    required this.lifetimeBossDamage,
    required this.level,
    required this.xp,
    required this.xpGoal,
    required this.questItems,
  });

  final int xpToday;
  final int currentStreak;
  final int bestStreak;
  final int questsDone;
  final int questsTotal;
  final int bossDamageToday;
  final int totalCompletions;
  final int lifetimeBossDamage;
  final int level;
  final int xp;
  final int xpGoal;
  final List<_DailySummaryQuestItem> questItems;

  @override
  State<_DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<_DailySummaryScreen> {
  _SummaryRange _range = _SummaryRange.today;

  void _toggleRange() {
    setState(() {
      _range = _range == _SummaryRange.today
          ? _SummaryRange.lifetime
          : _SummaryRange.today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLifetime = _range == _SummaryRange.lifetime;
    final scheme = Theme.of(context).colorScheme;
    final progressValue = widget.xpGoal == 0
        ? 0.0
        : (widget.xp / widget.xpGoal).clamp(0.0, 1.0);
    final xpColor =
        Color.lerp(const Color(0xFF2F9E63), scheme.primary, 0.35) ??
        scheme.primary;
    final streakColor =
        Color.lerp(const Color(0xFFB87735), scheme.tertiary, 0.5) ??
        scheme.tertiary;
    final checklistDone =
        Color.lerp(const Color(0xFF64B38F), scheme.primary, 0.4) ??
        scheme.primary;
    final checklistTodo = scheme.outline.withValues(alpha: 0.65);
    final cardColor = scheme.brightness == Brightness.dark
        ? const Color(0xFF111418)
        : const Color(0xFFFCFCFE);
    final summaryTitle = isLifetime ? 'Lifetime Summary' : 'Daily Summary';
    final rangeLabel = isLifetime ? 'Lifetime' : 'Today';
    final streakLabel = isLifetime
        ? 'Best ${widget.bestStreak} streak'
        : 'Day ${widget.currentStreak} streak';
    final xpHeadline = isLifetime
        ? '+${widget.xp} XP gained lifetime'
        : '+${widget.xpToday} XP gained today';
    final impactHeading = isLifetime ? 'Lifetime Quests' : "Today's Quests";
    final impactLine = isLifetime
        ? '${widget.totalCompletions} total quests completed'
        : '${widget.questsDone} of ${widget.questsTotal} quests completed';
    final dealtDamage = isLifetime
        ? widget.lifetimeBossDamage
        : widget.bossDamageToday;
    final showImpactLine = isLifetime || widget.questsTotal > 0;
    final showQuestList = !isLifetime && widget.questItems.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 36,
                      spreadRadius: 2,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    summaryTitle,
                                    style: TextStyle(
                                      color: scheme.onSurface,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: _toggleRange,
                                    style: TextButton.styleFrom(
                                      foregroundColor: scheme.onSurfaceVariant,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          rangeLabel,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.swap_horiz_rounded,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: scheme.primary.withValues(
                                          alpha: 0.55,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.hiking_rounded,
                                      color: scheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'LVL ${widget.level}',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  14,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: scheme.outline.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: streakColor.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_fire_department_rounded,
                                            color: streakColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            streakLabel,
                                            style: TextStyle(
                                              color: scheme.onSurface,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.bolt_rounded,
                                          color: xpColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            xpHeadline,
                                            style: TextStyle(
                                              color: scheme.onSurface,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: progressValue,
                                        minHeight: 14,
                                        backgroundColor:
                                            scheme.surfaceContainerHighest,
                                        color: xpColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${widget.xp} / ${widget.xpGoal}',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                impactHeading,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (showImpactLine)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: scheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        impactLine,
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (showQuestList) ...[
                                const SizedBox(height: 10),
                                ...widget.questItems.map(
                                  (item) => _SummaryQuestLine(
                                    title: item.name,
                                    done: item.completed,
                                    doneColor: checklistDone,
                                    todoColor: checklistTodo,
                                  ),
                                ),
                              ],
                              if (dealtDamage != 0) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Boss Damage Dealt',
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.whatshot_rounded,
                                      color: streakColor,
                                      size: 26,
                                    ),
                                    const SizedBox(width: 10),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$dealtDamage HP',
                                            style: TextStyle(
                                              color: streakColor,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const TextSpan(text: ' dealt'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.7),
                          border: Border(
                            top: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [
                                scheme.primary.withValues(alpha: 0.92),
                                scheme.primary.withValues(alpha: 0.72),
                              ],
                            ),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Continue'),
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
      ),
    );
  }
}

class _SummaryQuestLine extends StatelessWidget {
  const _SummaryQuestLine({
    required this.title,
    required this.done,
    required this.doneColor,
    required this.todoColor,
  });

  final String title;
  final bool done;
  final Color doneColor;
  final Color todoColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: done
                      ? doneColor.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: done ? doneColor : todoColor,
                    width: 2,
                  ),
                ),
                child: done
                    ? Icon(Icons.check_rounded, color: doneColor, size: 16)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 17,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: scheme.outline.withValues(alpha: 0.18), height: 1),
        ],
      ),
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
