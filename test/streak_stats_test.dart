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

  test('scheduled-only streaks count properly with gaps', () async {
    final habitId = 'h-streak';
    final scheduleMask = ScheduleMask.maskFromDays({0, 2, 4});
    await repo.createHabit(
      id: habitId,
      name: 'MWF Habit',
      scheduleMask: scheduleMask,
    );

    final now = DateTime.now();
    final weekStart =
        startOfLocalDay(now).subtract(Duration(days: now.weekday - DateTime.monday));
    final lastWeekMonday = weekStart.subtract(const Duration(days: 7));
    final lastWeekWednesday = lastWeekMonday.add(const Duration(days: 2));

    await repo.toggleCompletionForDay(habitId, lastWeekMonday);
    await repo.toggleCompletionForDay(habitId, lastWeekWednesday);

    final stats = await repo.getStreakStats(habitId);
    expect(stats.longest, 2);
    expect(stats.current, 0);
    expect(stats.totalCompletions, 2);
  });

  test('no scheduled days yields zero streaks', () async {
    final habitId = 'h-none';
    await repo.createHabit(
      id: habitId,
      name: 'No Schedule',
      scheduleMask: 0,
    );

    final day = DateTime.now().subtract(const Duration(days: 1));
    final dayKey = localDay(day);
    await db.into(db.habitCompletions).insert(
          HabitCompletionsCompanion.insert(
            id: 'c-$habitId-$dayKey',
            habitId: habitId,
            completedAt: dayAtNoon(day).millisecondsSinceEpoch,
            localDay: dayKey,
          ),
        );

    final stats = await repo.getStreakStats(habitId);
    expect(stats.current, 0);
    expect(stats.longest, 0);
    expect(stats.totalCompletions, 1);
  });
}
