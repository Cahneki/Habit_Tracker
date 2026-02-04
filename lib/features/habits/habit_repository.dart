// lib/features/habits/habit_repository.dart
import 'package:drift/drift.dart';
import '../../db/app_db.dart';

class StreakStats {
  const StreakStats({
    required this.current,
    required this.longest,
    required this.totalCompletions,
    required this.lastLocalDay,
    required this.completedToday,
  });

  final int current;
  final int longest;
  final int totalCompletions;
  final String? lastLocalDay;
  final bool completedToday;
}

class HabitRepository {
  HabitRepository(this.db);
  final AppDb db;

  String _localDay(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _parseLocalDay(String s) {
    final y = int.parse(s.substring(0, 4));
    final m = int.parse(s.substring(5, 7));
    final d = int.parse(s.substring(8, 10));
    return DateTime(y, m, d);
  }

  bool _isScheduled(DateTime date, int? scheduleMask) {
    if (scheduleMask == null) return true; // legacy: treat as daily
    if (scheduleMask == 0) return false;
    final bit = 1 << (date.weekday - 1); // Mon=1 .. Sun=7
    return (scheduleMask & bit) != 0;
  }

  Future<List<Habit>> listHabits() {
    return db.select(db.habits).get();
  }

  Future<void> createHabit({
    required String id,
    required String name,
    required int scheduleMask,
  }) async {
    final now = DateTime.now();
    await db.into(db.habits).insert(
          HabitsCompanion.insert(
            id: id,
            name: name,
            createdAt: now.millisecondsSinceEpoch,
            archivedAt: const Value.absent(),
            scheduleMask: Value(scheduleMask),
          ),
        );
  }

  Future<void> updateScheduleMask(String habitId, int scheduleMask) async {
    await (db.update(db.habits)..where((h) => h.id.equals(habitId))).write(
      HabitsCompanion(scheduleMask: Value(scheduleMask)),
    );
  }

  Future<void> completeHabit(String habitId) async {
    final now = DateTime.now();
    final today = _localDay(now);

    await db.transaction(() async {
      await db.into(db.habitCompletions).insert(
            HabitCompletionsCompanion.insert(
              id: 'c-$habitId-$today', // deterministic => stable + idempotent
              habitId: habitId,
              completedAt: now.millisecondsSinceEpoch,
              localDay: today,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    });
  }

  Future<void> toggleCompletionForDay(String habitId, DateTime day) async {
    final localDay = _localDay(day);
    final rows = await (db.select(db.habitCompletions)
          ..where(
            (c) => c.habitId.equals(habitId) & c.localDay.equals(localDay),
          )
          ..limit(1))
        .get();

    if (rows.isEmpty) {
      final completedAt = DateTime(day.year, day.month, day.day, 12);
      await db.into(db.habitCompletions).insert(
            HabitCompletionsCompanion.insert(
              id: 'c-$habitId-$localDay',
              habitId: habitId,
              completedAt: completedAt.millisecondsSinceEpoch,
              localDay: localDay,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      return;
    }

    await (db.delete(db.habitCompletions)
          ..where(
            (c) => c.habitId.equals(habitId) & c.localDay.equals(localDay),
          ))
        .go();
  }

  Future<StreakStats> getStreakStats(String habitId) async {
    final habit = await (db.select(db.habits)..where((h) => h.id.equals(habitId)))
        .getSingleOrNull();
    final scheduleMask = habit?.scheduleMask;

    final rows = await (db.select(db.habitCompletions)
          ..where((c) => c.habitId.equals(habitId))
          ..orderBy([(c) => OrderingTerm(expression: c.localDay)]))
        .get();

    if (rows.isEmpty) {
      return const StreakStats(
        current: 0,
        longest: 0,
        totalCompletions: 0,
        lastLocalDay: null,
        completedToday: false,
      );
    }

    final days = rows.map((r) => r.localDay).toList();
    final total = days.length;
    final completedSet = days.toSet();

    final now = DateTime.now();
    final todayStr = _localDay(now);
    final completedToday = completedSet.contains(todayStr);

    // If no schedule days are active, streaks are zero.
    if (scheduleMask != null && scheduleMask == 0) {
      return StreakStats(
        current: 0,
        longest: 0,
        totalCompletions: total,
        lastLocalDay: days.last,
        completedToday: completedToday,
      );
    }

    // Longest streak: consecutive scheduled days completed (unscheduled days ignored).
    var longest = 0;
    var run = 0;
    final start = _parseLocalDay(days.first);
    final end = _parseLocalDay(days.last);
    for (var d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      if (!_isScheduled(d, scheduleMask)) continue;
      final key = _localDay(d);
      if (completedSet.contains(key)) {
        run += 1;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }

    // Current streak: count back from most recent scheduled day <= today.
    var current = 0;
    var cursor = now;
    while (!_isScheduled(cursor, scheduleMask)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (true) {
      if (!_isScheduled(cursor, scheduleMask)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      final key = _localDay(cursor);
      if (!completedSet.contains(key)) break;
      current += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return StreakStats(
      current: current,
      longest: longest,
      totalCompletions: total,
      lastLocalDay: days.last,
      completedToday: completedToday,
    );
  }
  Future<Set<String>> getCompletionDaysForMonth(String habitId, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    String ld(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    final startStr = ld(start);
    final endStr = ld(end);

    final rows = await (db.select(db.habitCompletions)
          ..where((c) =>
              c.habitId.equals(habitId) &
              c.localDay.isBiggerOrEqualValue(startStr) &
              c.localDay.isSmallerThanValue(endStr))
          ..orderBy([(c) => OrderingTerm(expression: c.localDay)]))
        .get();

    return rows.map((r) => r.localDay).toSet();
  }
}
