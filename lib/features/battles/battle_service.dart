import '../../shared/local_day.dart';
import '../avatar/avatar_repository.dart';
import '../habits/habit_repository.dart';

class BattleStats {
  const BattleStats({
    required this.id,
    required this.start,
    required this.endExclusive,
    required this.scheduledTotal,
    required this.completedTotal,
    required this.density,
    required this.rawDamage,
    required this.equipPct,
    required this.equipPctCapped,
    required this.damage,
    required this.expectedDamage,
    required this.hp,
    required this.progressPct,
    required this.earnedXpWindow,
    required this.daysLeft,
  });

  final String id;
  final DateTime start;
  final DateTime endExclusive;
  final int scheduledTotal;
  final int completedTotal;
  final double density;
  final int rawDamage;
  final double equipPct;
  final double equipPctCapped;
  final int damage;
  final int expectedDamage;
  final int hp;
  final double progressPct;
  final int earnedXpWindow;
  final int daysLeft;
}

class BattleService {
  BattleService(this.repo, this.avatarRepo);
  final HabitRepository repo;
  final AvatarRepository avatarRepo;

  static const double equipCap = 0.15;
  static const double weekMultiplier = 1.15;
  static const double monthMultiplier = 1.25;

  int _baseDamageForHabit(int baseXp) {
    final dmg = 8 + (baseXp ~/ 5);
    if (dmg < 8) return 8;
    if (dmg > 14) return 14;
    return dmg;
  }

  bool _isScheduled(DateTime date, int? scheduleMask) {
    if (scheduleMask == null) return true;
    if (scheduleMask == 0) return false;
    final bit = 1 << (date.weekday - 1);
    return (scheduleMask & bit) != 0;
  }

  Future<double> _equipBonusPct() async {
    final equipped = await avatarRepo.getEquipped();
    if (equipped.isEmpty) return 0.0;
    var sum = 0.0;
    final byId = {
      for (final item in AvatarRepository.catalog) item.id: item
    };
    for (final id in equipped.values) {
      final item = byId[id];
      if (item == null) continue;
      if (!item.damageEligible) continue;
      sum += item.damageBonusPct;
    }
    return sum;
  }

  String weeklyBattleId(DateTime weekStart) {
    return 'week_${localDay(weekStart)}';
  }

  String monthlyBattleId(DateTime monthStart) {
    final y = monthStart.year.toString().padLeft(4, '0');
    final m = monthStart.month.toString().padLeft(2, '0');
    return 'month_$y-$m';
  }

  Future<BattleStats> computeWeekly() async {
    final now = DateTime.now();
    final offset = now.weekday - DateTime.monday;
    final weekStart = startOfLocalDay(now).subtract(Duration(days: offset));
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    final id = weeklyBattleId(weekStart);
    return _computeWindow(id, weekStart, weekEndExclusive, weekMultiplier);
  }

  Future<BattleStats> computeMonthly() async {
    final now = DateTime.now();
    final monthStart = startOfLocalDay(DateTime(now.year, now.month, 1));
    final monthEndExclusive =
        startOfLocalDay(DateTime(now.year, now.month + 1, 1));
    final id = monthlyBattleId(monthStart);
    return _computeWindow(id, monthStart, monthEndExclusive, monthMultiplier);
  }

  Future<BattleStats> _computeWindow(
    String id,
    DateTime start,
    DateTime endExclusive,
    double multiplier,
  ) async {
    final habits = await repo.listHabits();
    final habitIds = habits.map((h) => h.id).toList();
    final completionsByHabit =
        await repo.getCompletionDaysForRangeByHabit(
      start,
      endExclusive,
      habitIds: habitIds,
    );

    var scheduledTotal = 0;
    var completedTotal = 0;
    var rawDamage = 0;
    var expectedDamage = 0;
    var earnedXpWindow = 0;

    for (final habit in habits) {
      final completedDays = completionsByHabit[habit.id] ?? const <String>{};
      var scheduled = 0;
      var completed = 0;
      for (var d = start;
          d.isBefore(endExclusive);
          d = d.add(const Duration(days: 1))) {
        if (!_isScheduled(d, habit.scheduleMask)) continue;
        scheduledTotal += 1;
        scheduled += 1;
        if (completedDays.contains(localDay(d))) {
          completedTotal += 1;
          completed += 1;
        }
      }
      if (scheduled == 0) continue;
      final baseXp = habit.baseXp;
      final baseDamage = _baseDamageForHabit(baseXp);
      rawDamage += completed * baseDamage;
      expectedDamage += scheduled * baseDamage;
      earnedXpWindow += completed * baseXp;
    }

    final equipPct = await _equipBonusPct();
    final equipPctCapped = equipPct > equipCap ? equipCap : equipPct;
    final damage = (rawDamage * (1 + equipPctCapped)).round();
    final hp = expectedDamage == 0 ? 0 : (expectedDamage * multiplier).ceil();
    final progressPct =
        hp == 0 ? 0.0 : (damage / hp).clamp(0.0, 1.0);
    final density =
        scheduledTotal == 0 ? 0.0 : completedTotal / scheduledTotal;
    final daysLeft =
        endExclusive.difference(startOfLocalDay(DateTime.now())).inDays;

    return BattleStats(
      id: id,
      start: start,
      endExclusive: endExclusive,
      scheduledTotal: scheduledTotal,
      completedTotal: completedTotal,
      density: density,
      rawDamage: rawDamage,
      equipPct: equipPct,
      equipPctCapped: equipPctCapped,
      damage: damage,
      expectedDamage: expectedDamage,
      hp: hp,
      progressPct: progressPct,
      earnedXpWindow: earnedXpWindow,
      daysLeft: daysLeft < 0 ? 0 : daysLeft,
    );
  }
}
