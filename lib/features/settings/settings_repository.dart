import 'package:drift/drift.dart';
import '../../db/app_db.dart';

class SettingsRepository {
  SettingsRepository(this.db);
  final AppDb db;

  Future<UserSetting> getSettings() async {
    final existing = await (db.select(
      db.userSettings,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    if (existing != null) {
      if (existing.soundPackId == 'system' ||
          existing.soundPackId == 'forest') {
        await setSoundPack('interface');
      }
      return (db.select(
        db.userSettings,
      )..where((s) => s.id.equals(1))).getSingle();
    }

    await db
        .into(db.userSettings)
        .insert(
          const UserSettingsCompanion(id: Value(1), themeId: Value('light')),
          mode: InsertMode.insertOrIgnore,
        );

    return (db.select(
      db.userSettings,
    )..where((s) => s.id.equals(1))).getSingle();
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
          UserSettingsCompanion(id: const Value(1), soundPackId: Value(packId)),
        );
  }

  Future<void> setSoundCompleteId(String soundId) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            soundCompleteId: Value(soundId),
          ),
        );
  }

  Future<void> setSoundLevelUpId(String soundId) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            soundLevelUpId: Value(soundId),
          ),
        );
  }

  Future<void> setSoundEquipId(String soundId) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            soundEquipId: Value(soundId),
          ),
        );
  }

  Future<void> setSoundCompletePath(String path) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            soundCompletePath: Value(path),
          ),
        );
  }

  Future<void> setSoundLevelUpPath(String path) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            soundLevelUpPath: Value(path),
          ),
        );
  }

  Future<void> setSoundEquipPath(String path) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            soundEquipPath: Value(path),
          ),
        );
  }

  Future<void> setThemeId(String themeId) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(id: const Value(1), themeId: Value(themeId)),
        );
  }

  Future<void> setProfileAvatarMode(String mode) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            profileAvatarMode: Value(mode),
          ),
        );
  }

  Future<void> setProfileAvatarPath(String path) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            profileAvatarPath: Value(path),
          ),
        );
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            onboardingCompleted: Value(value),
          ),
        );
  }

  Future<void> setExperienceLevel(String value) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            experienceLevel: Value(value),
          ),
        );
  }

  Future<void> setFocusTags(List<String> tags) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            focusTags: Value(tags.join(',')),
          ),
        );
  }

  Future<void> setArchetype(String value) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(id: const Value(1), archetype: Value(value)),
        );
  }

  Future<void> setStarterHabitsSeeded(bool value) async {
    await db
        .into(db.userSettings)
        .insertOnConflictUpdate(
          UserSettingsCompanion(
            id: const Value(1),
            starterHabitsSeeded: Value(value),
          ),
        );
  }
}
