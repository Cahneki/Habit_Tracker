import '../../db/app_db.dart';
import '../../shared/local_day.dart';
import 'daily_intent_model.dart';

class DailyIntentRepository {
  DailyIntentRepository(this.db);

  final AppDb db;

  Future<DailyIntentSelection?> getForDate(DateTime date) async {
    final key = localDay(startOfLocalDay(date));
    final row = await (db.select(
      db.dailyIntents,
    )..where((t) => t.dateKey.equals(key))).getSingleOrNull();
    if (row == null) return null;
    final intent = dailyIntentTypeFromStorage(row.intent);
    if (intent == null) return null;
    return DailyIntentSelection(
      dateKey: row.dateKey,
      intent: intent,
      selectedAt: DateTime.fromMillisecondsSinceEpoch(row.selectedAt),
    );
  }

  Future<void> setForDate(DateTime date, DailyIntentType intent) async {
    final key = localDay(startOfLocalDay(date));
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.dailyIntents)
        .insertOnConflictUpdate(
          DailyIntentsCompanion.insert(
            dateKey: key,
            intent: intent.storageValue,
            selectedAt: now,
          ),
        );
  }

  Future<void> clearForDate(DateTime date) async {
    final key = localDay(startOfLocalDay(date));
    await (db.delete(
      db.dailyIntents,
    )..where((t) => t.dateKey.equals(key))).go();
  }
}
