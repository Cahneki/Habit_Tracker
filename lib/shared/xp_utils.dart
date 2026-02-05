int xpGoalFor(int xp) {
  if (xp <= 0) return 1000;
  return ((xp / 1000).floor() + 1) * 1000;
}

int levelForXp(int xp) {
  return (xp ~/ 1000) + 1;
}

String rankTitleForLevel(int level) {
  if (level < 5) return 'Wanderer';
  if (level < 10) return 'Paladin Apprentice';
  if (level < 15) return 'Knight Adept';
  if (level < 20) return 'Paladin Captain';
  return 'Legendary Hero';
}
