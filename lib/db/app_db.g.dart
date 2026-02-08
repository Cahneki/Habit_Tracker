// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseXpMeta = const VerificationMeta('baseXp');
  @override
  late final GeneratedColumn<int> baseXp = GeneratedColumn<int>(
    'base_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduleMaskMeta = const VerificationMeta(
    'scheduleMask',
  );
  @override
  late final GeneratedColumn<int> scheduleMask = GeneratedColumn<int>(
    'schedule_mask',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeOfDayMeta = const VerificationMeta(
    'timeOfDay',
  );
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('morning'),
  );
  static const VerificationMeta _iconIdMeta = const VerificationMeta('iconId');
  @override
  late final GeneratedColumn<String> iconId = GeneratedColumn<String>(
    'icon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('magic'),
  );
  static const VerificationMeta _iconPathMeta = const VerificationMeta(
    'iconPath',
  );
  @override
  late final GeneratedColumn<String> iconPath = GeneratedColumn<String>(
    'icon_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    baseXp,
    createdAt,
    archivedAt,
    scheduleMask,
    timeOfDay,
    iconId,
    iconPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Habit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_xp')) {
      context.handle(
        _baseXpMeta,
        baseXp.isAcceptableOrUnknown(data['base_xp']!, _baseXpMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('schedule_mask')) {
      context.handle(
        _scheduleMaskMeta,
        scheduleMask.isAcceptableOrUnknown(
          data['schedule_mask']!,
          _scheduleMaskMeta,
        ),
      );
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
        _timeOfDayMeta,
        timeOfDay.isAcceptableOrUnknown(data['time_of_day']!, _timeOfDayMeta),
      );
    }
    if (data.containsKey('icon_id')) {
      context.handle(
        _iconIdMeta,
        iconId.isAcceptableOrUnknown(data['icon_id']!, _iconIdMeta),
      );
    }
    if (data.containsKey('icon_path')) {
      context.handle(
        _iconPathMeta,
        iconPath.isAcceptableOrUnknown(data['icon_path']!, _iconPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_xp'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_at'],
      ),
      scheduleMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_mask'],
      ),
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
      iconId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_id'],
      )!,
      iconPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_path'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final String id;
  final String name;
  final int baseXp;
  final int createdAt;
  final int? archivedAt;
  final int? scheduleMask;
  final String timeOfDay;
  final String iconId;
  final String iconPath;
  const Habit({
    required this.id,
    required this.name,
    required this.baseXp,
    required this.createdAt,
    this.archivedAt,
    this.scheduleMask,
    required this.timeOfDay,
    required this.iconId,
    required this.iconPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_xp'] = Variable<int>(baseXp);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    if (!nullToAbsent || scheduleMask != null) {
      map['schedule_mask'] = Variable<int>(scheduleMask);
    }
    map['time_of_day'] = Variable<String>(timeOfDay);
    map['icon_id'] = Variable<String>(iconId);
    map['icon_path'] = Variable<String>(iconPath);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      baseXp: Value(baseXp),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      scheduleMask: scheduleMask == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleMask),
      timeOfDay: Value(timeOfDay),
      iconId: Value(iconId),
      iconPath: Value(iconPath),
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseXp: serializer.fromJson<int>(json['baseXp']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
      scheduleMask: serializer.fromJson<int?>(json['scheduleMask']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      iconId: serializer.fromJson<String>(json['iconId']),
      iconPath: serializer.fromJson<String>(json['iconPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseXp': serializer.toJson<int>(baseXp),
      'createdAt': serializer.toJson<int>(createdAt),
      'archivedAt': serializer.toJson<int?>(archivedAt),
      'scheduleMask': serializer.toJson<int?>(scheduleMask),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'iconId': serializer.toJson<String>(iconId),
      'iconPath': serializer.toJson<String>(iconPath),
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    int? baseXp,
    int? createdAt,
    Value<int?> archivedAt = const Value.absent(),
    Value<int?> scheduleMask = const Value.absent(),
    String? timeOfDay,
    String? iconId,
    String? iconPath,
  }) => Habit(
    id: id ?? this.id,
    name: name ?? this.name,
    baseXp: baseXp ?? this.baseXp,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    scheduleMask: scheduleMask.present ? scheduleMask.value : this.scheduleMask,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    iconId: iconId ?? this.iconId,
    iconPath: iconPath ?? this.iconPath,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseXp: data.baseXp.present ? data.baseXp.value : this.baseXp,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      scheduleMask: data.scheduleMask.present
          ? data.scheduleMask.value
          : this.scheduleMask,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      iconId: data.iconId.present ? data.iconId.value : this.iconId,
      iconPath: data.iconPath.present ? data.iconPath.value : this.iconPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseXp: $baseXp, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('scheduleMask: $scheduleMask, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('iconId: $iconId, ')
          ..write('iconPath: $iconPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    baseXp,
    createdAt,
    archivedAt,
    scheduleMask,
    timeOfDay,
    iconId,
    iconPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseXp == this.baseXp &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt &&
          other.scheduleMask == this.scheduleMask &&
          other.timeOfDay == this.timeOfDay &&
          other.iconId == this.iconId &&
          other.iconPath == this.iconPath);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> baseXp;
  final Value<int> createdAt;
  final Value<int?> archivedAt;
  final Value<int?> scheduleMask;
  final Value<String> timeOfDay;
  final Value<String> iconId;
  final Value<String> iconPath;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseXp = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.scheduleMask = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.iconId = const Value.absent(),
    this.iconPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required String name,
    this.baseXp = const Value.absent(),
    required int createdAt,
    this.archivedAt = const Value.absent(),
    this.scheduleMask = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.iconId = const Value.absent(),
    this.iconPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Habit> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? baseXp,
    Expression<int>? createdAt,
    Expression<int>? archivedAt,
    Expression<int>? scheduleMask,
    Expression<String>? timeOfDay,
    Expression<String>? iconId,
    Expression<String>? iconPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseXp != null) 'base_xp': baseXp,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (scheduleMask != null) 'schedule_mask': scheduleMask,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (iconId != null) 'icon_id': iconId,
      if (iconPath != null) 'icon_path': iconPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? baseXp,
    Value<int>? createdAt,
    Value<int?>? archivedAt,
    Value<int?>? scheduleMask,
    Value<String>? timeOfDay,
    Value<String>? iconId,
    Value<String>? iconPath,
    Value<int>? rowid,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseXp: baseXp ?? this.baseXp,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      scheduleMask: scheduleMask ?? this.scheduleMask,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      iconId: iconId ?? this.iconId,
      iconPath: iconPath ?? this.iconPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseXp.present) {
      map['base_xp'] = Variable<int>(baseXp.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (scheduleMask.present) {
      map['schedule_mask'] = Variable<int>(scheduleMask.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (iconId.present) {
      map['icon_id'] = Variable<String>(iconId.value);
    }
    if (iconPath.present) {
      map['icon_path'] = Variable<String>(iconPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseXp: $baseXp, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('scheduleMask: $scheduleMask, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('iconId: $iconId, ')
          ..write('iconPath: $iconPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitCompletionsTable extends HabitCompletions
    with TableInfo<$HabitCompletionsTable, HabitCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id)',
    ),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDayMeta = const VerificationMeta(
    'localDay',
  );
  @override
  late final GeneratedColumn<String> localDay = GeneratedColumn<String>(
    'local_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, completedAt, localDay];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitCompletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('local_day')) {
      context.handle(
        _localDayMeta,
        localDay.isAcceptableOrUnknown(data['local_day']!, _localDayMeta),
      );
    } else if (isInserting) {
      context.missing(_localDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, localDay},
  ];
  @override
  HabitCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitCompletion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      )!,
      localDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_day'],
      )!,
    );
  }

  @override
  $HabitCompletionsTable createAlias(String alias) {
    return $HabitCompletionsTable(attachedDatabase, alias);
  }
}

class HabitCompletion extends DataClass implements Insertable<HabitCompletion> {
  final String id;
  final String habitId;
  final int completedAt;
  final String localDay;
  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.completedAt,
    required this.localDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['completed_at'] = Variable<int>(completedAt);
    map['local_day'] = Variable<String>(localDay);
    return map;
  }

  HabitCompletionsCompanion toCompanion(bool nullToAbsent) {
    return HabitCompletionsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      completedAt: Value(completedAt),
      localDay: Value(localDay),
    );
  }

  factory HabitCompletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitCompletion(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      completedAt: serializer.fromJson<int>(json['completedAt']),
      localDay: serializer.fromJson<String>(json['localDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'completedAt': serializer.toJson<int>(completedAt),
      'localDay': serializer.toJson<String>(localDay),
    };
  }

  HabitCompletion copyWith({
    String? id,
    String? habitId,
    int? completedAt,
    String? localDay,
  }) => HabitCompletion(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    completedAt: completedAt ?? this.completedAt,
    localDay: localDay ?? this.localDay,
  );
  HabitCompletion copyWithCompanion(HabitCompletionsCompanion data) {
    return HabitCompletion(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      localDay: data.localDay.present ? data.localDay.value : this.localDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitCompletion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('completedAt: $completedAt, ')
          ..write('localDay: $localDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, completedAt, localDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitCompletion &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.completedAt == this.completedAt &&
          other.localDay == this.localDay);
}

class HabitCompletionsCompanion extends UpdateCompanion<HabitCompletion> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<int> completedAt;
  final Value<String> localDay;
  final Value<int> rowid;
  const HabitCompletionsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.localDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitCompletionsCompanion.insert({
    required String id,
    required String habitId,
    required int completedAt,
    required String localDay,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitId = Value(habitId),
       completedAt = Value(completedAt),
       localDay = Value(localDay);
  static Insertable<HabitCompletion> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<int>? completedAt,
    Expression<String>? localDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (completedAt != null) 'completed_at': completedAt,
      if (localDay != null) 'local_day': localDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitCompletionsCompanion copyWith({
    Value<String>? id,
    Value<String>? habitId,
    Value<int>? completedAt,
    Value<String>? localDay,
    Value<int>? rowid,
  }) {
    return HabitCompletionsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      completedAt: completedAt ?? this.completedAt,
      localDay: localDay ?? this.localDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (localDay.present) {
      map['local_day'] = Variable<String>(localDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitCompletionsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('completedAt: $completedAt, ')
          ..write('localDay: $localDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _soundEnabledMeta = const VerificationMeta(
    'soundEnabled',
  );
  @override
  late final GeneratedColumn<bool> soundEnabled = GeneratedColumn<bool>(
    'sound_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sound_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _soundPackIdMeta = const VerificationMeta(
    'soundPackId',
  );
  @override
  late final GeneratedColumn<String> soundPackId = GeneratedColumn<String>(
    'sound_pack_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _soundCompleteIdMeta = const VerificationMeta(
    'soundCompleteId',
  );
  @override
  late final GeneratedColumn<String> soundCompleteId = GeneratedColumn<String>(
    'sound_complete_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('complete'),
  );
  static const VerificationMeta _soundLevelUpIdMeta = const VerificationMeta(
    'soundLevelUpId',
  );
  @override
  late final GeneratedColumn<String> soundLevelUpId = GeneratedColumn<String>(
    'sound_level_up_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('level_up'),
  );
  static const VerificationMeta _soundEquipIdMeta = const VerificationMeta(
    'soundEquipId',
  );
  @override
  late final GeneratedColumn<String> soundEquipId = GeneratedColumn<String>(
    'sound_equip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('equip'),
  );
  static const VerificationMeta _soundCompletePathMeta = const VerificationMeta(
    'soundCompletePath',
  );
  @override
  late final GeneratedColumn<String> soundCompletePath =
      GeneratedColumn<String>(
        'sound_complete_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _soundLevelUpPathMeta = const VerificationMeta(
    'soundLevelUpPath',
  );
  @override
  late final GeneratedColumn<String> soundLevelUpPath = GeneratedColumn<String>(
    'sound_level_up_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _soundEquipPathMeta = const VerificationMeta(
    'soundEquipPath',
  );
  @override
  late final GeneratedColumn<String> soundEquipPath = GeneratedColumn<String>(
    'sound_equip_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _themeIdMeta = const VerificationMeta(
    'themeId',
  );
  @override
  late final GeneratedColumn<String> themeId = GeneratedColumn<String>(
    'theme_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('forest'),
  );
  static const VerificationMeta _profileAvatarModeMeta = const VerificationMeta(
    'profileAvatarMode',
  );
  @override
  late final GeneratedColumn<String> profileAvatarMode =
      GeneratedColumn<String>(
        'profile_avatar_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('character'),
      );
  static const VerificationMeta _profileAvatarPathMeta = const VerificationMeta(
    'profileAvatarPath',
  );
  @override
  late final GeneratedColumn<String> profileAvatarPath =
      GeneratedColumn<String>(
        'profile_avatar_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    soundEnabled,
    soundPackId,
    soundCompleteId,
    soundLevelUpId,
    soundEquipId,
    soundCompletePath,
    soundLevelUpPath,
    soundEquipPath,
    themeId,
    profileAvatarMode,
    profileAvatarPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sound_enabled')) {
      context.handle(
        _soundEnabledMeta,
        soundEnabled.isAcceptableOrUnknown(
          data['sound_enabled']!,
          _soundEnabledMeta,
        ),
      );
    }
    if (data.containsKey('sound_pack_id')) {
      context.handle(
        _soundPackIdMeta,
        soundPackId.isAcceptableOrUnknown(
          data['sound_pack_id']!,
          _soundPackIdMeta,
        ),
      );
    }
    if (data.containsKey('sound_complete_id')) {
      context.handle(
        _soundCompleteIdMeta,
        soundCompleteId.isAcceptableOrUnknown(
          data['sound_complete_id']!,
          _soundCompleteIdMeta,
        ),
      );
    }
    if (data.containsKey('sound_level_up_id')) {
      context.handle(
        _soundLevelUpIdMeta,
        soundLevelUpId.isAcceptableOrUnknown(
          data['sound_level_up_id']!,
          _soundLevelUpIdMeta,
        ),
      );
    }
    if (data.containsKey('sound_equip_id')) {
      context.handle(
        _soundEquipIdMeta,
        soundEquipId.isAcceptableOrUnknown(
          data['sound_equip_id']!,
          _soundEquipIdMeta,
        ),
      );
    }
    if (data.containsKey('sound_complete_path')) {
      context.handle(
        _soundCompletePathMeta,
        soundCompletePath.isAcceptableOrUnknown(
          data['sound_complete_path']!,
          _soundCompletePathMeta,
        ),
      );
    }
    if (data.containsKey('sound_level_up_path')) {
      context.handle(
        _soundLevelUpPathMeta,
        soundLevelUpPath.isAcceptableOrUnknown(
          data['sound_level_up_path']!,
          _soundLevelUpPathMeta,
        ),
      );
    }
    if (data.containsKey('sound_equip_path')) {
      context.handle(
        _soundEquipPathMeta,
        soundEquipPath.isAcceptableOrUnknown(
          data['sound_equip_path']!,
          _soundEquipPathMeta,
        ),
      );
    }
    if (data.containsKey('theme_id')) {
      context.handle(
        _themeIdMeta,
        themeId.isAcceptableOrUnknown(data['theme_id']!, _themeIdMeta),
      );
    }
    if (data.containsKey('profile_avatar_mode')) {
      context.handle(
        _profileAvatarModeMeta,
        profileAvatarMode.isAcceptableOrUnknown(
          data['profile_avatar_mode']!,
          _profileAvatarModeMeta,
        ),
      );
    }
    if (data.containsKey('profile_avatar_path')) {
      context.handle(
        _profileAvatarPathMeta,
        profileAvatarPath.isAcceptableOrUnknown(
          data['profile_avatar_path']!,
          _profileAvatarPathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      soundEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sound_enabled'],
      )!,
      soundPackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_pack_id'],
      )!,
      soundCompleteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_complete_id'],
      )!,
      soundLevelUpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_level_up_id'],
      )!,
      soundEquipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_equip_id'],
      )!,
      soundCompletePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_complete_path'],
      )!,
      soundLevelUpPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_level_up_path'],
      )!,
      soundEquipPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_equip_path'],
      )!,
      themeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_id'],
      )!,
      profileAvatarMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_avatar_mode'],
      )!,
      profileAvatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_avatar_path'],
      )!,
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  final int id;
  final bool soundEnabled;
  final String soundPackId;
  final String soundCompleteId;
  final String soundLevelUpId;
  final String soundEquipId;
  final String soundCompletePath;
  final String soundLevelUpPath;
  final String soundEquipPath;
  final String themeId;
  final String profileAvatarMode;
  final String profileAvatarPath;
  const UserSetting({
    required this.id,
    required this.soundEnabled,
    required this.soundPackId,
    required this.soundCompleteId,
    required this.soundLevelUpId,
    required this.soundEquipId,
    required this.soundCompletePath,
    required this.soundLevelUpPath,
    required this.soundEquipPath,
    required this.themeId,
    required this.profileAvatarMode,
    required this.profileAvatarPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sound_enabled'] = Variable<bool>(soundEnabled);
    map['sound_pack_id'] = Variable<String>(soundPackId);
    map['sound_complete_id'] = Variable<String>(soundCompleteId);
    map['sound_level_up_id'] = Variable<String>(soundLevelUpId);
    map['sound_equip_id'] = Variable<String>(soundEquipId);
    map['sound_complete_path'] = Variable<String>(soundCompletePath);
    map['sound_level_up_path'] = Variable<String>(soundLevelUpPath);
    map['sound_equip_path'] = Variable<String>(soundEquipPath);
    map['theme_id'] = Variable<String>(themeId);
    map['profile_avatar_mode'] = Variable<String>(profileAvatarMode);
    map['profile_avatar_path'] = Variable<String>(profileAvatarPath);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      id: Value(id),
      soundEnabled: Value(soundEnabled),
      soundPackId: Value(soundPackId),
      soundCompleteId: Value(soundCompleteId),
      soundLevelUpId: Value(soundLevelUpId),
      soundEquipId: Value(soundEquipId),
      soundCompletePath: Value(soundCompletePath),
      soundLevelUpPath: Value(soundLevelUpPath),
      soundEquipPath: Value(soundEquipPath),
      themeId: Value(themeId),
      profileAvatarMode: Value(profileAvatarMode),
      profileAvatarPath: Value(profileAvatarPath),
    );
  }

  factory UserSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      id: serializer.fromJson<int>(json['id']),
      soundEnabled: serializer.fromJson<bool>(json['soundEnabled']),
      soundPackId: serializer.fromJson<String>(json['soundPackId']),
      soundCompleteId: serializer.fromJson<String>(json['soundCompleteId']),
      soundLevelUpId: serializer.fromJson<String>(json['soundLevelUpId']),
      soundEquipId: serializer.fromJson<String>(json['soundEquipId']),
      soundCompletePath: serializer.fromJson<String>(json['soundCompletePath']),
      soundLevelUpPath: serializer.fromJson<String>(json['soundLevelUpPath']),
      soundEquipPath: serializer.fromJson<String>(json['soundEquipPath']),
      themeId: serializer.fromJson<String>(json['themeId']),
      profileAvatarMode: serializer.fromJson<String>(json['profileAvatarMode']),
      profileAvatarPath: serializer.fromJson<String>(json['profileAvatarPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'soundEnabled': serializer.toJson<bool>(soundEnabled),
      'soundPackId': serializer.toJson<String>(soundPackId),
      'soundCompleteId': serializer.toJson<String>(soundCompleteId),
      'soundLevelUpId': serializer.toJson<String>(soundLevelUpId),
      'soundEquipId': serializer.toJson<String>(soundEquipId),
      'soundCompletePath': serializer.toJson<String>(soundCompletePath),
      'soundLevelUpPath': serializer.toJson<String>(soundLevelUpPath),
      'soundEquipPath': serializer.toJson<String>(soundEquipPath),
      'themeId': serializer.toJson<String>(themeId),
      'profileAvatarMode': serializer.toJson<String>(profileAvatarMode),
      'profileAvatarPath': serializer.toJson<String>(profileAvatarPath),
    };
  }

  UserSetting copyWith({
    int? id,
    bool? soundEnabled,
    String? soundPackId,
    String? soundCompleteId,
    String? soundLevelUpId,
    String? soundEquipId,
    String? soundCompletePath,
    String? soundLevelUpPath,
    String? soundEquipPath,
    String? themeId,
    String? profileAvatarMode,
    String? profileAvatarPath,
  }) => UserSetting(
    id: id ?? this.id,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    soundPackId: soundPackId ?? this.soundPackId,
    soundCompleteId: soundCompleteId ?? this.soundCompleteId,
    soundLevelUpId: soundLevelUpId ?? this.soundLevelUpId,
    soundEquipId: soundEquipId ?? this.soundEquipId,
    soundCompletePath: soundCompletePath ?? this.soundCompletePath,
    soundLevelUpPath: soundLevelUpPath ?? this.soundLevelUpPath,
    soundEquipPath: soundEquipPath ?? this.soundEquipPath,
    themeId: themeId ?? this.themeId,
    profileAvatarMode: profileAvatarMode ?? this.profileAvatarMode,
    profileAvatarPath: profileAvatarPath ?? this.profileAvatarPath,
  );
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      id: data.id.present ? data.id.value : this.id,
      soundEnabled: data.soundEnabled.present
          ? data.soundEnabled.value
          : this.soundEnabled,
      soundPackId: data.soundPackId.present
          ? data.soundPackId.value
          : this.soundPackId,
      soundCompleteId: data.soundCompleteId.present
          ? data.soundCompleteId.value
          : this.soundCompleteId,
      soundLevelUpId: data.soundLevelUpId.present
          ? data.soundLevelUpId.value
          : this.soundLevelUpId,
      soundEquipId: data.soundEquipId.present
          ? data.soundEquipId.value
          : this.soundEquipId,
      soundCompletePath: data.soundCompletePath.present
          ? data.soundCompletePath.value
          : this.soundCompletePath,
      soundLevelUpPath: data.soundLevelUpPath.present
          ? data.soundLevelUpPath.value
          : this.soundLevelUpPath,
      soundEquipPath: data.soundEquipPath.present
          ? data.soundEquipPath.value
          : this.soundEquipPath,
      themeId: data.themeId.present ? data.themeId.value : this.themeId,
      profileAvatarMode: data.profileAvatarMode.present
          ? data.profileAvatarMode.value
          : this.profileAvatarMode,
      profileAvatarPath: data.profileAvatarPath.present
          ? data.profileAvatarPath.value
          : this.profileAvatarPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('id: $id, ')
          ..write('soundEnabled: $soundEnabled, ')
          ..write('soundPackId: $soundPackId, ')
          ..write('soundCompleteId: $soundCompleteId, ')
          ..write('soundLevelUpId: $soundLevelUpId, ')
          ..write('soundEquipId: $soundEquipId, ')
          ..write('soundCompletePath: $soundCompletePath, ')
          ..write('soundLevelUpPath: $soundLevelUpPath, ')
          ..write('soundEquipPath: $soundEquipPath, ')
          ..write('themeId: $themeId, ')
          ..write('profileAvatarMode: $profileAvatarMode, ')
          ..write('profileAvatarPath: $profileAvatarPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    soundEnabled,
    soundPackId,
    soundCompleteId,
    soundLevelUpId,
    soundEquipId,
    soundCompletePath,
    soundLevelUpPath,
    soundEquipPath,
    themeId,
    profileAvatarMode,
    profileAvatarPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.id == this.id &&
          other.soundEnabled == this.soundEnabled &&
          other.soundPackId == this.soundPackId &&
          other.soundCompleteId == this.soundCompleteId &&
          other.soundLevelUpId == this.soundLevelUpId &&
          other.soundEquipId == this.soundEquipId &&
          other.soundCompletePath == this.soundCompletePath &&
          other.soundLevelUpPath == this.soundLevelUpPath &&
          other.soundEquipPath == this.soundEquipPath &&
          other.themeId == this.themeId &&
          other.profileAvatarMode == this.profileAvatarMode &&
          other.profileAvatarPath == this.profileAvatarPath);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<int> id;
  final Value<bool> soundEnabled;
  final Value<String> soundPackId;
  final Value<String> soundCompleteId;
  final Value<String> soundLevelUpId;
  final Value<String> soundEquipId;
  final Value<String> soundCompletePath;
  final Value<String> soundLevelUpPath;
  final Value<String> soundEquipPath;
  final Value<String> themeId;
  final Value<String> profileAvatarMode;
  final Value<String> profileAvatarPath;
  const UserSettingsCompanion({
    this.id = const Value.absent(),
    this.soundEnabled = const Value.absent(),
    this.soundPackId = const Value.absent(),
    this.soundCompleteId = const Value.absent(),
    this.soundLevelUpId = const Value.absent(),
    this.soundEquipId = const Value.absent(),
    this.soundCompletePath = const Value.absent(),
    this.soundLevelUpPath = const Value.absent(),
    this.soundEquipPath = const Value.absent(),
    this.themeId = const Value.absent(),
    this.profileAvatarMode = const Value.absent(),
    this.profileAvatarPath = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.soundEnabled = const Value.absent(),
    this.soundPackId = const Value.absent(),
    this.soundCompleteId = const Value.absent(),
    this.soundLevelUpId = const Value.absent(),
    this.soundEquipId = const Value.absent(),
    this.soundCompletePath = const Value.absent(),
    this.soundLevelUpPath = const Value.absent(),
    this.soundEquipPath = const Value.absent(),
    this.themeId = const Value.absent(),
    this.profileAvatarMode = const Value.absent(),
    this.profileAvatarPath = const Value.absent(),
  });
  static Insertable<UserSetting> custom({
    Expression<int>? id,
    Expression<bool>? soundEnabled,
    Expression<String>? soundPackId,
    Expression<String>? soundCompleteId,
    Expression<String>? soundLevelUpId,
    Expression<String>? soundEquipId,
    Expression<String>? soundCompletePath,
    Expression<String>? soundLevelUpPath,
    Expression<String>? soundEquipPath,
    Expression<String>? themeId,
    Expression<String>? profileAvatarMode,
    Expression<String>? profileAvatarPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (soundEnabled != null) 'sound_enabled': soundEnabled,
      if (soundPackId != null) 'sound_pack_id': soundPackId,
      if (soundCompleteId != null) 'sound_complete_id': soundCompleteId,
      if (soundLevelUpId != null) 'sound_level_up_id': soundLevelUpId,
      if (soundEquipId != null) 'sound_equip_id': soundEquipId,
      if (soundCompletePath != null) 'sound_complete_path': soundCompletePath,
      if (soundLevelUpPath != null) 'sound_level_up_path': soundLevelUpPath,
      if (soundEquipPath != null) 'sound_equip_path': soundEquipPath,
      if (themeId != null) 'theme_id': themeId,
      if (profileAvatarMode != null) 'profile_avatar_mode': profileAvatarMode,
      if (profileAvatarPath != null) 'profile_avatar_path': profileAvatarPath,
    });
  }

  UserSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? soundEnabled,
    Value<String>? soundPackId,
    Value<String>? soundCompleteId,
    Value<String>? soundLevelUpId,
    Value<String>? soundEquipId,
    Value<String>? soundCompletePath,
    Value<String>? soundLevelUpPath,
    Value<String>? soundEquipPath,
    Value<String>? themeId,
    Value<String>? profileAvatarMode,
    Value<String>? profileAvatarPath,
  }) {
    return UserSettingsCompanion(
      id: id ?? this.id,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundPackId: soundPackId ?? this.soundPackId,
      soundCompleteId: soundCompleteId ?? this.soundCompleteId,
      soundLevelUpId: soundLevelUpId ?? this.soundLevelUpId,
      soundEquipId: soundEquipId ?? this.soundEquipId,
      soundCompletePath: soundCompletePath ?? this.soundCompletePath,
      soundLevelUpPath: soundLevelUpPath ?? this.soundLevelUpPath,
      soundEquipPath: soundEquipPath ?? this.soundEquipPath,
      themeId: themeId ?? this.themeId,
      profileAvatarMode: profileAvatarMode ?? this.profileAvatarMode,
      profileAvatarPath: profileAvatarPath ?? this.profileAvatarPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (soundEnabled.present) {
      map['sound_enabled'] = Variable<bool>(soundEnabled.value);
    }
    if (soundPackId.present) {
      map['sound_pack_id'] = Variable<String>(soundPackId.value);
    }
    if (soundCompleteId.present) {
      map['sound_complete_id'] = Variable<String>(soundCompleteId.value);
    }
    if (soundLevelUpId.present) {
      map['sound_level_up_id'] = Variable<String>(soundLevelUpId.value);
    }
    if (soundEquipId.present) {
      map['sound_equip_id'] = Variable<String>(soundEquipId.value);
    }
    if (soundCompletePath.present) {
      map['sound_complete_path'] = Variable<String>(soundCompletePath.value);
    }
    if (soundLevelUpPath.present) {
      map['sound_level_up_path'] = Variable<String>(soundLevelUpPath.value);
    }
    if (soundEquipPath.present) {
      map['sound_equip_path'] = Variable<String>(soundEquipPath.value);
    }
    if (themeId.present) {
      map['theme_id'] = Variable<String>(themeId.value);
    }
    if (profileAvatarMode.present) {
      map['profile_avatar_mode'] = Variable<String>(profileAvatarMode.value);
    }
    if (profileAvatarPath.present) {
      map['profile_avatar_path'] = Variable<String>(profileAvatarPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('id: $id, ')
          ..write('soundEnabled: $soundEnabled, ')
          ..write('soundPackId: $soundPackId, ')
          ..write('soundCompleteId: $soundCompleteId, ')
          ..write('soundLevelUpId: $soundLevelUpId, ')
          ..write('soundEquipId: $soundEquipId, ')
          ..write('soundCompletePath: $soundCompletePath, ')
          ..write('soundLevelUpPath: $soundLevelUpPath, ')
          ..write('soundEquipPath: $soundEquipPath, ')
          ..write('themeId: $themeId, ')
          ..write('profileAvatarMode: $profileAvatarMode, ')
          ..write('profileAvatarPath: $profileAvatarPath')
          ..write(')'))
        .toString();
  }
}

class $EquippedCosmeticsTable extends EquippedCosmetics
    with TableInfo<$EquippedCosmeticsTable, EquippedCosmetic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EquippedCosmeticsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cosmeticIdMeta = const VerificationMeta(
    'cosmeticId',
  );
  @override
  late final GeneratedColumn<String> cosmeticId = GeneratedColumn<String>(
    'cosmetic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [slot, cosmeticId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'equipped_cosmetics';
  @override
  VerificationContext validateIntegrity(
    Insertable<EquippedCosmetic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('cosmetic_id')) {
      context.handle(
        _cosmeticIdMeta,
        cosmeticId.isAcceptableOrUnknown(data['cosmetic_id']!, _cosmeticIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cosmeticIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slot};
  @override
  EquippedCosmetic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EquippedCosmetic(
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      cosmeticId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cosmetic_id'],
      )!,
    );
  }

  @override
  $EquippedCosmeticsTable createAlias(String alias) {
    return $EquippedCosmeticsTable(attachedDatabase, alias);
  }
}

class EquippedCosmetic extends DataClass
    implements Insertable<EquippedCosmetic> {
  final String slot;
  final String cosmeticId;
  const EquippedCosmetic({required this.slot, required this.cosmeticId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slot'] = Variable<String>(slot);
    map['cosmetic_id'] = Variable<String>(cosmeticId);
    return map;
  }

  EquippedCosmeticsCompanion toCompanion(bool nullToAbsent) {
    return EquippedCosmeticsCompanion(
      slot: Value(slot),
      cosmeticId: Value(cosmeticId),
    );
  }

  factory EquippedCosmetic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EquippedCosmetic(
      slot: serializer.fromJson<String>(json['slot']),
      cosmeticId: serializer.fromJson<String>(json['cosmeticId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slot': serializer.toJson<String>(slot),
      'cosmeticId': serializer.toJson<String>(cosmeticId),
    };
  }

  EquippedCosmetic copyWith({String? slot, String? cosmeticId}) =>
      EquippedCosmetic(
        slot: slot ?? this.slot,
        cosmeticId: cosmeticId ?? this.cosmeticId,
      );
  EquippedCosmetic copyWithCompanion(EquippedCosmeticsCompanion data) {
    return EquippedCosmetic(
      slot: data.slot.present ? data.slot.value : this.slot,
      cosmeticId: data.cosmeticId.present
          ? data.cosmeticId.value
          : this.cosmeticId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EquippedCosmetic(')
          ..write('slot: $slot, ')
          ..write('cosmeticId: $cosmeticId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(slot, cosmeticId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EquippedCosmetic &&
          other.slot == this.slot &&
          other.cosmeticId == this.cosmeticId);
}

class EquippedCosmeticsCompanion extends UpdateCompanion<EquippedCosmetic> {
  final Value<String> slot;
  final Value<String> cosmeticId;
  final Value<int> rowid;
  const EquippedCosmeticsCompanion({
    this.slot = const Value.absent(),
    this.cosmeticId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EquippedCosmeticsCompanion.insert({
    required String slot,
    required String cosmeticId,
    this.rowid = const Value.absent(),
  }) : slot = Value(slot),
       cosmeticId = Value(cosmeticId);
  static Insertable<EquippedCosmetic> custom({
    Expression<String>? slot,
    Expression<String>? cosmeticId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slot != null) 'slot': slot,
      if (cosmeticId != null) 'cosmetic_id': cosmeticId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EquippedCosmeticsCompanion copyWith({
    Value<String>? slot,
    Value<String>? cosmeticId,
    Value<int>? rowid,
  }) {
    return EquippedCosmeticsCompanion(
      slot: slot ?? this.slot,
      cosmeticId: cosmeticId ?? this.cosmeticId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (cosmeticId.present) {
      map['cosmetic_id'] = Variable<String>(cosmeticId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EquippedCosmeticsCompanion(')
          ..write('slot: $slot, ')
          ..write('cosmeticId: $cosmeticId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BattleRewardsClaimedTable extends BattleRewardsClaimed
    with TableInfo<$BattleRewardsClaimedTable, BattleRewardsClaimedData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BattleRewardsClaimedTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _battleIdMeta = const VerificationMeta(
    'battleId',
  );
  @override
  late final GeneratedColumn<String> battleId = GeneratedColumn<String>(
    'battle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _milestoneMeta = const VerificationMeta(
    'milestone',
  );
  @override
  late final GeneratedColumn<int> milestone = GeneratedColumn<int>(
    'milestone',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _claimedAtMeta = const VerificationMeta(
    'claimedAt',
  );
  @override
  late final GeneratedColumn<String> claimedAt = GeneratedColumn<String>(
    'claimed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [battleId, milestone, claimedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'battle_rewards_claimed';
  @override
  VerificationContext validateIntegrity(
    Insertable<BattleRewardsClaimedData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('battle_id')) {
      context.handle(
        _battleIdMeta,
        battleId.isAcceptableOrUnknown(data['battle_id']!, _battleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_battleIdMeta);
    }
    if (data.containsKey('milestone')) {
      context.handle(
        _milestoneMeta,
        milestone.isAcceptableOrUnknown(data['milestone']!, _milestoneMeta),
      );
    } else if (isInserting) {
      context.missing(_milestoneMeta);
    }
    if (data.containsKey('claimed_at')) {
      context.handle(
        _claimedAtMeta,
        claimedAt.isAcceptableOrUnknown(data['claimed_at']!, _claimedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_claimedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {battleId, milestone};
  @override
  BattleRewardsClaimedData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BattleRewardsClaimedData(
      battleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}battle_id'],
      )!,
      milestone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}milestone'],
      )!,
      claimedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claimed_at'],
      )!,
    );
  }

  @override
  $BattleRewardsClaimedTable createAlias(String alias) {
    return $BattleRewardsClaimedTable(attachedDatabase, alias);
  }
}

class BattleRewardsClaimedData extends DataClass
    implements Insertable<BattleRewardsClaimedData> {
  final String battleId;
  final int milestone;
  final String claimedAt;
  const BattleRewardsClaimedData({
    required this.battleId,
    required this.milestone,
    required this.claimedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['battle_id'] = Variable<String>(battleId);
    map['milestone'] = Variable<int>(milestone);
    map['claimed_at'] = Variable<String>(claimedAt);
    return map;
  }

  BattleRewardsClaimedCompanion toCompanion(bool nullToAbsent) {
    return BattleRewardsClaimedCompanion(
      battleId: Value(battleId),
      milestone: Value(milestone),
      claimedAt: Value(claimedAt),
    );
  }

  factory BattleRewardsClaimedData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BattleRewardsClaimedData(
      battleId: serializer.fromJson<String>(json['battleId']),
      milestone: serializer.fromJson<int>(json['milestone']),
      claimedAt: serializer.fromJson<String>(json['claimedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'battleId': serializer.toJson<String>(battleId),
      'milestone': serializer.toJson<int>(milestone),
      'claimedAt': serializer.toJson<String>(claimedAt),
    };
  }

  BattleRewardsClaimedData copyWith({
    String? battleId,
    int? milestone,
    String? claimedAt,
  }) => BattleRewardsClaimedData(
    battleId: battleId ?? this.battleId,
    milestone: milestone ?? this.milestone,
    claimedAt: claimedAt ?? this.claimedAt,
  );
  BattleRewardsClaimedData copyWithCompanion(
    BattleRewardsClaimedCompanion data,
  ) {
    return BattleRewardsClaimedData(
      battleId: data.battleId.present ? data.battleId.value : this.battleId,
      milestone: data.milestone.present ? data.milestone.value : this.milestone,
      claimedAt: data.claimedAt.present ? data.claimedAt.value : this.claimedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BattleRewardsClaimedData(')
          ..write('battleId: $battleId, ')
          ..write('milestone: $milestone, ')
          ..write('claimedAt: $claimedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(battleId, milestone, claimedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BattleRewardsClaimedData &&
          other.battleId == this.battleId &&
          other.milestone == this.milestone &&
          other.claimedAt == this.claimedAt);
}

class BattleRewardsClaimedCompanion
    extends UpdateCompanion<BattleRewardsClaimedData> {
  final Value<String> battleId;
  final Value<int> milestone;
  final Value<String> claimedAt;
  final Value<int> rowid;
  const BattleRewardsClaimedCompanion({
    this.battleId = const Value.absent(),
    this.milestone = const Value.absent(),
    this.claimedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BattleRewardsClaimedCompanion.insert({
    required String battleId,
    required int milestone,
    required String claimedAt,
    this.rowid = const Value.absent(),
  }) : battleId = Value(battleId),
       milestone = Value(milestone),
       claimedAt = Value(claimedAt);
  static Insertable<BattleRewardsClaimedData> custom({
    Expression<String>? battleId,
    Expression<int>? milestone,
    Expression<String>? claimedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (battleId != null) 'battle_id': battleId,
      if (milestone != null) 'milestone': milestone,
      if (claimedAt != null) 'claimed_at': claimedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BattleRewardsClaimedCompanion copyWith({
    Value<String>? battleId,
    Value<int>? milestone,
    Value<String>? claimedAt,
    Value<int>? rowid,
  }) {
    return BattleRewardsClaimedCompanion(
      battleId: battleId ?? this.battleId,
      milestone: milestone ?? this.milestone,
      claimedAt: claimedAt ?? this.claimedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (battleId.present) {
      map['battle_id'] = Variable<String>(battleId.value);
    }
    if (milestone.present) {
      map['milestone'] = Variable<int>(milestone.value);
    }
    if (claimedAt.present) {
      map['claimed_at'] = Variable<String>(claimedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BattleRewardsClaimedCompanion(')
          ..write('battleId: $battleId, ')
          ..write('milestone: $milestone, ')
          ..write('claimedAt: $claimedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $XpEventsTable extends XpEvents with TableInfo<$XpEventsTable, XpEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $XpEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _battleIdMeta = const VerificationMeta(
    'battleId',
  );
  @override
  late final GeneratedColumn<String> battleId = GeneratedColumn<String>(
    'battle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    source,
    battleId,
    amount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'xp_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<XpEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('battle_id')) {
      context.handle(
        _battleIdMeta,
        battleId.isAcceptableOrUnknown(data['battle_id']!, _battleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_battleIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  XpEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return XpEvent(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      battleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}battle_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $XpEventsTable createAlias(String alias) {
    return $XpEventsTable(attachedDatabase, alias);
  }
}

class XpEvent extends DataClass implements Insertable<XpEvent> {
  final String eventId;
  final String source;
  final String battleId;
  final int amount;
  final String createdAt;
  const XpEvent({
    required this.eventId,
    required this.source,
    required this.battleId,
    required this.amount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['source'] = Variable<String>(source);
    map['battle_id'] = Variable<String>(battleId);
    map['amount'] = Variable<int>(amount);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  XpEventsCompanion toCompanion(bool nullToAbsent) {
    return XpEventsCompanion(
      eventId: Value(eventId),
      source: Value(source),
      battleId: Value(battleId),
      amount: Value(amount),
      createdAt: Value(createdAt),
    );
  }

  factory XpEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return XpEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      source: serializer.fromJson<String>(json['source']),
      battleId: serializer.fromJson<String>(json['battleId']),
      amount: serializer.fromJson<int>(json['amount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'source': serializer.toJson<String>(source),
      'battleId': serializer.toJson<String>(battleId),
      'amount': serializer.toJson<int>(amount),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  XpEvent copyWith({
    String? eventId,
    String? source,
    String? battleId,
    int? amount,
    String? createdAt,
  }) => XpEvent(
    eventId: eventId ?? this.eventId,
    source: source ?? this.source,
    battleId: battleId ?? this.battleId,
    amount: amount ?? this.amount,
    createdAt: createdAt ?? this.createdAt,
  );
  XpEvent copyWithCompanion(XpEventsCompanion data) {
    return XpEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      source: data.source.present ? data.source.value : this.source,
      battleId: data.battleId.present ? data.battleId.value : this.battleId,
      amount: data.amount.present ? data.amount.value : this.amount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('XpEvent(')
          ..write('eventId: $eventId, ')
          ..write('source: $source, ')
          ..write('battleId: $battleId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, source, battleId, amount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is XpEvent &&
          other.eventId == this.eventId &&
          other.source == this.source &&
          other.battleId == this.battleId &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt);
}

class XpEventsCompanion extends UpdateCompanion<XpEvent> {
  final Value<String> eventId;
  final Value<String> source;
  final Value<String> battleId;
  final Value<int> amount;
  final Value<String> createdAt;
  final Value<int> rowid;
  const XpEventsCompanion({
    this.eventId = const Value.absent(),
    this.source = const Value.absent(),
    this.battleId = const Value.absent(),
    this.amount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  XpEventsCompanion.insert({
    required String eventId,
    required String source,
    required String battleId,
    required int amount,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       source = Value(source),
       battleId = Value(battleId),
       amount = Value(amount),
       createdAt = Value(createdAt);
  static Insertable<XpEvent> custom({
    Expression<String>? eventId,
    Expression<String>? source,
    Expression<String>? battleId,
    Expression<int>? amount,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (source != null) 'source': source,
      if (battleId != null) 'battle_id': battleId,
      if (amount != null) 'amount': amount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  XpEventsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? source,
    Value<String>? battleId,
    Value<int>? amount,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return XpEventsCompanion(
      eventId: eventId ?? this.eventId,
      source: source ?? this.source,
      battleId: battleId ?? this.battleId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (battleId.present) {
      map['battle_id'] = Variable<String>(battleId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('XpEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('source: $source, ')
          ..write('battleId: $battleId, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitCompletionsTable habitCompletions = $HabitCompletionsTable(
    this,
  );
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $EquippedCosmeticsTable equippedCosmetics =
      $EquippedCosmeticsTable(this);
  late final $BattleRewardsClaimedTable battleRewardsClaimed =
      $BattleRewardsClaimedTable(this);
  late final $XpEventsTable xpEvents = $XpEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    habitCompletions,
    userSettings,
    equippedCosmetics,
    battleRewardsClaimed,
    xpEvents,
  ];
}

typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      required String id,
      required String name,
      Value<int> baseXp,
      required int createdAt,
      Value<int?> archivedAt,
      Value<int?> scheduleMask,
      Value<String> timeOfDay,
      Value<String> iconId,
      Value<String> iconPath,
      Value<int> rowid,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> baseXp,
      Value<int> createdAt,
      Value<int?> archivedAt,
      Value<int?> scheduleMask,
      Value<String> timeOfDay,
      Value<String> iconId,
      Value<String> iconPath,
      Value<int> rowid,
    });

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDb, $HabitsTable, Habit> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HabitCompletionsTable, List<HabitCompletion>>
  _habitCompletionsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.habitCompletions,
    aliasName: $_aliasNameGenerator(db.habits.id, db.habitCompletions.habitId),
  );

  $$HabitCompletionsTableProcessedTableManager get habitCompletionsRefs {
    final manager = $$HabitCompletionsTableTableManager(
      $_db,
      $_db.habitCompletions,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _habitCompletionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer extends Composer<_$AppDb, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseXp => $composableBuilder(
    column: $table.baseXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduleMask => $composableBuilder(
    column: $table.scheduleMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconId => $composableBuilder(
    column: $table.iconId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconPath => $composableBuilder(
    column: $table.iconPath,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> habitCompletionsRefs(
    Expression<bool> Function($$HabitCompletionsTableFilterComposer f) f,
  ) {
    final $$HabitCompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitCompletions,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitCompletionsTableFilterComposer(
            $db: $db,
            $table: $db.habitCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer extends Composer<_$AppDb, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseXp => $composableBuilder(
    column: $table.baseXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduleMask => $composableBuilder(
    column: $table.scheduleMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconId => $composableBuilder(
    column: $table.iconId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconPath => $composableBuilder(
    column: $table.iconPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer extends Composer<_$AppDb, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get baseXp =>
      $composableBuilder(column: $table.baseXp, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scheduleMask => $composableBuilder(
    column: $table.scheduleMask,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<String> get iconId =>
      $composableBuilder(column: $table.iconId, builder: (column) => column);

  GeneratedColumn<String> get iconPath =>
      $composableBuilder(column: $table.iconPath, builder: (column) => column);

  Expression<T> habitCompletionsRefs<T extends Object>(
    Expression<T> Function($$HabitCompletionsTableAnnotationComposer a) f,
  ) {
    final $$HabitCompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitCompletions,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitCompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, $$HabitsTableReferences),
          Habit,
          PrefetchHooks Function({bool habitCompletionsRefs})
        > {
  $$HabitsTableTableManager(_$AppDb db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> baseXp = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<int?> scheduleMask = const Value.absent(),
                Value<String> timeOfDay = const Value.absent(),
                Value<String> iconId = const Value.absent(),
                Value<String> iconPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                baseXp: baseXp,
                createdAt: createdAt,
                archivedAt: archivedAt,
                scheduleMask: scheduleMask,
                timeOfDay: timeOfDay,
                iconId: iconId,
                iconPath: iconPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> baseXp = const Value.absent(),
                required int createdAt,
                Value<int?> archivedAt = const Value.absent(),
                Value<int?> scheduleMask = const Value.absent(),
                Value<String> timeOfDay = const Value.absent(),
                Value<String> iconId = const Value.absent(),
                Value<String> iconPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                baseXp: baseXp,
                createdAt: createdAt,
                archivedAt: archivedAt,
                scheduleMask: scheduleMask,
                timeOfDay: timeOfDay,
                iconId: iconId,
                iconPath: iconPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$HabitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({habitCompletionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (habitCompletionsRefs) db.habitCompletions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (habitCompletionsRefs)
                    await $_getPrefetchedData<
                      Habit,
                      $HabitsTable,
                      HabitCompletion
                    >(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences
                          ._habitCompletionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$HabitsTableReferences(
                        db,
                        table,
                        p0,
                      ).habitCompletionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.habitId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, $$HabitsTableReferences),
      Habit,
      PrefetchHooks Function({bool habitCompletionsRefs})
    >;
typedef $$HabitCompletionsTableCreateCompanionBuilder =
    HabitCompletionsCompanion Function({
      required String id,
      required String habitId,
      required int completedAt,
      required String localDay,
      Value<int> rowid,
    });
typedef $$HabitCompletionsTableUpdateCompanionBuilder =
    HabitCompletionsCompanion Function({
      Value<String> id,
      Value<String> habitId,
      Value<int> completedAt,
      Value<String> localDay,
      Value<int> rowid,
    });

final class $$HabitCompletionsTableReferences
    extends BaseReferences<_$AppDb, $HabitCompletionsTable, HabitCompletion> {
  $$HabitCompletionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HabitsTable _habitIdTable(_$AppDb db) => db.habits.createAlias(
    $_aliasNameGenerator(db.habitCompletions.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitCompletionsTableFilterComposer
    extends Composer<_$AppDb, $HabitCompletionsTable> {
  $$HabitCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitCompletionsTableOrderingComposer
    extends Composer<_$AppDb, $HabitCompletionsTable> {
  $$HabitCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitCompletionsTableAnnotationComposer
    extends Composer<_$AppDb, $HabitCompletionsTable> {
  $$HabitCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDay =>
      $composableBuilder(column: $table.localDay, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitCompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $HabitCompletionsTable,
          HabitCompletion,
          $$HabitCompletionsTableFilterComposer,
          $$HabitCompletionsTableOrderingComposer,
          $$HabitCompletionsTableAnnotationComposer,
          $$HabitCompletionsTableCreateCompanionBuilder,
          $$HabitCompletionsTableUpdateCompanionBuilder,
          (HabitCompletion, $$HabitCompletionsTableReferences),
          HabitCompletion,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitCompletionsTableTableManager(_$AppDb db, $HabitCompletionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitCompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<int> completedAt = const Value.absent(),
                Value<String> localDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCompletionsCompanion(
                id: id,
                habitId: habitId,
                completedAt: completedAt,
                localDay: localDay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitId,
                required int completedAt,
                required String localDay,
                Value<int> rowid = const Value.absent(),
              }) => HabitCompletionsCompanion.insert(
                id: id,
                habitId: habitId,
                completedAt: completedAt,
                localDay: localDay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HabitCompletionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable:
                                    $$HabitCompletionsTableReferences
                                        ._habitIdTable(db),
                                referencedColumn:
                                    $$HabitCompletionsTableReferences
                                        ._habitIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitCompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $HabitCompletionsTable,
      HabitCompletion,
      $$HabitCompletionsTableFilterComposer,
      $$HabitCompletionsTableOrderingComposer,
      $$HabitCompletionsTableAnnotationComposer,
      $$HabitCompletionsTableCreateCompanionBuilder,
      $$HabitCompletionsTableUpdateCompanionBuilder,
      (HabitCompletion, $$HabitCompletionsTableReferences),
      HabitCompletion,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$UserSettingsTableCreateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<bool> soundEnabled,
      Value<String> soundPackId,
      Value<String> soundCompleteId,
      Value<String> soundLevelUpId,
      Value<String> soundEquipId,
      Value<String> soundCompletePath,
      Value<String> soundLevelUpPath,
      Value<String> soundEquipPath,
      Value<String> themeId,
      Value<String> profileAvatarMode,
      Value<String> profileAvatarPath,
    });
typedef $$UserSettingsTableUpdateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<bool> soundEnabled,
      Value<String> soundPackId,
      Value<String> soundCompleteId,
      Value<String> soundLevelUpId,
      Value<String> soundEquipId,
      Value<String> soundCompletePath,
      Value<String> soundLevelUpPath,
      Value<String> soundEquipPath,
      Value<String> themeId,
      Value<String> profileAvatarMode,
      Value<String> profileAvatarPath,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDb, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get soundEnabled => $composableBuilder(
    column: $table.soundEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundPackId => $composableBuilder(
    column: $table.soundPackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundCompleteId => $composableBuilder(
    column: $table.soundCompleteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundLevelUpId => $composableBuilder(
    column: $table.soundLevelUpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundEquipId => $composableBuilder(
    column: $table.soundEquipId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundCompletePath => $composableBuilder(
    column: $table.soundCompletePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundLevelUpPath => $composableBuilder(
    column: $table.soundLevelUpPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundEquipPath => $composableBuilder(
    column: $table.soundEquipPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileAvatarMode => $composableBuilder(
    column: $table.profileAvatarMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileAvatarPath => $composableBuilder(
    column: $table.profileAvatarPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDb, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get soundEnabled => $composableBuilder(
    column: $table.soundEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundPackId => $composableBuilder(
    column: $table.soundPackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundCompleteId => $composableBuilder(
    column: $table.soundCompleteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundLevelUpId => $composableBuilder(
    column: $table.soundLevelUpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundEquipId => $composableBuilder(
    column: $table.soundEquipId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundCompletePath => $composableBuilder(
    column: $table.soundCompletePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundLevelUpPath => $composableBuilder(
    column: $table.soundLevelUpPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundEquipPath => $composableBuilder(
    column: $table.soundEquipPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileAvatarMode => $composableBuilder(
    column: $table.profileAvatarMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileAvatarPath => $composableBuilder(
    column: $table.profileAvatarPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDb, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get soundEnabled => $composableBuilder(
    column: $table.soundEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundPackId => $composableBuilder(
    column: $table.soundPackId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundCompleteId => $composableBuilder(
    column: $table.soundCompleteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundLevelUpId => $composableBuilder(
    column: $table.soundLevelUpId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundEquipId => $composableBuilder(
    column: $table.soundEquipId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundCompletePath => $composableBuilder(
    column: $table.soundCompletePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundLevelUpPath => $composableBuilder(
    column: $table.soundLevelUpPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundEquipPath => $composableBuilder(
    column: $table.soundEquipPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeId =>
      $composableBuilder(column: $table.themeId, builder: (column) => column);

  GeneratedColumn<String> get profileAvatarMode => $composableBuilder(
    column: $table.profileAvatarMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profileAvatarPath => $composableBuilder(
    column: $table.profileAvatarPath,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $UserSettingsTable,
          UserSetting,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSetting,
            BaseReferences<_$AppDb, $UserSettingsTable, UserSetting>,
          ),
          UserSetting,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$AppDb db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> soundEnabled = const Value.absent(),
                Value<String> soundPackId = const Value.absent(),
                Value<String> soundCompleteId = const Value.absent(),
                Value<String> soundLevelUpId = const Value.absent(),
                Value<String> soundEquipId = const Value.absent(),
                Value<String> soundCompletePath = const Value.absent(),
                Value<String> soundLevelUpPath = const Value.absent(),
                Value<String> soundEquipPath = const Value.absent(),
                Value<String> themeId = const Value.absent(),
                Value<String> profileAvatarMode = const Value.absent(),
                Value<String> profileAvatarPath = const Value.absent(),
              }) => UserSettingsCompanion(
                id: id,
                soundEnabled: soundEnabled,
                soundPackId: soundPackId,
                soundCompleteId: soundCompleteId,
                soundLevelUpId: soundLevelUpId,
                soundEquipId: soundEquipId,
                soundCompletePath: soundCompletePath,
                soundLevelUpPath: soundLevelUpPath,
                soundEquipPath: soundEquipPath,
                themeId: themeId,
                profileAvatarMode: profileAvatarMode,
                profileAvatarPath: profileAvatarPath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> soundEnabled = const Value.absent(),
                Value<String> soundPackId = const Value.absent(),
                Value<String> soundCompleteId = const Value.absent(),
                Value<String> soundLevelUpId = const Value.absent(),
                Value<String> soundEquipId = const Value.absent(),
                Value<String> soundCompletePath = const Value.absent(),
                Value<String> soundLevelUpPath = const Value.absent(),
                Value<String> soundEquipPath = const Value.absent(),
                Value<String> themeId = const Value.absent(),
                Value<String> profileAvatarMode = const Value.absent(),
                Value<String> profileAvatarPath = const Value.absent(),
              }) => UserSettingsCompanion.insert(
                id: id,
                soundEnabled: soundEnabled,
                soundPackId: soundPackId,
                soundCompleteId: soundCompleteId,
                soundLevelUpId: soundLevelUpId,
                soundEquipId: soundEquipId,
                soundCompletePath: soundCompletePath,
                soundLevelUpPath: soundLevelUpPath,
                soundEquipPath: soundEquipPath,
                themeId: themeId,
                profileAvatarMode: profileAvatarMode,
                profileAvatarPath: profileAvatarPath,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $UserSettingsTable,
      UserSetting,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (UserSetting, BaseReferences<_$AppDb, $UserSettingsTable, UserSetting>),
      UserSetting,
      PrefetchHooks Function()
    >;
typedef $$EquippedCosmeticsTableCreateCompanionBuilder =
    EquippedCosmeticsCompanion Function({
      required String slot,
      required String cosmeticId,
      Value<int> rowid,
    });
typedef $$EquippedCosmeticsTableUpdateCompanionBuilder =
    EquippedCosmeticsCompanion Function({
      Value<String> slot,
      Value<String> cosmeticId,
      Value<int> rowid,
    });

class $$EquippedCosmeticsTableFilterComposer
    extends Composer<_$AppDb, $EquippedCosmeticsTable> {
  $$EquippedCosmeticsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cosmeticId => $composableBuilder(
    column: $table.cosmeticId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EquippedCosmeticsTableOrderingComposer
    extends Composer<_$AppDb, $EquippedCosmeticsTable> {
  $$EquippedCosmeticsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cosmeticId => $composableBuilder(
    column: $table.cosmeticId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EquippedCosmeticsTableAnnotationComposer
    extends Composer<_$AppDb, $EquippedCosmeticsTable> {
  $$EquippedCosmeticsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get cosmeticId => $composableBuilder(
    column: $table.cosmeticId,
    builder: (column) => column,
  );
}

class $$EquippedCosmeticsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $EquippedCosmeticsTable,
          EquippedCosmetic,
          $$EquippedCosmeticsTableFilterComposer,
          $$EquippedCosmeticsTableOrderingComposer,
          $$EquippedCosmeticsTableAnnotationComposer,
          $$EquippedCosmeticsTableCreateCompanionBuilder,
          $$EquippedCosmeticsTableUpdateCompanionBuilder,
          (
            EquippedCosmetic,
            BaseReferences<_$AppDb, $EquippedCosmeticsTable, EquippedCosmetic>,
          ),
          EquippedCosmetic,
          PrefetchHooks Function()
        > {
  $$EquippedCosmeticsTableTableManager(
    _$AppDb db,
    $EquippedCosmeticsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EquippedCosmeticsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EquippedCosmeticsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EquippedCosmeticsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> slot = const Value.absent(),
                Value<String> cosmeticId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EquippedCosmeticsCompanion(
                slot: slot,
                cosmeticId: cosmeticId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slot,
                required String cosmeticId,
                Value<int> rowid = const Value.absent(),
              }) => EquippedCosmeticsCompanion.insert(
                slot: slot,
                cosmeticId: cosmeticId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EquippedCosmeticsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $EquippedCosmeticsTable,
      EquippedCosmetic,
      $$EquippedCosmeticsTableFilterComposer,
      $$EquippedCosmeticsTableOrderingComposer,
      $$EquippedCosmeticsTableAnnotationComposer,
      $$EquippedCosmeticsTableCreateCompanionBuilder,
      $$EquippedCosmeticsTableUpdateCompanionBuilder,
      (
        EquippedCosmetic,
        BaseReferences<_$AppDb, $EquippedCosmeticsTable, EquippedCosmetic>,
      ),
      EquippedCosmetic,
      PrefetchHooks Function()
    >;
typedef $$BattleRewardsClaimedTableCreateCompanionBuilder =
    BattleRewardsClaimedCompanion Function({
      required String battleId,
      required int milestone,
      required String claimedAt,
      Value<int> rowid,
    });
typedef $$BattleRewardsClaimedTableUpdateCompanionBuilder =
    BattleRewardsClaimedCompanion Function({
      Value<String> battleId,
      Value<int> milestone,
      Value<String> claimedAt,
      Value<int> rowid,
    });

class $$BattleRewardsClaimedTableFilterComposer
    extends Composer<_$AppDb, $BattleRewardsClaimedTable> {
  $$BattleRewardsClaimedTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get battleId => $composableBuilder(
    column: $table.battleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get milestone => $composableBuilder(
    column: $table.milestone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimedAt => $composableBuilder(
    column: $table.claimedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BattleRewardsClaimedTableOrderingComposer
    extends Composer<_$AppDb, $BattleRewardsClaimedTable> {
  $$BattleRewardsClaimedTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get battleId => $composableBuilder(
    column: $table.battleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get milestone => $composableBuilder(
    column: $table.milestone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimedAt => $composableBuilder(
    column: $table.claimedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BattleRewardsClaimedTableAnnotationComposer
    extends Composer<_$AppDb, $BattleRewardsClaimedTable> {
  $$BattleRewardsClaimedTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get battleId =>
      $composableBuilder(column: $table.battleId, builder: (column) => column);

  GeneratedColumn<int> get milestone =>
      $composableBuilder(column: $table.milestone, builder: (column) => column);

  GeneratedColumn<String> get claimedAt =>
      $composableBuilder(column: $table.claimedAt, builder: (column) => column);
}

class $$BattleRewardsClaimedTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $BattleRewardsClaimedTable,
          BattleRewardsClaimedData,
          $$BattleRewardsClaimedTableFilterComposer,
          $$BattleRewardsClaimedTableOrderingComposer,
          $$BattleRewardsClaimedTableAnnotationComposer,
          $$BattleRewardsClaimedTableCreateCompanionBuilder,
          $$BattleRewardsClaimedTableUpdateCompanionBuilder,
          (
            BattleRewardsClaimedData,
            BaseReferences<
              _$AppDb,
              $BattleRewardsClaimedTable,
              BattleRewardsClaimedData
            >,
          ),
          BattleRewardsClaimedData,
          PrefetchHooks Function()
        > {
  $$BattleRewardsClaimedTableTableManager(
    _$AppDb db,
    $BattleRewardsClaimedTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BattleRewardsClaimedTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BattleRewardsClaimedTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BattleRewardsClaimedTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> battleId = const Value.absent(),
                Value<int> milestone = const Value.absent(),
                Value<String> claimedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BattleRewardsClaimedCompanion(
                battleId: battleId,
                milestone: milestone,
                claimedAt: claimedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String battleId,
                required int milestone,
                required String claimedAt,
                Value<int> rowid = const Value.absent(),
              }) => BattleRewardsClaimedCompanion.insert(
                battleId: battleId,
                milestone: milestone,
                claimedAt: claimedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BattleRewardsClaimedTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $BattleRewardsClaimedTable,
      BattleRewardsClaimedData,
      $$BattleRewardsClaimedTableFilterComposer,
      $$BattleRewardsClaimedTableOrderingComposer,
      $$BattleRewardsClaimedTableAnnotationComposer,
      $$BattleRewardsClaimedTableCreateCompanionBuilder,
      $$BattleRewardsClaimedTableUpdateCompanionBuilder,
      (
        BattleRewardsClaimedData,
        BaseReferences<
          _$AppDb,
          $BattleRewardsClaimedTable,
          BattleRewardsClaimedData
        >,
      ),
      BattleRewardsClaimedData,
      PrefetchHooks Function()
    >;
typedef $$XpEventsTableCreateCompanionBuilder =
    XpEventsCompanion Function({
      required String eventId,
      required String source,
      required String battleId,
      required int amount,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$XpEventsTableUpdateCompanionBuilder =
    XpEventsCompanion Function({
      Value<String> eventId,
      Value<String> source,
      Value<String> battleId,
      Value<int> amount,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$XpEventsTableFilterComposer extends Composer<_$AppDb, $XpEventsTable> {
  $$XpEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get battleId => $composableBuilder(
    column: $table.battleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$XpEventsTableOrderingComposer
    extends Composer<_$AppDb, $XpEventsTable> {
  $$XpEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get battleId => $composableBuilder(
    column: $table.battleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$XpEventsTableAnnotationComposer
    extends Composer<_$AppDb, $XpEventsTable> {
  $$XpEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get battleId =>
      $composableBuilder(column: $table.battleId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$XpEventsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $XpEventsTable,
          XpEvent,
          $$XpEventsTableFilterComposer,
          $$XpEventsTableOrderingComposer,
          $$XpEventsTableAnnotationComposer,
          $$XpEventsTableCreateCompanionBuilder,
          $$XpEventsTableUpdateCompanionBuilder,
          (XpEvent, BaseReferences<_$AppDb, $XpEventsTable, XpEvent>),
          XpEvent,
          PrefetchHooks Function()
        > {
  $$XpEventsTableTableManager(_$AppDb db, $XpEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$XpEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$XpEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$XpEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> battleId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => XpEventsCompanion(
                eventId: eventId,
                source: source,
                battleId: battleId,
                amount: amount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String source,
                required String battleId,
                required int amount,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => XpEventsCompanion.insert(
                eventId: eventId,
                source: source,
                battleId: battleId,
                amount: amount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$XpEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $XpEventsTable,
      XpEvent,
      $$XpEventsTableFilterComposer,
      $$XpEventsTableOrderingComposer,
      $$XpEventsTableAnnotationComposer,
      $$XpEventsTableCreateCompanionBuilder,
      $$XpEventsTableUpdateCompanionBuilder,
      (XpEvent, BaseReferences<_$AppDb, $XpEventsTable, XpEvent>),
      XpEvent,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$HabitCompletionsTableTableManager get habitCompletions =>
      $$HabitCompletionsTableTableManager(_db, _db.habitCompletions);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$EquippedCosmeticsTableTableManager get equippedCosmetics =>
      $$EquippedCosmeticsTableTableManager(_db, _db.equippedCosmetics);
  $$BattleRewardsClaimedTableTableManager get battleRewardsClaimed =>
      $$BattleRewardsClaimedTableTableManager(_db, _db.battleRewardsClaimed);
  $$XpEventsTableTableManager get xpEvents =>
      $$XpEventsTableTableManager(_db, _db.xpEvents);
}
