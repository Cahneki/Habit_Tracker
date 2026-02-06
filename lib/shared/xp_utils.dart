int xpGoalFor(int xp) {
  if (xp <= 0) return 1000;
  return ((xp / 1000).floor() + 1) * 1000;
}

int levelForXp(int xp) {
  return (xp ~/ 1000) + 1;
}

String rankTitleForLevel(int level) {
  if (level <= 5) return 'Bronze';
  if (level <= 10) return 'Silver';
  if (level <= 20) return 'Gold';
  if (level <= 30) return 'Platinum';
  if (level <= 45) return 'Diamond';
  return 'Mythic';
}
