import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../db/app_db.dart';
import '../../services/audio_service.dart';
import 'settings_repository.dart';

class SoundPackPage extends StatefulWidget {
  const SoundPackPage({
    super.key,
    required this.selectedId,
    required this.audio,
    required this.settingsRepo,
    required this.onDataChanged,
  });

  final String selectedId;
  final AudioService audio;
  final SettingsRepository settingsRepo;
  final VoidCallback onDataChanged;

  @override
  State<SoundPackPage> createState() => _SoundPackPageState();
}

class _SoundPackPageState extends State<SoundPackPage> {
  static const Map<String, String> _packSubtitles = {
    'interface': 'Clean & Crisp',
    'celestial': 'Ethereal & Divine',
    'dungeon': 'Heavy & Metallic',
  };
  late String _selectedPackId;
  late String _lastPresetId;
  late Future<UserSetting> _settingsFuture;
  List<SoundOption> _soundOptions = const [];
  bool _loadingSounds = false;

  @override
  void initState() {
    super.initState();
    _selectedPackId = widget.selectedId;
    _lastPresetId = _selectedPackId == 'custom' ? 'interface' : _selectedPackId;
    _settingsFuture = widget.settingsRepo.getSettings();
    _loadSoundOptions();
  }

  void _refreshSettings() {
    setState(() {
      _settingsFuture = widget.settingsRepo.getSettings();
    });
  }

  Future<void> _loadSoundOptions() async {
    if (_selectedPackId == 'custom') {
      setState(() {
        _soundOptions = const [];
        _loadingSounds = false;
      });
      return;
    }
    setState(() => _loadingSounds = true);
    final options = await widget.audio.getAvailableSounds();
    if (!mounted) return;
    setState(() {
      _soundOptions = options;
      _loadingSounds = false;
    });
  }

  Future<void> _applyPresetDefaults(String packId) async {
    final options = await widget.audio.getAvailableSounds();
    final ids = options.map((o) => o.id).toSet();

    String fallbackFor(String preferred) {
      if (ids.contains(preferred)) return preferred;
      if (options.isNotEmpty) return options.first.id;
      return '';
    }

    final completeId = fallbackFor('complete');
    final levelUpId = fallbackFor('level_up');
    final equipId = fallbackFor('equip');

    if (completeId.isNotEmpty) {
      await widget.audio.setSoundForEvent(SoundEvent.complete, completeId);
    }
    if (levelUpId.isNotEmpty) {
      await widget.audio.setSoundForEvent(SoundEvent.levelUp, levelUpId);
    }
    if (equipId.isNotEmpty) {
      await widget.audio.setSoundForEvent(SoundEvent.equip, equipId);
    }
  }

  Future<void> _selectPreset(String packId) async {
    if (_selectedPackId == packId) return;
    await widget.audio.setSoundPack(packId);
    await _applyPresetDefaults(packId);
    widget.onDataChanged();
    if (!mounted) return;
    setState(() {
      _selectedPackId = packId;
      _lastPresetId = packId;
    });
    _refreshSettings();
    await _loadSoundOptions();
  }

  Future<void> _toggleMode(bool presetMode) async {
    if (presetMode) {
      final target = _lastPresetId.isEmpty ? 'interface' : _lastPresetId;
      await widget.audio.setSoundPack(target);
      await _applyPresetDefaults(target);
      widget.onDataChanged();
      if (!mounted) return;
      setState(() => _selectedPackId = target);
      _refreshSettings();
      await _loadSoundOptions();
      return;
    }

    await widget.audio.setSoundPack('custom');
    widget.onDataChanged();
    if (!mounted) return;
    setState(() => _selectedPackId = 'custom');
    _refreshSettings();
    await _loadSoundOptions();
  }

  Future<void> _pickCustomSound(SoundEvent event) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3', 'm4a', 'aac', 'ogg'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await widget.audio.setCustomSoundForEvent(event, path);
    if (!mounted) return;
    _refreshSettings();
  }

  Future<void> _previewSound(SoundEvent event) async {
    await widget.audio.play(event);
  }

  String _labelForPath(String path) {
    if (path.isEmpty) return 'Not set';
    return p.basename(path);
  }

  String _labelForSound(String id) {
    if (_soundOptions.isEmpty) return _loadingSounds ? 'Loading…' : 'No sounds';
    final option = _soundOptions.firstWhere(
      (o) => o.id == id,
      orElse: () => const SoundOption(id: '', label: 'Unknown'),
    );
    return option.label;
  }

  String _resolveSoundId(String id) {
    if (_soundOptions.any((o) => o.id == id)) return id;
    if (_soundOptions.isNotEmpty) return _soundOptions.first.id;
    return '';
  }

  Widget _segmentedControl(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPreset = _selectedPackId != 'custom';
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segmentButton(
              context,
              label: 'Preset Pack',
              selected: isPreset,
              onTap: () => _toggleMode(true),
            ),
          ),
          Expanded(
            child: _segmentButton(
              context,
              label: 'Custom Mixed',
              selected: !isPreset,
              onTap: () => _toggleMode(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: selected ? scheme.primary : scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(color: scheme.outline.withValues(alpha: 0.4)),
        ),
      ],
    );
  }

  Widget _presetTile(SoundPack pack, bool selected) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = _packSubtitles[pack.id] ?? 'Tap to preview';
    return InkWell(
      onTap: () => _selectPreset(pack.id),
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.6)
                    : scheme.outline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_awesome, color: scheme.primary),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool locked,
    required bool canPreview,
    VoidCallback? onChange,
    required VoidCallback onPreview,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (locked)
                        Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: canPreview ? onPreview : null,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            if (onChange != null)
              TextButton(
                onPressed: onChange,
                child: const Text('Change'),
              )
            else
              Text(
                'EDIT',
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final presetPacks = AudioService.packs.where((p) => p.id != 'custom');
    final isPreset = _selectedPackId != 'custom';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sound Pack'),
        centerTitle: true,
      ),
      body: FutureBuilder<UserSetting>(
        future: _settingsFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snap.data!;
          final completeSoundId = _resolveSoundId(settings.soundCompleteId);
          final levelUpSoundId = _resolveSoundId(settings.soundLevelUpId);
          final equipSoundId = _resolveSoundId(settings.soundEquipId);

          final completionLabel = isPreset
              ? '${_packNameFor(_selectedPackId)}: ${_labelForSound(completeSoundId)}'
              : _labelForPath(settings.soundCompletePath);
          final levelUpLabel = isPreset
              ? '${_packNameFor(_selectedPackId)}: ${_labelForSound(levelUpSoundId)}'
              : _labelForPath(settings.soundLevelUpPath);
          final equipLabel = isPreset
              ? '${_packNameFor(_selectedPackId)}: ${_labelForSound(equipSoundId)}'
              : _labelForPath(settings.soundEquipPath);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _segmentedControl(context),
              const SizedBox(height: 20),
              if (isPreset) ...[
                _sectionHeader(context, 'Select Sound Pack'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presetPacks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final pack = presetPacks.elementAt(index);
                      return SizedBox(
                        width: 180,
                        height: 180,
                        child: _presetTile(
                          pack,
                          pack.id == _selectedPackId,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _sectionHeader(context, 'Event Sounds'),
              const SizedBox(height: 12),
              _eventRow(
                context: context,
                title: 'Task completion',
                subtitle: completionLabel,
                locked: isPreset,
                canPreview: isPreset
                    ? _soundOptions.isNotEmpty
                    : settings.soundCompletePath.isNotEmpty,
                onPreview: () => _previewSound(SoundEvent.complete),
                onChange: isPreset
                    ? null
                    : () => _pickCustomSound(SoundEvent.complete),
              ),
              const SizedBox(height: 12),
              _eventRow(
                context: context,
                title: 'Level up',
                subtitle: levelUpLabel,
                locked: isPreset,
                canPreview: isPreset
                    ? _soundOptions.isNotEmpty
                    : settings.soundLevelUpPath.isNotEmpty,
                onPreview: () => _previewSound(SoundEvent.levelUp),
                onChange: isPreset
                    ? null
                    : () => _pickCustomSound(SoundEvent.levelUp),
              ),
              const SizedBox(height: 12),
              _eventRow(
                context: context,
                title: 'Equipment',
                subtitle: equipLabel,
                locked: isPreset,
                canPreview: isPreset
                    ? _soundOptions.isNotEmpty
                    : settings.soundEquipPath.isNotEmpty,
                onPreview: () => _previewSound(SoundEvent.equip),
                onChange: isPreset
                    ? null
                    : () => _pickCustomSound(SoundEvent.equip),
              ),
              if (isPreset)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Locked to ${_packNameFor(_selectedPackId)} preset. Switch to Custom Mixed to mix sounds from different packs.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _packNameFor(String id) {
    final pack = AudioService.packs.firstWhere(
      (p) => p.id == id,
      orElse: () => const SoundPack(id: 'interface', name: 'Interface Sounds'),
    );
    return pack.name;
  }
}
