import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../shared/local_day.dart';
import '../../shared/xp_utils.dart';
import '../../theme/app_theme.dart';
import '../habits/habit_repository.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({
    super.key,
    required this.repo,
    required this.dataVersion,
    required this.onDataChanged,
  });
  final HabitRepository repo;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;

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
  late final VoidCallback _dataListener;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _dataListener = _refresh;
    widget.dataVersion.addListener(_dataListener);
  }

  @override
  void dispose() {
    widget.dataVersion.removeListener(_dataListener);
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  bool _isScheduled(DateTime date, int? scheduleMask) {
    if (scheduleMask == null) return true;
    if (scheduleMask == 0) return false;
    final bit = 1 << (date.weekday - 1);
    return (scheduleMask & bit) != 0;
  }

  _CompletionRate _completionRate(
    List<Habit> habits,
    DateTime start,
    DateTime endExclusive,
    Map<String, Set<String>> completionsByHabit,
  ) {
    var scheduled = 0;
    var completed = 0;

    for (final habit in habits) {
      final completedDays = completionsByHabit[habit.id] ?? const <String>{};
      for (var d = start;
          d.isBefore(endExclusive);
          d = d.add(const Duration(days: 1))) {
        if (!_isScheduled(d, habit.scheduleMask)) continue;
        scheduled += 1;
        if (completedDays.contains(localDay(d))) {
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
    final xp = await widget.repo.computeTotalXp();
    final level = levelForXp(xp);

    final now = DateTime.now();
    final todayStart = startOfLocalDay(now);
    final weekStart =
        todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final monthStart = startOfLocalDay(DateTime(now.year, now.month, 1));
    final monthEnd = startOfLocalDay(DateTime(now.year, now.month + 1, 1));

    final habitIds = habits.map((h) => h.id).toList();
    final weekCompletions =
        await widget.repo.getCompletionDaysForRangeByHabit(
      weekStart,
      weekEnd,
      habitIds: habitIds,
    );
    final monthCompletions =
        await widget.repo.getCompletionDaysForRangeByHabit(
      monthStart,
      monthEnd,
      habitIds: habitIds,
    );

    final week = _completionRate(habits, weekStart, weekEnd, weekCompletions);
    final month = _completionRate(habits, monthStart, monthEnd, monthCompletions);

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
