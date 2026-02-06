import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/db/app_db.dart';
import 'package:habit_tracker/features/habits/habit_repository.dart';
import 'package:habit_tracker/features/habits/schedule_picker.dart';
import 'package:habit_tracker/shared/local_day.dart';

void main() {
  late AppDb db;
  late HabitRepository repo;

  setUp(() {
    db = AppDb.test(NativeDatabase.memory());
    repo = HabitRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('XP recomputes deterministically after history edits', () async {
    final habitId = 'h-xp';
    final scheduleMask = ScheduleMask.maskFromDays({0, 1, 2, 3, 4, 5, 6});
    await repo.createHabit(
      id: habitId,
      name: 'Daily Habit',
      scheduleMask: scheduleMask,
    );

    final today = startOfLocalDay(DateTime.now());
    final day1 = today.subtract(const Duration(days: 1));
    final day2 = today.subtract(const Duration(days: 2));

    await repo.toggleCompletionForDay(habitId, day2);
    await repo.toggleCompletionForDay(habitId, day1);
    await repo.toggleCompletionForDay(habitId, today);

    final xpBefore = await repo.computeTotalXp();
    expect(xpBefore, 90);

    await repo.toggleCompletionForDay(habitId, day1);

    final xpAfter = await repo.computeTotalXp();
    expect(xpAfter, 60);
  });
}
