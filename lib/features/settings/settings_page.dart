import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../shared/profile_avatar.dart';
import '../avatar/avatar_repository.dart';
import '../habits/habit_repository.dart';
import 'profile_picture_page.dart';
import 'settings_repository.dart';
import 'sound_pack_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settingsRepo,
    required this.audio,
    required this.habitRepo,
    required this.avatarRepo,
    required this.dataVersion,
    required this.onDataChanged,
  });

  final SettingsRepository settingsRepo;
  final AudioService audio;
  final HabitRepository habitRepo;
  final AvatarRepository avatarRepo;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsVm {
  const _SettingsVm({required this.settings, required this.equipped});

  final UserSetting settings;
  final Map<String, String> equipped;
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<_SettingsVm> _future;
  late final VoidCallback _dataListener;
  bool _notificationsEnabled = true;
  bool _hapticsEnabled = true;
  String _visibility = 'Public';

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

  Future<_SettingsVm> _load() async {
    final settings = await widget.settingsRepo.getSettings();
    final equipped = await widget.avatarRepo.getEquipped();
    return _SettingsVm(settings: settings, equipped: equipped);
  }

  Future<void> _updateSoundEnabled(bool enabled) async {
    await widget.audio.setSoundEnabled(enabled);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _updateSoundForEvent(SoundEvent event, String soundId) async {
    await widget.audio.setSoundForEvent(event, soundId);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _updateTheme(String themeId) async {
    await widget.settingsRepo.setThemeId(themeId);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _openProfilePicture() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePicturePage(
          settingsRepo: widget.settingsRepo,
          avatarRepo: widget.avatarRepo,
          habitRepo: widget.habitRepo,
          audio: widget.audio,
          dataVersion: widget.dataVersion,
          onDataChanged: widget.onDataChanged,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _previewSound(SoundEvent event) async {
    await widget.audio.play(event);
  }

  Future<void> _openCustomSounds() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SoundPackPage(
          selectedId: 'custom',
          audio: widget.audio,
          settingsRepo: widget.settingsRepo,
          onDataChanged: widget.onDataChanged,
        ),
      ),
    );
  }

  Future<void> _redoOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Redo onboarding?'),
        content: const Text(
          'This will launch onboarding again. Existing quests will stay as-is.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Redo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.settingsRepo.setOnboardingCompleted(false);
    widget.onDataChanged();
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
  }

  void _toggleHaptics(bool value) {
    setState(() => _hapticsEnabled = value);
  }

  Future<String?> _showSelectionSheet({
    required String title,
    required List<_SheetOption> options,
    required String selectedId,
  }) async {
    if (!mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: scheme.outline.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final selected = option.id == selectedId;
                      return ListTile(
                        title: Text(option.label),
                        trailing: selected
                            ? Icon(Icons.check_rounded, color: scheme.primary)
                            : null,
                        onTap: () => Navigator.of(context).pop(option.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          letterSpacing: 2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, List<Widget> items) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final divider = Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          );
          return Column(
            children: [item, if (index != items.length - 1) divider],
          );
        }),
      ),
    );
  }

  Widget _profileCard(UserSetting settings, Map<String, String> equipped) {
    final scheme = Theme.of(context).colorScheme;
    final usingCustom = settings.profileAvatarMode == 'custom';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openProfilePicture,
          child: Row(
            children: [
              ProfileAvatar(
                settings: settings,
                equipped: equipped,
                size: 72,
                borderWidth: 2.5,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Picture',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usingCustom ? 'Custom Photo' : 'My Avatar',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _valueTrailing(
    BuildContext context,
    String value, {
    bool showChevron = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (showChevron) ...[
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ],
    );
  }

  Widget _settingsRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool destructive = false,
    bool enabled = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = destructive ? scheme.error : scheme.primary;
    final titleColor = destructive ? scheme.error : scheme.onSurface;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              ...[trailing].whereType<Widget>(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSoundSettingsSheet({required UserSetting settings}) async {
    if (!mounted) return;
    final soundOptions = await widget.audio.getAvailableSounds();
    if (!mounted) return;

    final soundIds = soundOptions.map((s) => s.id).toSet();
    final completeSoundId = soundIds.contains(settings.soundCompleteId)
        ? settings.soundCompleteId
        : (soundOptions.isNotEmpty ? soundOptions.first.id : '');
    final levelUpSoundId = soundIds.contains(settings.soundLevelUpId)
        ? settings.soundLevelUpId
        : (soundOptions.isNotEmpty ? soundOptions.first.id : '');
    final equipSoundId = soundIds.contains(settings.soundEquipId)
        ? settings.soundEquipId
        : (soundOptions.isNotEmpty ? soundOptions.first.id : '');

    String labelForSound(String id) {
      if (id.isEmpty) return 'Not set';
      final option = soundOptions.firstWhere(
        (o) => o.id == id,
        orElse: () => const SoundOption(id: '', label: 'Unknown'),
      );
      return option.label;
    }

    final canSelectSounds = soundOptions.isNotEmpty;
    final noSoundsLabel = 'No sounds found';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final textTheme = Theme.of(sheetContext).textTheme;

        Widget soundRow({
          required String title,
          required IconData icon,
          required String selectedId,
          required SoundEvent event,
        }) {
          return _settingsRow(
            context: sheetContext,
            icon: icon,
            title: title,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: canSelectSounds
                      ? () => _previewSound(event)
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  tooltip: 'Preview',
                ),
                _valueTrailing(
                  sheetContext,
                  canSelectSounds ? labelForSound(selectedId) : noSoundsLabel,
                  showChevron: canSelectSounds,
                ),
              ],
            ),
            enabled: canSelectSounds,
            onTap: () async {
              final selection = await _showSelectionSheet(
                title: title,
                selectedId: selectedId,
                options: soundOptions
                    .map((s) => _SheetOption(s.id, s.label))
                    .toList(),
              );
              if (selection == null || selection == selectedId) return;
              await _updateSoundForEvent(event, selection);
              await _previewSound(event);
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Sound Settings',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      soundRow(
                        title: 'Completion Sound',
                        icon: Icons.check_circle_rounded,
                        selectedId: completeSoundId,
                        event: SoundEvent.complete,
                      ),
                      Divider(
                        height: 1,
                        indent: 72,
                        endIndent: 16,
                        color: scheme.outline.withValues(alpha: 0.3),
                      ),
                      soundRow(
                        title: 'Level Up Sound',
                        icon: Icons.trending_up_rounded,
                        selectedId: levelUpSoundId,
                        event: SoundEvent.levelUp,
                      ),
                      Divider(
                        height: 1,
                        indent: 72,
                        endIndent: 16,
                        color: scheme.outline.withValues(alpha: 0.3),
                      ),
                      soundRow(
                        title: 'Equip Sound',
                        icon: Icons.shield_rounded,
                        selectedId: equipSoundId,
                        event: SoundEvent.equip,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: FutureBuilder<_SettingsVm>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = snap.data!;
          final settings = vm.settings;
          final equipped = vm.equipped;
          final packIds = AudioService.packs.map((p) => p.id).toSet();
          final soundPackId = packIds.contains(settings.soundPackId)
              ? settings.soundPackId
              : AudioService.packs.first.id;

          String labelForPack(String id) {
            final option = AudioService.packs.firstWhere(
              (p) => p.id == id,
              orElse: () => const SoundPack(id: 'interface', name: 'Sound'),
            );
            return option.name;
          }

          String labelForTheme(String id) {
            final option = AppTheme.options.firstWhere(
              (t) => t.id == id,
              orElse: () => const ThemeOption(id: 'forest', label: 'Theme'),
            );
            return option.label;
          }

          final generalRows = [
            _settingsRow(
              context: context,
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              trailing: Switch.adaptive(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeTrackColor: scheme.primary,
                activeThumbColor: scheme.onPrimary,
              ),
              onTap: () => _toggleNotifications(!_notificationsEnabled),
            ),
            _settingsRow(
              context: context,
              icon: Icons.vibration_rounded,
              title: 'Haptic Feedback',
              trailing: Switch.adaptive(
                value: _hapticsEnabled,
                onChanged: _toggleHaptics,
                activeTrackColor: scheme.primary,
                activeThumbColor: scheme.onPrimary,
              ),
              onTap: () => _toggleHaptics(!_hapticsEnabled),
            ),
            _settingsRow(
              context: context,
              icon: Icons.person_rounded,
              title: 'Character Visibility',
              trailing: _valueTrailing(context, _visibility),
              onTap: () async {
                final selection = await _showSelectionSheet(
                  title: 'Character Visibility',
                  selectedId: _visibility,
                  options: const [
                    _SheetOption('Public', 'Public'),
                    _SheetOption('Friends Only', 'Friends Only'),
                    _SheetOption('Private', 'Private'),
                  ],
                );
                if (selection == null || selection == _visibility) return;
                setState(() => _visibility = selection);
              },
            ),
          ];

          final soundRows = <Widget>[
            _settingsRow(
              context: context,
              icon: Icons.volume_up_rounded,
              title: 'Sound Effects',
              trailing: Switch.adaptive(
                value: settings.soundEnabled,
                onChanged: _updateSoundEnabled,
                activeTrackColor: scheme.primary,
                activeThumbColor: scheme.onPrimary,
              ),
              onTap: () {
                if (soundPackId == 'custom') {
                  _openCustomSounds();
                  return;
                }
                _showSoundSettingsSheet(settings: settings);
              },
            ),
            _settingsRow(
              context: context,
              icon: Icons.brightness_2_rounded,
              title: 'Theme',
              trailing: _valueTrailing(
                context,
                labelForTheme(settings.themeId),
              ),
              onTap: () async {
                final selection = await _showSelectionSheet(
                  title: 'Theme',
                  selectedId: settings.themeId,
                  options: AppTheme.options
                      .map((t) => _SheetOption(t.id, t.label))
                      .toList(),
                );
                if (selection == null || selection == settings.themeId) {
                  return;
                }
                await _updateTheme(selection);
              },
            ),
            _settingsRow(
              context: context,
              icon: Icons.library_music_rounded,
              title: 'Sound Pack',
              trailing: _valueTrailing(context, labelForPack(soundPackId)),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SoundPackPage(
                      selectedId: soundPackId,
                      audio: widget.audio,
                      settingsRepo: widget.settingsRepo,
                      onDataChanged: widget.onDataChanged,
                    ),
                  ),
                );
                if (!mounted) return;
                _refresh();
              },
            ),
          ];

          final accountRows = [
            _settingsRow(
              context: context,
              icon: Icons.cloud_rounded,
              title: 'Cloud Sync',
              trailing: _valueTrailing(
                context,
                'Coming soon',
                showChevron: false,
              ),
              enabled: false,
            ),
            _settingsRow(
              context: context,
              icon: Icons.restart_alt_rounded,
              title: 'Redo Onboarding',
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
              onTap: _redoOnboarding,
            ),
            _settingsRow(
              context: context,
              icon: Icons.logout_rounded,
              title: 'Logout',
              destructive: true,
              onTap: () {},
            ),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _sectionHeader(context, 'Profile'),
              const SizedBox(height: 8),
              _profileCard(settings, equipped),
              const SizedBox(height: 20),
              _sectionHeader(context, 'General'),
              const SizedBox(height: 8),
              _sectionCard(context, generalRows),
              const SizedBox(height: 20),
              _sectionHeader(context, 'Sound & Visuals'),
              const SizedBox(height: 8),
              _sectionCard(context, soundRows),
              const SizedBox(height: 20),
              _sectionHeader(context, 'Account'),
              const SizedBox(height: 8),
              _sectionCard(context, accountRows),
            ],
          );
        },
      ),
    );
  }
}

class _SheetOption {
  const _SheetOption(this.id, this.label);
  final String id;
  final String label;
}
