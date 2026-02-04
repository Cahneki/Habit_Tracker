import 'package:drift/drift.dart';
import '../../db/app_db.dart';

class HabitRepository {
  HabitRepository(this.db);
  final AppDb db;

  String _localDay(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> seedOneHabitIfEmpty() async {
    final countExp = db.habits.id.count();
    final row =
        await (db.selectOnly(db.habits)..addColumns([countExp])).getSingle();
    final count = row.read(countExp) ?? 0;

    if (count > 0) return;

    final now = DateTime.now();
    await db.into(db.habits).insert(
          HabitsCompanion.insert(
            id: 'habit-1',
            name: 'Drink water',
            createdAt: now.millisecondsSinceEpoch,
            archivedAt: const Value.absent(),
          ),
        );
  }

  Future<bool> isCompletedToday(String habitId) async {
    final today = _localDay(DateTime.now());
    final q = db.select(db.habitCompletions)
      ..where((c) => c.habitId.equals(habitId) & c.localDay.equals(today))
      ..limit(1);
    return (await q.get()).isNotEmpty;
  }

  Future<void> completeHabit(String habitId) async {
    final now = DateTime.now();
    final today = _localDay(now);

    await db.transaction(() async {
      await db.into(db.habitCompletions).insert(
            HabitCompletionsCompanion.insert(
              id: 'c-$habitId-$today', // deterministic: prevents duplicates
              habitId: habitId,
              completedAt: now.millisecondsSinceEpoch,
              localDay: today,
            ),
            mode: InsertMode.insertOrIgnore, // idempotent
          );
    });
  }
}