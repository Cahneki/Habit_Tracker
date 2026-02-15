import 'package:drift/drift.dart';

import '../../db/app_db.dart';
import '../../shared/local_day.dart';
import 'daily_free_action_model.dart';

class DailyFreeActionRepository {
  DailyFreeActionRepository(this.db);

  final AppDb db;

  Future<List<DailyFreeActionRecord>> listForDate(DateTime date) async {
    final key = localDay(startOfLocalDay(date));
    final rows = await (db.select(
      db.dailyFreeActions,
    )..where((t) => t.dateKey.equals(key))).get();
    return rows
        .map((row) {
          final action = dailyFreeActionTypeFromStorage(row.actionType);
          if (action == null) return null;
          return DailyFreeActionRecord(
            dateKey: row.dateKey,
            actionType: action,
            performedAt: DateTime.fromMillisecondsSinceEpoch(row.performedAt),
          );
        })
        .whereType<DailyFreeActionRecord>()
        .toList();
  }

  Future<bool> performForDate(DateTime date, DailyFreeActionType action) async {
    final key = localDay(startOfLocalDay(date));
    final now = DateTime.now();

    return db.transaction(() async {
      final existing =
          await (db.select(db.dailyFreeActions)
                ..where(
                  (t) =>
                      t.dateKey.equals(key) &
                      t.actionType.equals(action.storageValue),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) return false;

      await db
          .into(db.dailyFreeActions)
          .insert(
            DailyFreeActionsCompanion.insert(
              dateKey: key,
              actionType: action.storageValue,
              performedAt: now.millisecondsSinceEpoch,
            ),
          );

      if (action == DailyFreeActionType.train) {
        final eventId = 'daily-train-$key';
        await db
            .into(db.xpEvents)
            .insert(
              XpEventsCompanion.insert(
                eventId: eventId,
                source: 'daily_free_action',
                battleId: 'daily_$key',
                amount: 5,
                createdAt: now.toIso8601String(),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      return true;
    });
  }

  Future<void> clearForDate(DateTime date) async {
    final key = localDay(startOfLocalDay(date));
    await (db.delete(
      db.dailyFreeActions,
    )..where((t) => t.dateKey.equals(key))).go();
    await (db.delete(
      db.xpEvents,
    )..where((t) => t.eventId.equals('daily-train-$key'))).go();
  }
}
