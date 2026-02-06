import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../shared/habit_utils.dart';
import 'habit_repository.dart';
import 'schedule_picker.dart';

class HabitsManagePage extends StatefulWidget {
  const HabitsManagePage({
    super.key,
    required this.repo,
    required this.dataVersion,
    required this.onDataChanged,
  });
  final HabitRepository repo;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;

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
    widget.onDataChanged();
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
    widget.onDataChanged();
  }

  Future<void> _archiveHabit(Habit habit) async {
    await widget.repo.archiveHabit(habit.id);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _restoreHabit(Habit habit) async {
    await widget.repo.unarchiveHabit(habit.id);
    _refresh();
    widget.onDataChanged();
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
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-habits',
        onPressed: _createHabit,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
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
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No active habits yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to add your first habit.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _createHabit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              shape: const StadiumBorder(),
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            child: const Text('Add Habit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...vm.active.map(
                  (habit) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(habit.name),
                      subtitle: Text(formatScheduleSummary(habit.scheduleMask)),
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
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No archived habits.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...vm.archived.map(
                  (habit) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(habit.name),
                      subtitle: Text(formatScheduleSummary(habit.scheduleMask)),
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
