import 'package:flutter/material.dart';
import 'db/app_db.dart';
import 'features/avatar/avatar_repository.dart';
import 'features/habits/habit_detail_page.dart';
import 'features/habits/habit_repository.dart';
import 'features/habits/schedule_picker.dart';
import 'features/settings/settings_repository.dart';
import 'services/audio_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppDb db;
  late final HabitRepository repo;
  late final SettingsRepository settingsRepo;
  late final AvatarRepository avatarRepo;
  late final AudioService audio;

  @override
  void initState() {
    super.initState();
    db = AppDb();
    repo = HabitRepository(db);
    settingsRepo = SettingsRepository(db);
    avatarRepo = AvatarRepository(db);
    audio = AudioService(settingsRepo);
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: HomeScaffold(
        repo: repo,
        settingsRepo: settingsRepo,
        avatarRepo: avatarRepo,
        audio: audio,
      ),
    );
  }
}

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({
    super.key,
    required this.repo,
    required this.settingsRepo,
    required this.avatarRepo,
    required this.audio,
  });

  final HabitRepository repo;
  final SettingsRepository settingsRepo;
  final AvatarRepository avatarRepo;
  final AudioService audio;

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _index = 0;

  void _setIndex(int next) {
    setState(() {
      _index = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(
        repo: widget.repo,
        audio: widget.audio,
        onOpenHabits: () => _setIndex(1),
      ),
      HabitsManagePage(repo: widget.repo),
      AvatarPage(
        repo: widget.repo,
        avatarRepo: widget.avatarRepo,
        audio: widget.audio,
      ),
      StatsPage(repo: widget.repo),
      SettingsPage(
        settingsRepo: widget.settingsRepo,
        audio: widget.audio,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _setIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: const Color(0xFFB5B0A7),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_rounded),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.backpack_rounded),
            label: 'Avatar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_rounded),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
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
    required this.xp,
    required this.xpGoal,
    required this.xpToNext,
    required this.gold,
    required this.currentStreak,
    required this.bestStreak,
    required this.level,
  });

  final List<_HabitRowVm> rows;
  final int xp;
  final int xpGoal;
  final int xpToNext;
  final int gold;
  final int currentStreak;
  final int bestStreak;
  final int level;
}

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.repo,
    required this.audio,
    required this.onOpenHabits,
  });
  final HabitRepository repo;
  final AudioService audio;
  final VoidCallback onOpenHabits;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late Future<_HabitsDashboardVm> _dashboardFuture;
  int? _lastLevel;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_HabitsDashboardVm> _loadDashboard() async {
    final habits = await widget.repo.listActiveHabits();
    final dayStatuses = await widget.repo.getHabitsForDate(DateTime.now());
    final statusById = {for (final s in dayStatuses) s.habit.id: s};

    final rows = <_HabitRowVm>[];
    var bestCurrent = 0;
    var bestStreak = 0;

    for (final h in habits) {
      final stats = await widget.repo.getStreakStats(h.id);
      if (stats.current > bestCurrent) bestCurrent = stats.current;
      if (stats.longest > bestStreak) bestStreak = stats.longest;

      final schedule = _formatScheduleSummary(h.scheduleMask);
      final subtitle = '$schedule · Streak ${stats.current}d';

      final status = statusById[h.id] ??
          HabitDayStatus(habit: h, scheduled: false, completed: false);
      if (!status.scheduled) continue;
      rows.add(_HabitRowVm(habit: h, stats: stats, subtitle: subtitle));
    }

    final totalCompletions = await widget.repo.getTotalCompletions();
    final xp = totalCompletions * 20;
    final xpGoal = _xpGoalFor(xp);
    final gold = totalCompletions * 10 + 250;
    final level = _levelForXp(xp);

    if (_lastLevel != null && level > _lastLevel!) {
      widget.audio.play(SoundEvent.levelUp);
    }
    _lastLevel = level;

    return _HabitsDashboardVm(
      rows: rows,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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

                    return Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: _refresh,
                          color: AppTheme.primary,
                          backgroundColor: Colors.white,
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
                                  rankTitle: _rankTitleForLevel(vm.level),
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
                                        xpReward: _xpForHabit(row.habit, row.stats),
                                        statusLabel: _statusLabelFor(row.habit, row.stats),
                                        urgent: _isUrgent(row.habit, row.stats),
                                        onComplete: () async {
                                          final wasCompleted =
                                              row.stats.completedToday;
                                          await widget.repo.toggleCompletionForDay(
                                            row.habit.id,
                                            DateTime.now(),
                                          );
                                          await _refresh();
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
                                              ),
                                            ),
                                          );
                                          await _refresh();
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 86,
                          child: _QuestFab(onPressed: _addHabit),
                        ),
                      ],
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

class HabitsManagePage extends StatefulWidget {
  const HabitsManagePage({super.key, required this.repo});
  final HabitRepository repo;

  @override
  State<HabitsManagePage> createState() => _HabitsManagePageState();
}

class _HabitsManageVm {
  const _HabitsManageVm({required this.active, required this.archived});
  final List<Habit> active;
  final List<Habit> archived;
}

class _HabitEditorResult {
  const _HabitEditorResult({required this.name, required this.days});
  final String name;
  final Set<int> days;
}

class _HabitsManagePageState extends State<HabitsManagePage> {
  late Future<_HabitsManageVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HabitsManageVm> _load() async {
    final active = await widget.repo.listActiveHabits();
    final archived = await widget.repo.listArchivedHabits();
    return _HabitsManageVm(active: active, archived: archived);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<_HabitEditorResult?> _showHabitEditor({Habit? habit}) {
    final controller = TextEditingController(text: habit?.name ?? '');
    final selectedDays = habit == null
        ? <int>{}
        : ScheduleMask.daysFromMask(habit.scheduleMask);
    final allowEmpty = habit != null;

    return showDialog<_HabitEditorResult>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final canSave =
              controller.text.trim().isNotEmpty && (allowEmpty || selectedDays.isNotEmpty);
          return AlertDialog(
            title: Text(habit == null ? 'Add habit' : 'Edit habit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Habit name'),
                  autofocus: habit == null,
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
                    allowEmpty ? 'No scheduled days' : 'Pick at least one day',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: canSave
                    ? () {
                        Navigator.pop(
                          context,
                          _HabitEditorResult(
                            name: controller.text.trim(),
                            days: Set<int>.from(selectedDays),
                          ),
                        );
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createHabit() async {
    final result = await _showHabitEditor();
    if (result == null) return;
    if (result.name.isEmpty || result.days.isEmpty) return;

    final id = 'h-${DateTime.now().millisecondsSinceEpoch}';
    final scheduleMask = ScheduleMask.maskFromDays(result.days);
    await widget.repo.createHabit(
      id: id,
      name: result.name,
      scheduleMask: scheduleMask,
    );
    _refresh();
  }

  Future<void> _editHabit(Habit habit) async {
    final result = await _showHabitEditor(habit: habit);
    if (result == null) return;

    if (result.name.trim() != habit.name) {
      await widget.repo.renameHabit(habit.id, result.name.trim());
    }
    final nextMask = ScheduleMask.maskFromDays(result.days);
    if (nextMask != habit.scheduleMask) {
      await widget.repo.updateScheduleMask(habit.id, nextMask);
    }
    _refresh();
  }

  Future<void> _archiveHabit(Habit habit) async {
    await widget.repo.archiveHabit(habit.id);
    _refresh();
  }

  Future<void> _restoreHabit(Habit habit) async {
    await widget.repo.unarchiveHabit(habit.id);
    _refresh();
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text('This removes the habit and its history.'),
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
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createHabit,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.ink,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<_HabitsManageVm>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = snap.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              const Text(
                'Active',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (vm.active.isEmpty)
                const Text('No active habits.')
              else
                ...vm.active.map(
                  (habit) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(habit.name),
                      subtitle: Text(_formatScheduleSummary(habit.scheduleMask)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () => _editHabit(habit),
                          ),
                          IconButton(
                            tooltip: 'Archive',
                            icon: const Icon(Icons.archive_rounded),
                            onPressed: () => _archiveHabit(habit),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Archived',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (vm.archived.isEmpty)
                const Text('No archived habits.')
              else
                ...vm.archived.map(
                  (habit) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(habit.name),
                      subtitle: Text(_formatScheduleSummary(habit.scheduleMask)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Restore',
                            icon: const Icon(Icons.unarchive_rounded),
                            onPressed: () => _restoreHabit(habit),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_rounded),
                            onPressed: () => _deleteHabit(habit),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.repo});
  final HabitRepository repo;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _CompletionRate {
  const _CompletionRate({required this.completed, required this.scheduled});
  final int completed;
  final int scheduled;
}

class _StatsVm {
  const _StatsVm({
    required this.totalCompletions,
    required this.xp,
    required this.level,
    required this.currentStreak,
    required this.bestStreak,
    required this.week,
    required this.month,
  });

  final int totalCompletions;
  final int xp;
  final int level;
  final int currentStreak;
  final int bestStreak;
  final _CompletionRate week;
  final _CompletionRate month;
}

class _StatsPageState extends State<StatsPage> {
  late Future<_StatsVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  bool _isScheduled(DateTime date, int? scheduleMask) {
    if (scheduleMask == null) return true;
    if (scheduleMask == 0) return false;
    final bit = 1 << (date.weekday - 1);
    return (scheduleMask & bit) != 0;
  }

  String _localDay(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<_CompletionRate> _completionRate(
    List<Habit> habits,
    DateTime start,
    DateTime endExclusive,
  ) async {
    var scheduled = 0;
    var completed = 0;

    for (final habit in habits) {
      final completedDays = await widget.repo.getCompletionDaysForRange(
        habit.id,
        start,
        endExclusive,
      );
      for (var d = start;
          d.isBefore(endExclusive);
          d = d.add(const Duration(days: 1))) {
        if (!_isScheduled(d, habit.scheduleMask)) continue;
        scheduled += 1;
        if (completedDays.contains(_localDay(d))) {
          completed += 1;
        }
      }
    }

    return _CompletionRate(completed: completed, scheduled: scheduled);
  }

  Future<_StatsVm> _load() async {
    final habits = await widget.repo.listActiveHabits();
    var bestCurrent = 0;
    var bestStreak = 0;

    for (final h in habits) {
      final stats = await widget.repo.getStreakStats(h.id);
      if (stats.current > bestCurrent) bestCurrent = stats.current;
      if (stats.longest > bestStreak) bestStreak = stats.longest;
    }

    final totalCompletions = await widget.repo.getTotalCompletions();
    final xp = totalCompletions * 20;
    final level = _levelForXp(xp);

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final week = await _completionRate(habits, weekStart, weekEnd);
    final month = await _completionRate(habits, monthStart, monthEnd);

    return _StatsVm(
      totalCompletions: totalCompletions,
      xp: xp,
      level: level,
      currentStreak: bestCurrent,
      bestStreak: bestStreak,
      week: week,
      month: month,
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _rateCard(String label, _CompletionRate rate) {
    final pct =
        rate.scheduled == 0 ? 0 : ((rate.completed / rate.scheduled) * 100).round();
    final density = rate.scheduled == 0 ? 0.0 : rate.completed / rate.scheduled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('${rate.completed}/${rate.scheduled} ($pct%)'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: density,
              minHeight: 8,
              backgroundColor: AppTheme.parchment,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Stats')),
      body: FutureBuilder<_StatsVm>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _statCard('Level', '${vm.level}')),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('XP', '${vm.xp}')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statCard('Current Streak', '${vm.currentStreak}d')),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Best Streak', '${vm.bestStreak}d')),
                ],
              ),
              const SizedBox(height: 12),
              _statCard('Total Completions', '${vm.totalCompletions}'),
              const SizedBox(height: 12),
              _rateCard('Completion Rate (This Week)', vm.week),
              const SizedBox(height: 12),
              _rateCard('Completion Rate (This Month)', vm.month),
            ],
          );
        },
      ),
    );
  }
}

class AvatarPage extends StatefulWidget {
  const AvatarPage({
    super.key,
    required this.repo,
    required this.avatarRepo,
    required this.audio,
  });

  final HabitRepository repo;
  final AvatarRepository avatarRepo;
  final AudioService audio;

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarVm {
  const _AvatarVm({
    required this.level,
    required this.equipped,
  });

  final int level;
  final Map<String, String> equipped;
}

class _AvatarPageState extends State<AvatarPage> {
  late Future<_AvatarVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AvatarVm> _load() async {
    final total = await widget.repo.getTotalCompletions();
    final level = _levelForXp(total * 20);
    final equipped = await widget.avatarRepo.getEquipped();
    return _AvatarVm(level: level, equipped: equipped);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _equip(CosmeticItem item) async {
    await widget.avatarRepo.equip(item.slot, item.id);
    await widget.audio.play(SoundEvent.equip);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Avatar')),
      body: FutureBuilder<_AvatarVm>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = snap.data!;
          final equipped = vm.equipped;
          final catalog = AvatarRepository.catalog;
          final namesById = {for (final item in catalog) item.id: item.name};
          final bySlot = <String, List<CosmeticItem>>{};
          for (final item in catalog) {
            bySlot.putIfAbsent(item.slot, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppTheme.parchment,
                      child: const Icon(Icons.person_rounded, size: 46),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${vm.level}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Head: ${namesById[equipped[AvatarRepository.slotHead]] ?? 'None'}',
                          ),
                          Text(
                            'Body: ${namesById[equipped[AvatarRepository.slotBody]] ?? 'None'}',
                          ),
                          Text(
                            'Accessory: ${namesById[equipped[AvatarRepository.slotAccessory]] ?? 'None'}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...bySlot.entries.map((entry) {
                final slot = entry.key;
                final items = entry.value;
                final slotLabel = slot[0].toUpperCase() + slot.substring(1);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slotLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final unlocked = vm.level >= item.unlockLevel;
                      final isEquipped = equipped[slot] == item.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(item.icon, color: item.color),
                          title: Text(item.name),
                          subtitle: Text('Unlocks at level ${item.unlockLevel}'),
                          trailing: unlocked
                              ? ElevatedButton(
                                  onPressed: isEquipped ? null : () => _equip(item),
                                  child: Text(isEquipped ? 'Equipped' : 'Equip'),
                                )
                              : const Text('Locked'),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settingsRepo,
    required this.audio,
  });

  final SettingsRepository settingsRepo;
  final AudioService audio;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<UserSetting> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.settingsRepo.getSettings();
  }

  Future<void> _updateSoundEnabled(bool enabled) async {
    await widget.audio.setSoundEnabled(enabled);
    setState(() {
      _future = widget.settingsRepo.getSettings();
    });
  }

  Future<void> _updateSoundPack(String packId) async {
    await widget.audio.setSoundPack(packId);
    setState(() {
      _future = widget.settingsRepo.getSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<UserSetting>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Sound effects'),
                value: settings.soundEnabled,
                onChanged: _updateSoundEnabled,
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Sound pack'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.soundPackId,
                    isExpanded: true,
                    items: AudioService.packs
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateSoundPack(value);
                    },
                  ),
                ),
              ),
            ],
          );
        },
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
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary, width: 2),
          ),
          child: const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.imgur.com/4Z7wG2x.png'),
            backgroundColor: AppTheme.parchment,
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
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  'LVL $level',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFD54A),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: Color(0xFF7B5B00),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rankSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
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
    final progress = xpGoal == 0 ? 0.0 : (xp / xpGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFE7D5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
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
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$xp / $xpGoal XP',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
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
              backgroundColor: const Color(0xFFF1EEE6),
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$xpToNext XP TO LEVEL ${_levelForXp(xp) + 1}',
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: AppTheme.muted,
              ),
            ),
          ),
        ],
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
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Gold',
            value: gold.toString(),
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFFD6A000),
            background: AppTheme.goldCard,
            borderColor: const Color(0xFFF0D9A8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Streak',
            value: '$streak Days',
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFDC4A4A),
            background: AppTheme.streakCard,
            borderColor: const Color(0xFFF4CFCF),
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
    required this.background,
    required this.borderColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
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
                  color: iconColor,
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
              color: AppTheme.ink,
            ),
          ),
        ],
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppTheme.primary,
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
    required this.onTap,
  });

  final _HabitRowVm row;
  final int xpReward;
  final String statusLabel;
  final bool urgent;
  final VoidCallback? onComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForHabit(row.habit.name);
    final iconColor = _iconColorForHabit(row.habit.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.cardBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.cardShadow,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      topRight: Radius.circular(20),
                    ),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Text(
                    '+$xpReward XP',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B7B4E),
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
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.cardBorder),
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.wood,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              row.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8B6B5D),
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
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF8A3D),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Color(0xFFB4551E),
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: Color(0xFF8B6B5D)),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B6B5D),
                          ),
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.wood,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppTheme.wood.withValues(alpha: 0.35),
                            disabledForegroundColor: Colors.white70,
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
                          child:
                              Text(row.stats.completedToday ? 'Undo' : 'Complete'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFE7D5)),
      ),
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
            style: const TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.wood,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('Create Quest'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestFab extends StatelessWidget {
  const _QuestFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      shape: const CircleBorder(),
      elevation: 10,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: const Icon(Icons.add, size: 32, color: AppTheme.ink),
        ),
      ),
    );
  }
}

class _QuestBottomNav extends StatelessWidget {
  const _QuestBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0x1A111814)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _BottomNavItem(icon: Icons.assignment_rounded, label: 'Board', active: true),
          _BottomNavItem(icon: Icons.backpack_rounded, label: 'Loot', active: false),
          _BottomNavItem(icon: Icons.leaderboard_rounded, label: 'Ranks', active: false),
          _BottomNavItem(icon: Icons.storefront_rounded, label: 'Shop', active: false),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.primary : const Color(0xFFB5B0A7);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: AppTheme.ink),
        ),
      ),
    );
  }
}

int _xpGoalFor(int xp) {
  if (xp <= 0) return 1000;
  return ((xp / 1000).floor() + 1) * 1000;
}

int _levelForXp(int xp) {
  return (xp ~/ 1000) + 1;
}

String _rankTitleForLevel(int level) {
  if (level < 5) return 'Wanderer';
  if (level < 10) return 'Paladin Apprentice';
  if (level < 15) return 'Knight Adept';
  if (level < 20) return 'Paladin Captain';
  return 'Legendary Hero';
}

int _xpForHabit(Habit habit, StreakStats stats) {
  var base = 20;
  if (_isDailySchedule(habit.scheduleMask)) base += 10;
  base += (stats.current ~/ 5) * 5;
  return base.clamp(20, 60);
}

bool _isDailySchedule(int? mask) {
  return mask == null || mask == 0x7f;
}

String _statusLabelFor(Habit habit, StreakStats stats) {
  if (stats.completedToday) return 'Completed';
  if (_isDailySchedule(habit.scheduleMask)) return 'Daily Reset';
  final schedule = _formatScheduleSummary(habit.scheduleMask);
  return schedule.replaceFirst('Schedule: ', '');
}

bool _isUrgent(Habit habit, StreakStats stats) {
  if (stats.completedToday) return false;
  return stats.current == 0;
}

IconData _iconForHabit(String name) {
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

Color _iconColorForHabit(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('water') || lower.contains('hydrate')) {
    return const Color(0xFF2B8CFF);
  }
  if (lower.contains('read') || lower.contains('book')) {
    return const Color(0xFFB35C00);
  }
  if (lower.contains('sleep')) return const Color(0xFF6C4BB5);
  if (lower.contains('run') || lower.contains('cardio')) {
    return const Color(0xFF1B9B6F);
  }
  if (lower.contains('lift') || lower.contains('gym') || lower.contains('workout')) {
    return const Color(0xFF8B5E34);
  }
  return const Color(0xFF4A2C2A);
}

String _formatScheduleSummary(int? mask) {
  if (mask == null) return 'Schedule: daily';
  if (mask == 0) return 'Schedule: none';
  if (mask == 0x7f) return 'Schedule: daily';

  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final days = ScheduleMask.daysFromMask(mask).toList()..sort();
  final short = days.map((i) => labels[i]).join(' ');
  return 'Schedule: $short';
}
