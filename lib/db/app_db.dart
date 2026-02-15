import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_db.g.dart';

@DriftDatabase(
  tables: [
    Habits,
    HabitCompletions,
    UserSettings,
    DailyIntents,
    DailyFreeActions,
    EquippedCosmetics,
    BattleRewardsClaimed,
    XpEvents,
  ],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());
  AppDb.test(super.executor);

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_habit_completions_habit_day ON habit_completions (habit_id, local_day)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_habit_completions_local_day ON habit_completions (local_day)',
      );
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(habits, habits.scheduleMask);
      }
      if (from < 3) {
        await migrator.alterTable(TableMigration(habits));
      }
      if (from < 4) {
        await migrator.createTable(userSettings);
        await migrator.createTable(equippedCosmetics);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_habit_completions_habit_day ON habit_completions (habit_id, local_day)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_habit_completions_local_day ON habit_completions (local_day)',
        );
      }
      if (from < 5) {
        await migrator.createTable(battleRewardsClaimed);
      }
      if (from < 6) {
        await migrator.addColumn(habits, habits.baseXp);
        await migrator.createTable(xpEvents);
      }
      if (from < 7) {
        await migrator.addColumn(userSettings, userSettings.themeId);
      }
      if (from < 8) {
        await migrator.addColumn(userSettings, userSettings.soundCompleteId);
        await migrator.addColumn(userSettings, userSettings.soundLevelUpId);
        await migrator.addColumn(userSettings, userSettings.soundEquipId);
      }
      if (from < 9) {
        await migrator.addColumn(userSettings, userSettings.soundCompletePath);
        await migrator.addColumn(userSettings, userSettings.soundLevelUpPath);
        await migrator.addColumn(userSettings, userSettings.soundEquipPath);
      }
      if (from < 10) {
        await migrator.addColumn(habits, habits.iconId);
      }
      if (from < 11) {
        await migrator.addColumn(habits, habits.iconPath);
      }
      if (from < 12) {
        await migrator.addColumn(habits, habits.timeOfDay as GeneratedColumn);
      }
      if (from < 13) {
        await migrator.addColumn(
          userSettings,
          userSettings.profileAvatarMode as GeneratedColumn,
        );
        await migrator.addColumn(
          userSettings,
          userSettings.profileAvatarPath as GeneratedColumn,
        );
      }
      if (from < 14) {
        await migrator.addColumn(
          userSettings,
          userSettings.onboardingCompleted as GeneratedColumn,
        );
        await migrator.addColumn(
          userSettings,
          userSettings.experienceLevel as GeneratedColumn,
        );
        await migrator.addColumn(
          userSettings,
          userSettings.focusTags as GeneratedColumn,
        );
        await migrator.addColumn(
          userSettings,
          userSettings.archetype as GeneratedColumn,
        );
        await migrator.addColumn(
          userSettings,
          userSettings.starterHabitsSeeded as GeneratedColumn,
        );
        await customStatement(
          'UPDATE user_settings SET onboarding_completed = 1 WHERE id = 1',
        );
      }
      if (from < 15) {
        await migrator.createTable(dailyIntents);
      }
      if (from < 16) {
        await migrator.addColumn(
          habitCompletions,
          habitCompletions.actionType as GeneratedColumn,
        );
        await migrator.addColumn(
          habitCompletions,
          habitCompletions.lootSuccess as GeneratedColumn,
        );
      }
      if (from < 17) {
        await migrator.createTable(dailyFreeActions);
      }
      if (from < 18) {
        await migrator.addColumn(
          userSettings,
          userSettings.profileName as GeneratedColumn,
        );
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'habit_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
