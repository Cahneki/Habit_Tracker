import 'package:drift/drift.dart';
import '../../db/app_db.dart';

class SettingsRepository {
  SettingsRepository(this.db);
  final AppDb db;

  Future<UserSetting> getSettings() async {
    final existing = await (db.select(db.userSettings)
          ..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    if (existing != null) return existing;

    await db.into(db.userSettings).insert(
          const UserSettingsCompanion(id: Value(1)),
          mode: InsertMode.insertOrIgnore,
        );

    return (db.select(db.userSettings)..where((s) => s.id.equals(1))).getSingle();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            soundEnabled: Value(enabled),
          ),
        );
  }

  Future<void> setSoundPack(String packId) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            soundPackId: Value(packId),
          ),
        );
  }

  Future<void> setThemeId(String themeId) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            themeId: Value(themeId),
          ),
        );
  }
}
