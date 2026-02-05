import 'package:drift/drift.dart';

class Habits extends Table {
  TextColumn get id => text()(); // e.g. uuid
  TextColumn get name => text()();
  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get archivedAt => integer().nullable()(); // epoch ms
  IntColumn get scheduleMask => integer().nullable()(); // bitmask: 0=Mon .. 6=Sun

  @override
  Set<Column> get primaryKey => {id};
}

class HabitCompletions extends Table {
  TextColumn get id => text()(); // uuid or deterministic id
  TextColumn get habitId => text().references(Habits, #id)();
  IntColumn get completedAt => integer()(); // epoch ms
  TextColumn get localDay => text()(); // YYYY-MM-DD

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, localDay}, // prevents double completion per day
      ];
}

class UserSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get soundEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get soundPackId => text().withDefault(const Constant('system'))();

  @override
  Set<Column> get primaryKey => {id};
}

class EquippedCosmetics extends Table {
  TextColumn get slot => text()(); // head, body, accessory
  TextColumn get cosmeticId => text()();

  @override
  Set<Column> get primaryKey => {slot};
}
