import 'package:flutter/services.dart';
import '../features/settings/settings_repository.dart';

enum SoundEvent { complete, levelUp, equip }

class SoundPack {
  const SoundPack({required this.id, required this.name});
  final String id;
  final String name;
}

class AudioService {
  AudioService(this.settingsRepo);
  final SettingsRepository settingsRepo;

  static const List<SoundPack> packs = [
    SoundPack(id: 'system', name: 'System'),
  ];

  bool _loaded = false;
  bool _enabled = true;
  String _packId = 'system';

  bool get soundEnabled => _enabled;
  String get soundPackId => _packId;

  Future<void> _load() async {
    if (_loaded) return;
    final settings = await settingsRepo.getSettings();
    _enabled = settings.soundEnabled;
    _packId = settings.soundPackId;
    _loaded = true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _enabled = enabled;
    await settingsRepo.setSoundEnabled(enabled);
  }

  Future<void> setSoundPack(String packId) async {
    _packId = packId;
    await settingsRepo.setSoundPack(packId);
  }

  Future<void> play(SoundEvent event) async {
    await _load();
    if (!_enabled) return;

    switch (event) {
      case SoundEvent.complete:
        SystemSound.play(SystemSoundType.click);
        break;
      case SoundEvent.levelUp:
        SystemSound.play(SystemSoundType.alert);
        break;
      case SoundEvent.equip:
        SystemSound.play(SystemSoundType.click);
        break;
    }
  }
}
