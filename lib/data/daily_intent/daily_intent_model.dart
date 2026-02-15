import 'package:flutter/material.dart';

enum DailyIntentType { power, growth, safety, loot }

class DailyIntentSelection {
  const DailyIntentSelection({
    required this.dateKey,
    required this.intent,
    required this.selectedAt,
  });

  final String dateKey;
  final DailyIntentType intent;
  final DateTime selectedAt;
}

extension DailyIntentTypeX on DailyIntentType {
  String get storageValue => name;

  String get label {
    switch (this) {
      case DailyIntentType.power:
        return 'Power';
      case DailyIntentType.growth:
        return 'Growth';
      case DailyIntentType.safety:
        return 'Safety';
      case DailyIntentType.loot:
        return 'Loot';
    }
  }

  String get summaryDescription {
    switch (this) {
      case DailyIntentType.power:
        return 'More boss damage';
      case DailyIntentType.growth:
        return 'More XP';
      case DailyIntentType.safety:
        return 'Streak protection';
      case DailyIntentType.loot:
        return 'Better drops';
    }
  }

  String get selectedDescription {
    switch (this) {
      case DailyIntentType.power:
        return 'Boss damage increased today';
      case DailyIntentType.growth:
        return 'XP gains emphasized today';
      case DailyIntentType.safety:
        return 'Streak safeguards emphasized today';
      case DailyIntentType.loot:
        return 'Loot quality emphasized today';
    }
  }

  IconData get icon {
    switch (this) {
      case DailyIntentType.power:
        return Icons.gavel_rounded;
      case DailyIntentType.growth:
        return Icons.trending_up_rounded;
      case DailyIntentType.safety:
        return Icons.shield_rounded;
      case DailyIntentType.loot:
        return Icons.redeem_rounded;
    }
  }
}

DailyIntentType? dailyIntentTypeFromStorage(String raw) {
  for (final intent in DailyIntentType.values) {
    if (intent.storageValue == raw) return intent;
  }
  return null;
}
