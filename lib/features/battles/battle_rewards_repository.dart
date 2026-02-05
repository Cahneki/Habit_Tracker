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

  Future<void> claim(String battleId, int milestone) async {
    await db.into(db.battleRewardsClaimed).insert(
          BattleRewardsClaimedCompanion.insert(
            battleId: battleId,
            milestone: milestone,
            claimedAt: DateTime.now().toIso8601String(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
