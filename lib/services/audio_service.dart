import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../db/app_db.dart';
import '../features/settings/settings_repository.dart';

enum SoundEvent { complete, levelUp, equip }

class SoundPack {
  const SoundPack({required this.id, required this.name});
  final String id;
  final String name;
}

class SoundOption {
  const SoundOption({required this.id, required this.label});
  final String id;
  final String label;
}

class AudioService {
  AudioService(this.settingsRepo);
  final SettingsRepository settingsRepo;

  static const List<SoundPack> packs = [
    SoundPack(id: 'interface', name: 'Interface Sounds'),
    SoundPack(id: 'custom', name: 'Custom'),
  ];

  bool _loaded = false;
  bool _enabled = true;
  String _packId = 'interface';
  String _completeSoundId = 'complete';
  String _levelUpSoundId = 'level_up';
  String _equipSoundId = 'equip';
  String _completeSoundPath = '';
  String _levelUpSoundPath = '';
  String _equipSoundPath = '';
  bool _soundsLoaded = false;
  List<SoundOption> _soundOptions = [];
  Set<String> _soundIds = {};
  final Map<SoundEvent, AudioPlayer> _players = {};

  bool get soundEnabled => _enabled;
  String get soundPackId => _packId;

  Future<void> _load() async {
    if (_loaded) return;
    final settings = await settingsRepo.getSettings();
    _enabled = settings.soundEnabled;
    _packId = _normalizePackId(settings.soundPackId);
    await _loadAvailableSounds();
    _completeSoundId = _normalizeSoundId(
      settings.soundCompleteId,
      SoundEvent.complete,
    );
    _levelUpSoundId = _normalizeSoundId(
      settings.soundLevelUpId,
      SoundEvent.levelUp,
    );
    _equipSoundId = _normalizeSoundId(
      settings.soundEquipId,
      SoundEvent.equip,
    );
    _completeSoundPath = settings.soundCompletePath;
    _levelUpSoundPath = settings.soundLevelUpPath;
    _equipSoundPath = settings.soundEquipPath;
    await _persistNormalizedSoundIds(settings);
    if (_packId != settings.soundPackId) {
      await settingsRepo.setSoundPack(_packId);
    }
    _loaded = true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _enabled = enabled;
    await settingsRepo.setSoundEnabled(enabled);
  }

  Future<void> setSoundPack(String packId) async {
    _packId = _normalizePackId(packId);
    _soundsLoaded = false;
    await _loadAvailableSounds();
    _completeSoundId = _normalizeSoundId(_completeSoundId, SoundEvent.complete);
    _levelUpSoundId = _normalizeSoundId(_levelUpSoundId, SoundEvent.levelUp);
    _equipSoundId = _normalizeSoundId(_equipSoundId, SoundEvent.equip);
    await settingsRepo.setSoundPack(_packId);
  }

  Future<void> setSoundForEvent(SoundEvent event, String soundId) async {
    await _loadAvailableSounds();
    final normalized = _normalizeSoundId(soundId, event);
    switch (event) {
      case SoundEvent.complete:
        _completeSoundId = normalized;
        await settingsRepo.setSoundCompleteId(normalized);
        break;
      case SoundEvent.levelUp:
        _levelUpSoundId = normalized;
        await settingsRepo.setSoundLevelUpId(normalized);
        break;
      case SoundEvent.equip:
        _equipSoundId = normalized;
        await settingsRepo.setSoundEquipId(normalized);
        break;
    }
  }

  Future<void> setCustomSoundForEvent(
    SoundEvent event,
    String sourcePath,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(sourcePath);
    final filename = switch (event) {
      SoundEvent.complete => 'complete$ext',
      SoundEvent.levelUp => 'level_up$ext',
      SoundEvent.equip => 'equip$ext',
    };
    final targetDir = p.join(dir.path, 'custom_sounds');
    await Directory(targetDir).create(recursive: true);
    final targetPath = p.join(targetDir, filename);
    await File(sourcePath).copy(targetPath);
    switch (event) {
      case SoundEvent.complete:
        _completeSoundPath = targetPath;
        await settingsRepo.setSoundCompletePath(targetPath);
        break;
      case SoundEvent.levelUp:
        _levelUpSoundPath = targetPath;
        await settingsRepo.setSoundLevelUpPath(targetPath);
        break;
      case SoundEvent.equip:
        _equipSoundPath = targetPath;
        await settingsRepo.setSoundEquipPath(targetPath);
        break;
    }
  }

  Future<List<SoundOption>> getAvailableSounds() async {
    await _loadAvailableSounds();
    return _soundOptions;
  }

  AudioPlayer _playerFor(SoundEvent event) {
    final existing = _players[event];
    if (existing != null) return existing;
    final player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.stop);
    _players[event] = player;
    return player;
  }

  String _assetForEvent(SoundEvent event) {
    final pack = _packId.isEmpty ? 'interface' : _packId;
    final soundId = _soundIdForEvent(event);
    switch (event) {
      case SoundEvent.complete:
        return 'audio/$pack/$soundId.wav';
      case SoundEvent.levelUp:
        return 'audio/$pack/$soundId.wav';
      case SoundEvent.equip:
        return 'audio/$pack/$soundId.wav';
    }
  }

  String _normalizePackId(String packId) {
    if (packId == 'system' || packId == 'forest') return 'interface';
    if (packs.any((p) => p.id == packId)) return packId;
    return 'interface';
  }

  String _soundIdForEvent(SoundEvent event) {
    switch (event) {
      case SoundEvent.complete:
        return _completeSoundId;
      case SoundEvent.levelUp:
        return _levelUpSoundId;
      case SoundEvent.equip:
        return _equipSoundId;
    }
  }

  String _defaultSoundIdForEvent(SoundEvent event) {
    switch (event) {
      case SoundEvent.complete:
        return 'complete';
      case SoundEvent.levelUp:
        return 'level_up';
      case SoundEvent.equip:
        return 'equip';
    }
  }

  String _normalizeSoundId(String soundId, SoundEvent event) {
    if (soundId.isEmpty) return _defaultSoundIdForEvent(event);
    if (_soundIds.contains(soundId)) return soundId;
    return _defaultSoundIdForEvent(event);
  }

  Future<void> _loadAvailableSounds() async {
    if (_soundsLoaded) return;
    if (_packId == 'custom') {
      _soundIds = {};
      _soundOptions = const [];
      _soundsLoaded = true;
      return;
    }
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      final prefix = 'assets/audio/$_packId/';
      final soundIds = <String>[];
      for (final key in assets) {
        if (!key.startsWith(prefix) || !key.endsWith('.wav')) continue;
        final filename = key.split('/').last;
        final id = filename.replaceAll('.wav', '');
        soundIds.add(id);
      }
      soundIds.sort();
      _soundIds = soundIds.toSet();
      _soundOptions = soundIds
          .map((id) => SoundOption(id: id, label: _labelForSoundId(id)))
          .toList();
      _soundsLoaded = true;
    } catch (_) {
      _soundIds = {};
      _soundOptions = const [];
      _soundsLoaded = true;
    }
  }

  String _labelForSoundId(String id) {
    final withSpaces = id.replaceAll('_', ' ').replaceAll('-', ' ');
    return withSpaces
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  Future<void> _persistNormalizedSoundIds(UserSetting settings) async {
    if (_completeSoundId != settings.soundCompleteId) {
      await settingsRepo.setSoundCompleteId(_completeSoundId);
    }
    if (_levelUpSoundId != settings.soundLevelUpId) {
      await settingsRepo.setSoundLevelUpId(_levelUpSoundId);
    }
    if (_equipSoundId != settings.soundEquipId) {
      await settingsRepo.setSoundEquipId(_equipSoundId);
    }
  }

  String _customPathForEvent(SoundEvent event) {
    switch (event) {
      case SoundEvent.complete:
        return _completeSoundPath;
      case SoundEvent.levelUp:
        return _levelUpSoundPath;
      case SoundEvent.equip:
        return _equipSoundPath;
    }
  }

  Future<void> play(SoundEvent event) async {
    await _load();
    if (!_enabled) return;

    final player = _playerFor(event);
    if (_packId == 'custom') {
      final path = _customPathForEvent(event);
      if (path.isEmpty) return;
      await player.play(DeviceFileSource(path));
    } else {
      await player.play(AssetSource(_assetForEvent(event)));
    }
  }
}
