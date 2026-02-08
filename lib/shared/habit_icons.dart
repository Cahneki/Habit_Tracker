import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum HabitIconTone {
  water,
  read,
  sleep,
  run,
  lift,
  neutral,
  primary,
  secondary,
  tertiary,
  error,
}

class HabitIconOption {
  const HabitIconOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.tone,
  });

  final String id;
  final String label;
  final IconData icon;
  final HabitIconTone tone;
}

const List<HabitIconOption> habitIconOptions = [
  HabitIconOption(
    id: 'magic',
    label: 'Magic',
    icon: Icons.auto_awesome_rounded,
    tone: HabitIconTone.primary,
  ),
  HabitIconOption(
    id: 'custom',
    label: 'Custom',
    icon: Icons.add_photo_alternate_rounded,
    tone: HabitIconTone.neutral,
  ),
  HabitIconOption(
    id: 'battle',
    label: 'Battle',
    icon: Icons.sports_martial_arts_rounded,
    tone: HabitIconTone.error,
  ),
  HabitIconOption(
    id: 'shield',
    label: 'Shield',
    icon: Icons.shield_rounded,
    tone: HabitIconTone.secondary,
  ),
  HabitIconOption(
    id: 'sword',
    label: 'Blade',
    icon: Icons.gavel_rounded,
    tone: HabitIconTone.tertiary,
  ),
  HabitIconOption(
    id: 'fire',
    label: 'Fire',
    icon: Icons.local_fire_department_rounded,
    tone: HabitIconTone.error,
  ),
  HabitIconOption(
    id: 'bolt',
    label: 'Bolt',
    icon: Icons.flash_on_rounded,
    tone: HabitIconTone.tertiary,
  ),
  HabitIconOption(
    id: 'skull',
    label: 'Skull',
    icon: Icons.emoji_nature_rounded,
    tone: HabitIconTone.error,
  ),
  HabitIconOption(
    id: 'potion',
    label: 'Potion',
    icon: Icons.local_drink_rounded,
    tone: HabitIconTone.secondary,
  ),
  HabitIconOption(
    id: 'alchemy',
    label: 'Alchemy',
    icon: Icons.science_rounded,
    tone: HabitIconTone.tertiary,
  ),
  HabitIconOption(
    id: 'map',
    label: 'Map',
    icon: Icons.map_rounded,
    tone: HabitIconTone.primary,
  ),
  HabitIconOption(
    id: 'camp',
    label: 'Camp',
    icon: Icons.park_rounded,
    tone: HabitIconTone.secondary,
  ),
  HabitIconOption(
    id: 'coin',
    label: 'Coin',
    icon: Icons.monetization_on_rounded,
    tone: HabitIconTone.tertiary,
  ),
  HabitIconOption(
    id: 'crown',
    label: 'Crown',
    icon: Icons.emoji_events_rounded,
    tone: HabitIconTone.primary,
  ),
  HabitIconOption(
    id: 'quest',
    label: 'Quest',
    icon: Icons.flag_rounded,
    tone: HabitIconTone.secondary,
  ),
  HabitIconOption(
    id: 'scroll',
    label: 'Scroll',
    icon: Icons.description_rounded,
    tone: HabitIconTone.tertiary,
  ),
  HabitIconOption(
    id: 'water',
    label: 'Water',
    icon: Icons.water_drop_rounded,
    tone: HabitIconTone.water,
  ),
  HabitIconOption(
    id: 'read',
    label: 'Read',
    icon: Icons.menu_book_rounded,
    tone: HabitIconTone.read,
  ),
  HabitIconOption(
    id: 'sleep',
    label: 'Sleep',
    icon: Icons.bedtime_rounded,
    tone: HabitIconTone.sleep,
  ),
  HabitIconOption(
    id: 'run',
    label: 'Run',
    icon: Icons.directions_run_rounded,
    tone: HabitIconTone.run,
  ),
  HabitIconOption(
    id: 'lift',
    label: 'Lift',
    icon: Icons.fitness_center_rounded,
    tone: HabitIconTone.lift,
  ),
  HabitIconOption(
    id: 'meditate',
    label: 'Mind',
    icon: Icons.self_improvement_rounded,
    tone: HabitIconTone.secondary,
  ),
  HabitIconOption(
    id: 'focus',
    label: 'Focus',
    icon: Icons.center_focus_strong_rounded,
    tone: HabitIconTone.primary,
  ),
  HabitIconOption(
    id: 'heart',
    label: 'Heart',
    icon: Icons.favorite_rounded,
    tone: HabitIconTone.error,
  ),
  HabitIconOption(
    id: 'food',
    label: 'Food',
    icon: Icons.restaurant_rounded,
    tone: HabitIconTone.tertiary,
  ),
  HabitIconOption(
    id: 'music',
    label: 'Music',
    icon: Icons.music_note_rounded,
    tone: HabitIconTone.primary,
  ),
  HabitIconOption(
    id: 'code',
    label: 'Code',
    icon: Icons.code_rounded,
    tone: HabitIconTone.tertiary,
  ),
  HabitIconOption(
    id: 'craft',
    label: 'Craft',
    icon: Icons.build_rounded,
    tone: HabitIconTone.secondary,
  ),
];

IconData iconForHabit(String? iconId, String name) {
  final id = iconId?.trim();
  if (id != null && id.isNotEmpty) {
    final match = habitIconOptions.where((o) => o.id == id);
    if (match.isNotEmpty) return match.first.icon;
  }
  final lower = name.toLowerCase();
  if (lower.contains('run') || lower.contains('cardio')) {
    return Icons.directions_run_rounded;
  }
  if (lower.contains('water') || lower.contains('hydrate')) {
    return Icons.water_drop_rounded;
  }
  if (lower.contains('read') || lower.contains('book')) {
    return Icons.menu_book_rounded;
  }
  if (lower.contains('medit') || lower.contains('yoga')) {
    return Icons.self_improvement_rounded;
  }
  if (lower.contains('sleep')) return Icons.bedtime_rounded;
  if (lower.contains('lift') || lower.contains('gym') || lower.contains('workout')) {
    return Icons.fitness_center_rounded;
  }
  return Icons.auto_awesome_rounded;
}

Color toneColor(HabitIconTone tone, ColorScheme scheme, GameTokens tokens) {
  switch (tone) {
    case HabitIconTone.water:
      return tokens.habitWater;
    case HabitIconTone.read:
      return tokens.habitRead;
    case HabitIconTone.sleep:
      return tokens.habitSleep;
    case HabitIconTone.run:
      return tokens.habitRun;
    case HabitIconTone.lift:
      return tokens.habitLift;
    case HabitIconTone.primary:
      return scheme.primary;
    case HabitIconTone.secondary:
      return scheme.secondary;
    case HabitIconTone.tertiary:
      return scheme.tertiary;
    case HabitIconTone.error:
      return scheme.error;
    case HabitIconTone.neutral:
      return tokens.habitDefault;
  }
}

Color iconColorForHabit(
  String? iconId,
  String name,
  ColorScheme scheme,
  GameTokens tokens,
) {
  final id = iconId?.trim();
  if (id != null && id.isNotEmpty) {
    final match = habitIconOptions.where((o) => o.id == id);
    if (match.isNotEmpty) {
      return toneColor(match.first.tone, scheme, tokens);
    }
  }
  final lower = name.toLowerCase();
  if (lower.contains('water') || lower.contains('hydrate')) {
    return tokens.habitWater;
  }
  if (lower.contains('read') || lower.contains('book')) {
    return tokens.habitRead;
  }
  if (lower.contains('sleep')) return tokens.habitSleep;
  if (lower.contains('run') || lower.contains('cardio')) {
    return tokens.habitRun;
  }
  if (lower.contains('lift') || lower.contains('gym') || lower.contains('workout')) {
    return tokens.habitLift;
  }
  return tokens.habitDefault;
}
