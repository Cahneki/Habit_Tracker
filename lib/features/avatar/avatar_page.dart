import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../shared/xp_utils.dart';
import 'avatar_repository.dart';
import '../habits/habit_repository.dart';

class AvatarPage extends StatefulWidget {
  const AvatarPage({
    super.key,
    required this.repo,
    required this.avatarRepo,
    required this.audio,
    required this.dataVersion,
    required this.onDataChanged,
  });

  final HabitRepository repo;
  final AvatarRepository avatarRepo;
  final AudioService audio;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarVm {
  const _AvatarVm({
    required this.level,
    required this.xp,
    required this.xpGoal,
    required this.xpToNext,
    required this.totalCompletions,
    required this.bestStreak,
    required this.equipPctCapped,
    required this.equipped,
  });

  final int level;
  final int xp;
  final int xpGoal;
  final int xpToNext;
  final int totalCompletions;
  final int bestStreak;
  final double equipPctCapped;
  final Map<String, String> equipped;
}

class _AvatarPageState extends State<AvatarPage> {
  late Future<_AvatarVm> _future;
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

  Future<_AvatarVm> _load() async {
    final xp = await widget.repo.computeTotalXp();
    final level = levelForXp(xp);
    final xpGoal = xpGoalFor(xp);
    final xpToNext = xpGoal - xp;
    final totalCompletions = await widget.repo.getTotalCompletions();
    final habits = await widget.repo.listHabits();
    var bestStreak = 0;
    for (final h in habits) {
      final stats = await widget.repo.getStreakStats(h.id);
      if (stats.longest > bestStreak) bestStreak = stats.longest;
    }
    final equipped = await widget.avatarRepo.getEquipped();
    final equipPct = _equipBonusPct(equipped);
    final equipPctCapped = equipPct > 0.15 ? 0.15 : equipPct;
    return _AvatarVm(
      level: level,
      xp: xp,
      xpGoal: xpGoal,
      xpToNext: xpToNext,
      totalCompletions: totalCompletions,
      bestStreak: bestStreak,
      equipPctCapped: equipPctCapped,
      equipped: equipped,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _equip(CosmeticItem item) async {
    await widget.avatarRepo.equip(item.slot, item.id);
    await widget.audio.play(SoundEvent.equip);
    _refresh();
    widget.onDataChanged();
  }

  double _equipBonusPct(Map<String, String> equipped) {
    if (equipped.isEmpty) return 0.0;
    final byId = {for (final item in AvatarRepository.catalog) item.id: item};
    var sum = 0.0;
    for (final id in equipped.values) {
      final item = byId[id];
      if (item == null) continue;
      if (!item.damageEligible) continue;
      sum += item.damageBonusPct;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Avatar')),
      body: FutureBuilder<_AvatarVm>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = snap.data!;
          final equipped = vm.equipped;
          final catalog = AvatarRepository.catalog;
          final namesById = {for (final item in catalog) item.id: item.name};
          final bySlot = <String, List<CosmeticItem>>{};
          for (final item in catalog) {
            bySlot.putIfAbsent(item.slot, () => []).add(item);
          }

          final progress =
              vm.xpGoal == 0 ? 0.0 : (vm.xp / vm.xpGoal).clamp(0.0, 1.0);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: scheme.surface,
                            child: Icon(
                              Icons.person_rounded,
                              size: 46,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level ${vm.level}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Head: ${namesById[equipped[AvatarRepository.slotHead]] ?? 'None'}',
                                ),
                                Text(
                                  'Body: ${namesById[equipped[AvatarRepository.slotBody]] ?? 'None'}',
                                ),
                                Text(
                                  'Accessory: ${namesById[equipped[AvatarRepository.slotAccessory]] ?? 'None'}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('XP ${vm.xp} / ${vm.xpGoal}'),
                          const Spacer(),
                          Text('+${vm.xpToNext} to next'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: scheme.surface,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Equipment bonus: +${(vm.equipPctCapped * 100).round()}% (cap 15%)',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lifetime Stats',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text('Total completions: ${vm.totalCompletions}'),
                      Text('Total XP earned: ${vm.xp}'),
                      Text('Best streak: ${vm.bestStreak} days'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...bySlot.entries.map((entry) {
                final slot = entry.key;
                final items = entry.value;
                final slotLabel = slot[0].toUpperCase() + slot.substring(1);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slotLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final unlocked = vm.level >= item.unlockLevel;
                      final isEquipped = equipped[slot] == item.id;
                      final iconColor = _toneColor(scheme, item.tone);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(item.icon, color: iconColor),
                          title: Text(item.name),
                          subtitle: Text('Unlocks at level ${item.unlockLevel}'),
                          trailing: unlocked
                              ? ElevatedButton(
                                  onPressed: isEquipped ? null : () => _equip(item),
                                  child: Text(isEquipped ? 'Equipped' : 'Equip'),
                                )
                              : const Text('Locked'),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

Color _toneColor(ColorScheme scheme, CosmeticTone tone) {
  switch (tone) {
    case CosmeticTone.primary:
      return scheme.primary;
    case CosmeticTone.secondary:
      return scheme.secondary;
    case CosmeticTone.tertiary:
      return scheme.tertiary;
    case CosmeticTone.primaryContainer:
      return scheme.primaryContainer;
    case CosmeticTone.secondaryContainer:
      return scheme.secondaryContainer;
    case CosmeticTone.tertiaryContainer:
      return scheme.tertiaryContainer;
  }
}
