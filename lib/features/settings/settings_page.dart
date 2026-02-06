import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
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
  late Future<List<SoundOption>> _soundOptionsFuture;
  late final VoidCallback _dataListener;

  @override
  void initState() {
    super.initState();
    _future = widget.settingsRepo.getSettings();
    _soundOptionsFuture = widget.audio.getAvailableSounds();
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
    _soundOptionsFuture = widget.audio.getAvailableSounds();
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _updateSoundForEvent(SoundEvent event, String soundId) async {
    await widget.audio.setSoundForEvent(event, soundId);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _pickCustomSound(SoundEvent event) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3', 'm4a', 'aac', 'ogg'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await widget.audio.setCustomSoundForEvent(event, path);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _updateTheme(String themeId) async {
    await widget.settingsRepo.setThemeId(themeId);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _previewSound(SoundEvent event) async {
    await widget.audio.play(event);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<UserSetting>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snap.data!;
          final packIds = AudioService.packs.map((p) => p.id).toSet();
          final soundPackId = packIds.contains(settings.soundPackId)
              ? settings.soundPackId
              : AudioService.packs.first.id;

          return FutureBuilder<List<SoundOption>>(
            future: _soundOptionsFuture,
            builder: (context, soundsSnap) {
              final soundOptions = soundsSnap.data ?? const <SoundOption>[];
              final soundIds = soundOptions.map((s) => s.id).toSet();
              final isCustomPack = soundPackId == 'custom';
              final completeSoundId = soundIds.contains(settings.soundCompleteId)
                  ? settings.soundCompleteId
                  : (soundOptions.isNotEmpty ? soundOptions.first.id : '');
              final levelUpSoundId = soundIds.contains(settings.soundLevelUpId)
                  ? settings.soundLevelUpId
                  : (soundOptions.isNotEmpty ? soundOptions.first.id : '');
              final equipSoundId = soundIds.contains(settings.soundEquipId)
                  ? settings.soundEquipId
                  : (soundOptions.isNotEmpty ? soundOptions.first.id : '');

              Widget buildDropdown<T>({
                required String label,
                required T value,
                required List<DropdownMenuItem<T>> items,
                required ValueChanged<T?> onChanged,
                Widget? trailing,
              }) {
                return InputDecorator(
                  decoration: InputDecoration(labelText: label),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              highlightColor: scheme.surface.withValues(alpha: 0),
                              splashColor: scheme.surface.withValues(alpha: 0),
                              hoverColor: scheme.surface.withValues(alpha: 0),
                            ),
                            child: DropdownButton<T>(
                              value: value,
                              isExpanded: true,
                              dropdownColor: scheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 8,
                              menuMaxHeight: 320,
                              items: items,
                              onChanged: onChanged,
                            ),
                          ),
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing,
                      ],
                    ],
                  ),
                );
              }

              List<DropdownMenuItem<String>> buildSoundItems(String selectedId) {
                return soundOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.id,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedId == option.id
                                ? scheme.surfaceContainerHigh
                                : scheme.surface.withValues(alpha: 0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(option.label),
                        ),
                      ),
                    )
                    .toList();
              }

              Widget buildCustomPicker({
                required String label,
                required String path,
                required VoidCallback onPick,
                required VoidCallback onPreview,
              }) {
                final filename = path.isEmpty ? 'Not set' : p.basename(path);
                return Card(
                  child: ListTile(
                    title: Text(label),
                    subtitle: Text(filename),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: path.isEmpty ? null : onPreview,
                          icon: const Icon(Icons.play_arrow_rounded),
                          tooltip: 'Preview',
                        ),
                        TextButton(
                          onPressed: onPick,
                          child: const Text('Choose'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    title: const Text('Sound effects'),
                    value: settings.soundEnabled,
                    onChanged: _updateSoundEnabled,
                  ),
                  const SizedBox(height: 8),
                  buildDropdown<String>(
                    label: 'Sound pack',
                    value: soundPackId,
                    items: AudioService.packs
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: soundPackId == p.id
                                    ? scheme.surfaceContainerHigh
                                    : scheme.surface.withValues(alpha: 0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(p.name),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateSoundPack(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (isCustomPack) ...[
                    buildCustomPicker(
                      label: 'Completion sound',
                      path: settings.soundCompletePath,
                      onPick: () => _pickCustomSound(SoundEvent.complete),
                      onPreview: () => _previewSound(SoundEvent.complete),
                    ),
                    buildCustomPicker(
                      label: 'Level up sound',
                      path: settings.soundLevelUpPath,
                      onPick: () => _pickCustomSound(SoundEvent.levelUp),
                      onPreview: () => _previewSound(SoundEvent.levelUp),
                    ),
                    buildCustomPicker(
                      label: 'Equip sound',
                      path: settings.soundEquipPath,
                      onPick: () => _pickCustomSound(SoundEvent.equip),
                      onPreview: () => _previewSound(SoundEvent.equip),
                    ),
                  ] else if (soundOptions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        soundsSnap.connectionState == ConnectionState.waiting
                            ? 'Loading sounds…'
                            : 'No sounds found in this pack.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    )
                  else ...[
                    buildDropdown<String>(
                      label: 'Completion sound',
                      value: completeSoundId,
                      items: buildSoundItems(completeSoundId),
                      trailing: IconButton(
                        onPressed: () => _previewSound(SoundEvent.complete),
                        icon: const Icon(Icons.play_arrow_rounded),
                        tooltip: 'Preview',
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        _updateSoundForEvent(SoundEvent.complete, value);
                      },
                    ),
                    const SizedBox(height: 12),
                    buildDropdown<String>(
                      label: 'Level up sound',
                      value: levelUpSoundId,
                      items: buildSoundItems(levelUpSoundId),
                      trailing: IconButton(
                        onPressed: () => _previewSound(SoundEvent.levelUp),
                        icon: const Icon(Icons.play_arrow_rounded),
                        tooltip: 'Preview',
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        _updateSoundForEvent(SoundEvent.levelUp, value);
                      },
                    ),
                    const SizedBox(height: 12),
                    buildDropdown<String>(
                      label: 'Equip sound',
                      value: equipSoundId,
                      items: buildSoundItems(equipSoundId),
                      trailing: IconButton(
                        onPressed: () => _previewSound(SoundEvent.equip),
                        icon: const Icon(Icons.play_arrow_rounded),
                        tooltip: 'Preview',
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        _updateSoundForEvent(SoundEvent.equip, value);
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  buildDropdown<String>(
                    label: 'Theme',
                    value: settings.themeId,
                    items: AppTheme.options
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: settings.themeId == t.id
                                    ? scheme.surfaceContainerHigh
                                    : scheme.surface.withValues(alpha: 0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(t.label),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateTheme(value);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
