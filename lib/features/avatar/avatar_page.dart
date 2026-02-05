import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../shared/xp_utils.dart';
import '../../theme/app_theme.dart';
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
    required this.equipped,
  });

  final int level;
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
    final equipped = await widget.avatarRepo.getEquipped();
    return _AvatarVm(level: level, equipped: equipped);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppTheme.parchment,
                      child: const Icon(Icons.person_rounded, size: 46),
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(item.icon, color: item.color),
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
