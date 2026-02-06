import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import 'settings_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settingsRepo,
    required this.audio,
    required this.dataVersion,
    required this.onDataChanged,
  });

  final SettingsRepository settingsRepo;
  final AudioService audio;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<UserSetting> _future;
  late final VoidCallback _dataListener;

  @override
  void initState() {
    super.initState();
    _future = widget.settingsRepo.getSettings();
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
      _future = widget.settingsRepo.getSettings();
    });
  }

  Future<void> _updateSoundEnabled(bool enabled) async {
    await widget.audio.setSoundEnabled(enabled);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _updateSoundPack(String packId) async {
    await widget.audio.setSoundPack(packId);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _updateTheme(String themeId) async {
    await widget.settingsRepo.setThemeId(themeId);
    _refresh();
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<UserSetting>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Sound effects'),
                value: settings.soundEnabled,
                onChanged: _updateSoundEnabled,
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Sound pack'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.soundPackId,
                    isExpanded: true,
                    items: AudioService.packs
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateSoundPack(value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Theme'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.themeId,
                    isExpanded: true,
                    items: AppTheme.options
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateTheme(value);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
