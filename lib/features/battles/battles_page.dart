import 'package:flutter/material.dart';
import '../avatar/avatar_repository.dart';
import '../habits/habit_repository.dart';
import 'battle_rewards_repository.dart';
import 'battle_service.dart';

class BattlesPage extends StatefulWidget {
  const BattlesPage({
    super.key,
    required this.repo,
    required this.avatarRepo,
    required this.rewardsRepo,
    required this.dataVersion,
    required this.onDataChanged,
  });

  final HabitRepository repo;
  final AvatarRepository avatarRepo;
  final BattleRewardsRepository rewardsRepo;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;

  @override
  State<BattlesPage> createState() => _BattlesPageState();
}

class _BattleVm {
  const _BattleVm({
    required this.weekly,
    required this.monthly,
    required this.weeklyClaimed,
    required this.monthlyClaimed,
  });

  final BattleStats weekly;
  final BattleStats monthly;
  final Set<int> weeklyClaimed;
  final Set<int> monthlyClaimed;
}

class _BattlesPageState extends State<BattlesPage> {
  late Future<_BattleVm> _future;
  late final VoidCallback _dataListener;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _dataListener = _refresh;
    widget.dataVersion.addListener(_dataListener);
  }

  @override
  void dispose() {
    widget.dataVersion.removeListener(_dataListener);
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<_BattleVm> _load() async {
    final service = BattleService(widget.repo, widget.avatarRepo);
    final weekly = await service.computeWeekly();
    final monthly = await service.computeMonthly();
    final weeklyClaimed =
        await widget.rewardsRepo.claimedMilestones(weekly.id);
    final monthlyClaimed =
        await widget.rewardsRepo.claimedMilestones(monthly.id);
    return _BattleVm(
      weekly: weekly,
      monthly: monthly,
      weeklyClaimed: weeklyClaimed,
      monthlyClaimed: monthlyClaimed,
    );
  }

  Future<void> _claim(BattleStats stats, int milestone, double bonusPct) async {
    final xpAmount =
        (stats.earnedXpWindow * bonusPct * (milestone / 100.0)).round();
    await widget.rewardsRepo.claim(stats.id, milestone, xpAmount);
    _refresh();
    widget.onDataChanged();
  }

  Widget _battleCard({
    required String title,
    required BattleStats stats,
    required Set<int> claimed,
    required double bonusPct,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final hasSchedule = stats.scheduledTotal > 0 && stats.hp > 0;
    final percent = (stats.progressPct * 100).round();
    final densityPct = (stats.density * 100).round();
    final xpBonus = (stats.earnedXpWindow * bonusPct).round();
    const epsilon = 1e-9;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(
                  '${stats.daysLeft}d left',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!hasSchedule) ...[
              Text(
                'No scheduled quests in this window.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ] else ...[
              Text(
                'Damage ${stats.damage} / ${stats.hp}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stats.progressPct,
                  minHeight: 10,
                  backgroundColor: scheme.surface,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('$percent% complete'),
                  const Spacer(),
                  Text(
                    'Density: $densityPct% (${stats.completedTotal}/${stats.scheduledTotal})',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'XP bonus: +$xpBonus total (claimable)',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [50, 75, 100].map((m) {
                  final eligible = stats.progressPct + epsilon >= (m / 100.0);
                  final isClaimed = claimed.contains(m);
                  final label =
                      isClaimed ? 'Claimed' : (eligible ? 'Claim' : 'Locked');
                  return SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: eligible && !isClaimed
                          ? () => _claim(stats, m, bonusPct)
                          : null,
                      child: Text('$m% $label'),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Battles')),
      body: FutureBuilder<_BattleVm>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _battleCard(
                title: 'Weekly Boss',
                stats: vm.weekly,
                claimed: vm.weeklyClaimed,
                bonusPct: 0.10,
              ),
              const SizedBox(height: 16),
              _battleCard(
                title: 'Monthly Boss',
                stats: vm.monthly,
                claimed: vm.monthlyClaimed,
                bonusPct: 0.15,
              ),
            ],
          );
        },
      ),
    );
  }
}
