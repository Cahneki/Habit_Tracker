import 'package:drift/drift.dart';

class Habits extends Table {
  TextColumn get id => text()(); // e.g. uuid
  TextColumn get name => text()();
  IntColumn get baseXp => integer().withDefault(const Constant(20))();
  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get archivedAt => integer().nullable()(); // epoch ms
  IntColumn get scheduleMask => integer().nullable()(); // bitmask: 0=Mon .. 6=Sun
  TextColumn get timeOfDay =>
      text().withDefault(const Constant('morning'))();
  TextColumn get iconId => text().withDefault(const Constant('magic'))();
  TextColumn get iconPath => text().withDefault(const Constant(''))();

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
  TextColumn get soundCompleteId =>
      text().withDefault(const Constant('complete'))();
  TextColumn get soundLevelUpId =>
      text().withDefault(const Constant('level_up'))();
  TextColumn get soundEquipId =>
      text().withDefault(const Constant('equip'))();
  TextColumn get soundCompletePath =>
      text().withDefault(const Constant(''))();
  TextColumn get soundLevelUpPath =>
      text().withDefault(const Constant(''))();
  TextColumn get soundEquipPath =>
      text().withDefault(const Constant(''))();
  TextColumn get themeId => text().withDefault(const Constant('forest'))();
  TextColumn get profileAvatarMode =>
      text().withDefault(const Constant('character'))();
  TextColumn get profileAvatarPath =>
      text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class EquippedCosmetics extends Table {
  TextColumn get slot => text()(); // head, body, accessory
  TextColumn get cosmeticId => text()();

  @override
  Set<Column> get primaryKey => {slot};
}

class BattleRewardsClaimed extends Table {
  TextColumn get battleId => text()(); // week_YYYY-MM-DD or month_YYYY-MM
  IntColumn get milestone => integer()(); // 50, 75, 100
  TextColumn get claimedAt => text()(); // ISO timestamp

  @override
  Set<Column> get primaryKey => {battleId, milestone};
}

class XpEvents extends Table {
  TextColumn get eventId => text()(); // deterministic id (battle_id + milestone)
  TextColumn get source => text()(); // e.g. battle
  TextColumn get battleId => text()(); // week_YYYY-MM-DD or month_YYYY-MM
  IntColumn get amount => integer()(); // positive XP
  TextColumn get createdAt => text()(); // ISO timestamp

  @override
  Set<Column> get primaryKey => {eventId};
}
