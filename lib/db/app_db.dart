import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart'; 
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [
  Habits,
  HabitCompletions,
  UserSettings,
  EquippedCosmetics,
  BattleRewardsClaimed,
  XpEvents,
])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());
  AppDb.test(super.executor);

  @override
  int get schemaVersion => 11;

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
            await migrator.addColumn(
              userSettings,
              userSettings.soundCompleteId,
            );
            await migrator.addColumn(
              userSettings,
              userSettings.soundLevelUpId,
            );
            await migrator.addColumn(
              userSettings,
              userSettings.soundEquipId,
            );
          }
          if (from < 9) {
            await migrator.addColumn(
              userSettings,
              userSettings.soundCompletePath,
            );
            await migrator.addColumn(
              userSettings,
              userSettings.soundLevelUpPath,
            );
            await migrator.addColumn(
              userSettings,
              userSettings.soundEquipPath,
            );
          }
          if (from < 10) {
            await migrator.addColumn(habits, habits.iconId);
          }
          if (from < 11) {
            await migrator.addColumn(habits, habits.iconPath);
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
