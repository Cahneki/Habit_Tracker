import 'package:flutter/material.dart';
import 'db/app_db.dart';
import 'features/habits/habit_detail_page.dart';
import 'features/habits/habit_repository.dart';
import 'features/habits/schedule_picker.dart';

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

  @override
  void initState() {
    super.initState();
    db = AppDb();
    repo = HabitRepository(db);
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HabitsPage(repo: repo));
  }
}

class _HabitRowVm {
  const _HabitRowVm({
    required this.habit,
    required this.completedToday,
    required this.subtitle,
  });

  final Habit habit;
  final bool completedToday;
  final String subtitle;
}

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key, required this.repo});
  final HabitRepository repo;

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  late Future<List<_HabitRowVm>> _rowsFuture;

  @override
  void initState() {
    super.initState();
    _rowsFuture = _loadRows();
  }

  Future<List<_HabitRowVm>> _loadRows() async {
    final habits = await widget.repo.listHabits();

    final rows = <_HabitRowVm>[];
    for (final h in habits) {
      final stats = await widget.repo.getStreakStats(h.id);
      final schedule = _formatScheduleSummary(h.scheduleMask);
      final subtitle =
          '${h.id}\n$schedule | Streak: ${stats.current}   Best: ${stats.longest}   Total: ${stats.totalCompletions}';

      rows.add(
        _HabitRowVm(
          habit: h,
          completedToday: stats.completedToday,
          subtitle: subtitle,
        ),
      );
    }
    return rows;
  }

  Future<void> _refresh() async {
    setState(() {
      _rowsFuture = _loadRows();
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
            title: const Text('Add habit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Habit name'),
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Schedule', style: TextStyle(fontWeight: FontWeight.w600)),
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
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addHabit),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<_HabitRowVm>>(
        future: _rowsFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snap.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('No habits yet. Tap + to add one.'));
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              final habit = row.habit;

              return Material(
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HabitDetailPage(repo: widget.repo, habit: habit),
                      ),
                    );
                    await _refresh();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(habit.name, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(row.subtitle, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: row.completedToday
                                ? null
                                : () async {
                                    await widget.repo.completeHabit(habit.id);
                                    await _refresh(); // reload rows (single rebuild)
                                  },
                            child: Text(
                              row.completedToday ? 'Done' : 'Complete',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
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
