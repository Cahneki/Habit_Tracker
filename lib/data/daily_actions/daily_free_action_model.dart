enum DailyFreeActionType { scout, train, prepare }

class DailyFreeActionRecord {
  const DailyFreeActionRecord({
    required this.dateKey,
    required this.actionType,
    required this.performedAt,
  });

  final String dateKey;
  final DailyFreeActionType actionType;
  final DateTime performedAt;
}

extension DailyFreeActionTypeX on DailyFreeActionType {
  String get storageValue => name;

  String get title {
    switch (this) {
      case DailyFreeActionType.scout:
        return 'Scout Encounter';
      case DailyFreeActionType.train:
        return 'Train';
      case DailyFreeActionType.prepare:
        return 'Prepare';
    }
  }

  String get description {
    switch (this) {
      case DailyFreeActionType.scout:
        return 'Reveal a weakness for today';
      case DailyFreeActionType.train:
        return 'Gain a small amount of XP';
      case DailyFreeActionType.prepare:
        return 'Store power for your next quest';
    }
  }

  String get emoji {
    switch (this) {
      case DailyFreeActionType.scout:
        return '🧭';
      case DailyFreeActionType.train:
        return '🏋️';
      case DailyFreeActionType.prepare:
        return '🔋';
    }
  }

  String get logLabel {
    switch (this) {
      case DailyFreeActionType.scout:
        return 'Scouted Encounter';
      case DailyFreeActionType.train:
        return 'Trained (+5 XP)';
      case DailyFreeActionType.prepare:
        return 'Prepared (Power stored)';
    }
  }
}

DailyFreeActionType? dailyFreeActionTypeFromStorage(String raw) {
  for (final action in DailyFreeActionType.values) {
    if (action.storageValue == raw) return action;
  }
  return null;
}
