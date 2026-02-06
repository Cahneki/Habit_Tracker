import 'package:drift/drift.dart';
import '../../db/app_db.dart';

class BattleRewardsRepository {
  BattleRewardsRepository(this.db);
  final AppDb db;

  Future<Set<int>> claimedMilestones(String battleId) async {
    final rows = await (db.select(db.battleRewardsClaimed)
          ..where((r) => r.battleId.equals(battleId)))
        .get();
    return rows.map((r) => r.milestone).toSet();
  }

  Future<void> claim(String battleId, int milestone, int xpAmount) async {
    await db.transaction(() async {
      await db.into(db.battleRewardsClaimed).insert(
            BattleRewardsClaimedCompanion.insert(
              battleId: battleId,
              milestone: milestone,
              claimedAt: DateTime.now().toIso8601String(),
            ),
            mode: InsertMode.insertOrIgnore,
          );

      final eventId = 'battle_${battleId}_$milestone';
      await db.into(db.xpEvents).insert(
            XpEventsCompanion.insert(
              eventId: eventId,
              source: 'battle',
              battleId: battleId,
              amount: xpAmount,
              createdAt: DateTime.now().toIso8601String(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    });
  }
}
