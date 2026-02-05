import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../theme/app_theme.dart';
import 'habit_repository.dart';
import 'schedule_picker.dart';

class HabitDetailPage extends StatefulWidget {
  const HabitDetailPage({super.key, required this.repo, required this.habit});

  final HabitRepository repo;
  final Habit habit;

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  late DateTime visibleMonth;
  int? scheduleMask;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    visibleMonth = DateTime(now.year, now.month, 1);
    scheduleMask = widget.habit.scheduleMask;
  }

  Future<void> _complete() async {
    await widget.repo.completeHabit(widget.habit.id);
    setState(() {});
  }

  Future<void> _toggleCompletionForDay(DateTime day) async {
    await widget.repo.toggleCompletionForDay(widget.habit.id, day);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _updateSchedule(Set<int> days) async {
    final mask = ScheduleMask.maskFromDays(days);
    setState(() {
      scheduleMask = mask;
    });
    await widget.repo.updateScheduleMask(widget.habit.id, mask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(widget.habit.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<StreakStats>(
            future: widget.repo.getStreakStats(widget.habit.id),
            builder: (_, snap) {
              final s = snap.data;
              if (s == null) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(minHeight: 6),
                );
              }
              final days = ScheduleMask.daysFromMask(scheduleMask);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.cardBorder),
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
                        _MiniStat(label: 'Current', value: '${s.current}'),
                        const SizedBox(width: 12),
                        _MiniStat(label: 'Best', value: '${s.longest}'),
                        const SizedBox(width: 12),
                        _MiniStat(label: 'Total', value: '${s.totalCompletions}'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Schedule',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    SchedulePicker(activeDays: days, onChanged: _updateSchedule),
                    if (days.isEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Pick at least one day',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: s.completedToday ? null : _complete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.wood,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.wood.withValues(alpha: 0.35),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        child: Text(
                          s.completedToday ? 'Completed today' : 'Complete today',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: _CalendarHistory(
              repo: widget.repo,
              habitId: widget.habit.id,
              month: visibleMonth,
              scheduleMask: scheduleMask,
              onToggleDay: _toggleCompletionForDay,
              onPrev: () => setState(() {
                visibleMonth = DateTime(visibleMonth.year, visibleMonth.month - 1, 1);
              }),
              onNext: () => setState(() {
                visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 1);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.parchment,
          borderRadius: BorderRadius.circular(14),
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
                letterSpacing: 1,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarHistory extends StatelessWidget {
  const _CalendarHistory({
    required this.repo,
    required this.habitId,
    required this.month,
    required this.scheduleMask,
    required this.onToggleDay,
    required this.onPrev,
    required this.onNext,
  });

  final HabitRepository repo;
  final String habitId;
  final DateTime month;
  final int? scheduleMask;
  final Future<void> Function(DateTime date) onToggleDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final title = '${_monthName(month.month)} ${month.year}';

    return FutureBuilder<Set<String>>(
      future: repo.getCompletionDaysForMonth(habitId, month),
      builder: (_, snap) {
        final completed = snap.data ?? <String>{};
        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
        final allDaysScheduled = scheduleMask == null;
        int scheduledDays = 0;
        int completedScheduled = 0;

        bool isScheduled(DateTime date) {
          if (allDaysScheduled) return true;
          if (scheduleMask == 0) return false;
          final bit = 1 << (date.weekday - 1); // Mon=1 .. Sun=7
          return (scheduleMask! & bit) != 0;
        }

        String localDay(DateTime dt) {
          final y = dt.year.toString().padLeft(4, '0');
          final m = dt.month.toString().padLeft(2, '0');
          final d = dt.day.toString().padLeft(2, '0');
          return '$y-$m-$d';
        }

        for (var day = 1; day <= daysInMonth; day++) {
          final date = DateTime(month.year, month.month, day);
          if (!isScheduled(date)) continue;
          scheduledDays += 1;
          if (completed.contains(localDay(date))) {
            completedScheduled += 1;
          }
        }

        final density = scheduledDays == 0 ? 0.0 : completedScheduled / scheduledDays;
        final pct = (density * 100).round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('XP (this month)', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$completedScheduled/$scheduledDays ($pct%)'),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: density,
                minHeight: 8,
                backgroundColor: AppTheme.parchment,
                color: AppTheme.primary,
              ),
            ),
            if (scheduledDays == 0) ...[
              const SizedBox(height: 6),
              Text(
                'No scheduled days',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Center(
                    child: Text(title, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 8),

            // Key fix: bounded height for the grid (no unbounded constraints).
            AspectRatio(
              aspectRatio: 1.1,
              child: _MonthGrid(
                month: month,
                completedLocalDays: completed,
                scheduleMask: scheduleMask,
                onToggleDay: onToggleDay,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.completedLocalDays,
    required this.scheduleMask,
    required this.onToggleDay,
  });

  final DateTime month; // first day of month
  final Set<String> completedLocalDays;
  final int? scheduleMask;
  final Future<void> Function(DateTime date) onToggleDay;

  String _localDay(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Monday = 0, ... Sunday = 6
    final firstWeekdayIndex = (first.weekday + 6) % 7;

    final totalCells = ((firstWeekdayIndex + daysInMonth + 6) ~/ 7) * 7;

    bool isScheduled(DateTime date) {
      if (scheduleMask == null) return true;
      if (scheduleMask == 0) return false;
      final bit = 1 << (date.weekday - 1); // Mon=1 .. Sun=7
      return (scheduleMask! & bit) != 0;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _Dow('M'),
            _Dow('T'),
            _Dow('W'),
            _Dow('T'),
            _Dow('F'),
            _Dow('S'),
            _Dow('S'),
          ],
        ),
        const SizedBox(height: 8),

        // No Expanded here. The parent AspectRatio provides bounded height.
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: totalCells,
            itemBuilder: (_, idx) {
              final dayNum = idx - firstWeekdayIndex + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(month.year, month.month, dayNum);
              final key = _localDay(date);
              final done = completedLocalDays.contains(key);
              final scheduled = isScheduled(date);
              final labelColor = scheduled
                  ? AppTheme.ink
                  : AppTheme.muted.withValues(alpha: 0.55);
              final borderColor = scheduled
                  ? AppTheme.cardBorder
                  : AppTheme.cardBorder.withValues(alpha: 0.45);

              return Material(
                color:
                    done ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async => onToggleDay(date),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      dayNum.toString(),
                      style: TextStyle(
                        color: labelColor,
                        fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Dow extends StatelessWidget {
  const _Dow(this.t);
  final String t;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Center(
        child: Text(
          t,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

String _monthName(int m) {
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return names[m - 1];
}
