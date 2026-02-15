enum QuestActionType { attack, charge, guard, loot }

class QuestCompletionRecord {
  const QuestCompletionRecord({
    required this.habitId,
    required this.localDay,
    required this.completedAt,
    required this.actionType,
    this.lootSuccess,
  });

  final String habitId;
  final String localDay;
  final DateTime completedAt;
  final QuestActionType actionType;
  final bool? lootSuccess;
}

class TodayActionEffects {
  const TodayActionEffects({
    required this.pendingBossDamage,
    required this.storedPower,
    required this.guardUsed,
    required this.lootSuccess,
  });

  final bool pendingBossDamage;
  final int storedPower;
  final bool guardUsed;
  final bool lootSuccess;
}

extension QuestActionTypeX on QuestActionType {
  String get storageValue => name;

  String get label {
    switch (this) {
      case QuestActionType.attack:
        return 'Attacked Boss';
      case QuestActionType.charge:
        return 'Charged Power';
      case QuestActionType.guard:
        return 'Guarded';
      case QuestActionType.loot:
        return 'Looted';
    }
  }

  String get shortLabel {
    switch (this) {
      case QuestActionType.attack:
        return 'Attack Boss';
      case QuestActionType.charge:
        return 'Charge Power';
      case QuestActionType.guard:
        return 'Guard';
      case QuestActionType.loot:
        return 'Loot Roll';
    }
  }

  String get description {
    switch (this) {
      case QuestActionType.attack:
        return 'Deal damage based on today\'s intent';
      case QuestActionType.charge:
        return 'Store power for later';
      case QuestActionType.guard:
        return 'Protect your streak';
      case QuestActionType.loot:
        return 'Chance to gain an item';
    }
  }

  String get emoji {
    switch (this) {
      case QuestActionType.attack:
        return '⚔️';
      case QuestActionType.charge:
        return '🔋';
      case QuestActionType.guard:
        return '🛡';
      case QuestActionType.loot:
        return '🎁';
    }
  }
}

QuestActionType questActionTypeFromStorage(String raw) {
  for (final action in QuestActionType.values) {
    if (action.storageValue == raw) return action;
  }
  return QuestActionType.attack;
}
