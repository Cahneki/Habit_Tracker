import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart'; 
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [Habits, HabitCompletions, UserSettings, EquippedCosmetics])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 4;

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
