// lib/features/habits/habit_repository.dart
import 'package:drift/drift.dart';
import '../../db/app_db.dart';
import '../../shared/local_day.dart';

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

class HabitDayStatus {
  const HabitDayStatus({
    required this.habit,
    required this.scheduled,
    required this.completed,
  });

  final Habit habit;
  final bool scheduled;
  final bool completed;
}

class HabitRepository {
  HabitRepository(this.db);
  final AppDb db;
  final Map<String, Map<String, Set<String>>> _completionRangeCache = {};

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

  bool _isDailySchedule(int? mask) {
    return mask == null || mask == 0x7f;
  }

  void _clearCompletionRangeCache() {
    _completionRangeCache.clear();
  }

  String _rangeKey(DateTime start, DateTime endExclusive, List<String>? habitIds) {
    final base = '${localDay(start)}|${localDay(endExclusive)}';
    if (habitIds == null) return '$base|*';
    if (habitIds.isEmpty) return '$base|[]';
    final ids = List<String>.from(habitIds)..sort();
    return '$base|${ids.join(',')}';
  }

  Future<List<Habit>> listHabits() {
    return db.select(db.habits).get();
  }

  Future<List<Habit>> listActiveHabits() {
    return (db.select(db.habits)..where((h) => h.archivedAt.isNull())).get();
  }

  Future<List<Habit>> listArchivedHabits() {
    return (db.select(db.habits)..where((h) => h.archivedAt.isNotNull())).get();
  }

  Future<void> createHabit({
    required String id,
    required String name,
    required int scheduleMask,
    int baseXp = 20,
  }) async {
    final now = DateTime.now();
    await db.into(db.habits).insert(
          HabitsCompanion.insert(
            id: id,
            name: name,
            baseXp: Value(baseXp),
            createdAt: now.millisecondsSinceEpoch,
            archivedAt: const Value.absent(),
            scheduleMask: Value(scheduleMask),
          ),
        );
  }

  Future<void> renameHabit(String habitId, String name) async {
    await (db.update(db.habits)..where((h) => h.id.equals(habitId))).write(
      HabitsCompanion(name: Value(name)),
    );
  }

  Future<void> updateScheduleMask(String habitId, int scheduleMask) async {
    await (db.update(db.habits)..where((h) => h.id.equals(habitId))).write(
      HabitsCompanion(scheduleMask: Value(scheduleMask)),
    );
  }

  Future<void> archiveHabit(String habitId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (db.update(db.habits)..where((h) => h.id.equals(habitId))).write(
      HabitsCompanion(archivedAt: Value(now)),
    );
  }

  Future<void> unarchiveHabit(String habitId) async {
    await (db.update(db.habits)..where((h) => h.id.equals(habitId))).write(
      const HabitsCompanion(archivedAt: Value(null)),
    );
  }

  Future<void> deleteHabit(String habitId) async {
    await db.transaction(() async {
      await (db.delete(db.habitCompletions)
            ..where((c) => c.habitId.equals(habitId)))
          .go();
      await (db.delete(db.habits)..where((h) => h.id.equals(habitId))).go();
    });
    _clearCompletionRangeCache();
  }

  Future<void> completeHabit(String habitId) async {
    final now = DateTime.now();
    final today = localDay(now);
    final habit = await (db.select(db.habits)..where((h) => h.id.equals(habitId)))
        .getSingleOrNull();
    if (habit == null) return;
    if (!_isScheduled(now, habit.scheduleMask)) return;

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
    _clearCompletionRangeCache();
  }

  Future<void> toggleCompletionForDay(String habitId, DateTime day) async {
    final habit = await (db.select(db.habits)..where((h) => h.id.equals(habitId)))
        .getSingleOrNull();
    if (habit == null) return;
    if (!_isScheduled(day, habit.scheduleMask)) return;

    final localDayStr = localDay(day);
    final rows = await (db.select(db.habitCompletions)
          ..where(
            (c) => c.habitId.equals(habitId) & c.localDay.equals(localDayStr),
          )
          ..limit(1))
        .get();

    if (rows.isEmpty) {
      final completedAt = dayAtNoon(day);
      await db.into(db.habitCompletions).insert(
            HabitCompletionsCompanion.insert(
              id: 'c-$habitId-$localDayStr',
              habitId: habitId,
              completedAt: completedAt.millisecondsSinceEpoch,
              localDay: localDayStr,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      _clearCompletionRangeCache();
      return;
    }

    await (db.delete(db.habitCompletions)
          ..where(
            (c) => c.habitId.equals(habitId) & c.localDay.equals(localDayStr),
          ))
        .go();
    _clearCompletionRangeCache();
  }

  Future<List<HabitDayStatus>> getHabitsForDate(DateTime date) async {
    final localDayStr = localDay(date);
    final habits = await listActiveHabits();
    final completions = await (db.select(db.habitCompletions)
          ..where((c) => c.localDay.equals(localDayStr)))
        .get();
    final completedIds = completions.map((c) => c.habitId).toSet();

    return habits
        .map(
          (h) => HabitDayStatus(
            habit: h,
            scheduled: _isScheduled(date, h.scheduleMask),
            completed: completedIds.contains(h.id),
          ),
        )
        .toList();
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
    final todayStr = localDay(now);
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
      final key = localDay(d);
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
      final key = localDay(cursor);
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

  Future<Set<String>> getCompletionDaysForRange(
    String habitId,
    DateTime start,
    DateTime endExclusive,
  ) async {
    final startStr = localDay(start);
    final endStr = localDay(endExclusive);

    final rows = await (db.select(db.habitCompletions)
          ..where((c) =>
              c.habitId.equals(habitId) &
              c.localDay.isBiggerOrEqualValue(startStr) &
              c.localDay.isSmallerThanValue(endStr))
          ..orderBy([(c) => OrderingTerm(expression: c.localDay)]))
        .get();

    return rows.map((r) => r.localDay).toSet();
  }

  Future<Map<String, Set<String>>> getCompletionDaysForRangeByHabit(
    DateTime start,
    DateTime endExclusive, {
    List<String>? habitIds,
  }) async {
    final key = _rangeKey(start, endExclusive, habitIds);
    final cached = _completionRangeCache[key];
    if (cached != null) return cached;

    final startStr = localDay(start);
    final endStr = localDay(endExclusive);

    final query = db.select(db.habitCompletions)
      ..where((c) =>
          c.localDay.isBiggerOrEqualValue(startStr) &
          c.localDay.isSmallerThanValue(endStr));
    if (habitIds != null) {
      if (habitIds.isEmpty) return <String, Set<String>>{};
      query.where((c) => c.habitId.isIn(habitIds));
    }

    final rows = await query.get();
    final result = <String, Set<String>>{};
    for (final row in rows) {
      result.putIfAbsent(row.habitId, () => <String>{}).add(row.localDay);
    }

    _completionRangeCache[key] = result;
    return result;
  }

  Future<Set<String>> getCompletionDaysForMonth(String habitId, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return getCompletionDaysForRange(habitId, start, end);
  }

  Future<int> getTotalCompletions() async {
    final rows = await db.select(db.habitCompletions).get();
    return rows.length;
  }

  Future<int> getXpEventsTotal() async {
    final rows = await db.select(db.xpEvents).get();
    if (rows.isEmpty) return 0;
    return rows.fold<int>(0, (sum, r) => sum + r.amount);
  }

  Future<int> computeTotalXp() async {
    final habits = await listHabits();
    if (habits.isEmpty) return 0;

    final habitById = {for (final h in habits) h.id: h};
    final rows = await (db.select(db.habitCompletions)
          ..orderBy([
            (c) => OrderingTerm(expression: c.habitId),
            (c) => OrderingTerm(expression: c.localDay),
          ]))
        .get();

    final grouped = <String, List<String>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.habitId, () => []).add(row.localDay);
    }

    var totalXp = 0;
    for (final entry in grouped.entries) {
      final habit = habitById[entry.key];
      if (habit == null) continue;
      final scheduleMask = habit.scheduleMask;
      final isDaily = _isDailySchedule(scheduleMask);
      final days = entry.value;
      if (days.isEmpty) continue;

      final completedSet = days.toSet();
      final start = _parseLocalDay(days.first);
      final end = _parseLocalDay(days.last);
      var streak = 0;

      for (var d = start;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1))) {
        if (!_isScheduled(d, scheduleMask)) continue;
        final key = localDay(d);
        if (completedSet.contains(key)) {
          streak += 1;
          var xp = 20;
          if (isDaily) xp += 10;
          xp += (streak ~/ 5) * 5;
          totalXp += xp.clamp(20, 60);
        } else {
          streak = 0;
        }
      }
    }

    final bonusXp = await getXpEventsTotal();
    return totalXp + bonusXp;
  }
}
