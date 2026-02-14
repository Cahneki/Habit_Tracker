import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../db/app_db.dart';
import '../../services/audio_service.dart';
import '../../shared/profile_avatar.dart';
import '../avatar/avatar_page.dart';
import '../avatar/avatar_repository.dart';
import '../habits/habit_repository.dart';
import 'settings_repository.dart';

class ProfilePicturePage extends StatefulWidget {
  const ProfilePicturePage({
    super.key,
    required this.settingsRepo,
    required this.avatarRepo,
    required this.habitRepo,
    required this.audio,
    required this.dataVersion,
    required this.onDataChanged,
  });

  final SettingsRepository settingsRepo;
  final AvatarRepository avatarRepo;
  final HabitRepository habitRepo;
  final AudioService audio;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;

  @override
  State<ProfilePicturePage> createState() => _ProfilePicturePageState();
}

class _ProfilePictureVm {
  const _ProfilePictureVm({
    required this.settings,
    required this.equipped,
  });

  final UserSetting settings;
  final Map<String, String> equipped;
}

class _ProfilePicturePageState extends State<ProfilePicturePage> {
  late Future<_ProfilePictureVm> _future;
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

  Future<_ProfilePictureVm> _load() async {
    final settings = await widget.settingsRepo.getSettings();
    final equipped = await widget.avatarRepo.getEquipped();
    return _ProfilePictureVm(settings: settings, equipped: equipped);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _pickCustomPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    final path = result?.files.single.path;
    if (path == null) {
      _refresh();
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(path);
    final targetDir = p.join(dir.path, 'profile_avatar');
    await Directory(targetDir).create(recursive: true);
    final targetPath = p.join(targetDir, 'profile$ext');
    await File(path).copy(targetPath);
    await widget.settingsRepo.setProfileAvatarPath(targetPath);
    await widget.settingsRepo.setProfileAvatarMode('custom');
    widget.onDataChanged();
    _refresh();
  }

  Future<void> _selectCustom(UserSetting settings) async {
    await widget.settingsRepo.setProfileAvatarMode('custom');
    widget.onDataChanged();
    if (settings.profileAvatarPath.trim().isEmpty) {
      await _pickCustomPhoto();
      return;
    }
    _refresh();
  }

  Future<void> _selectAvatar() async {
    await widget.settingsRepo.setProfileAvatarMode('character');
    widget.onDataChanged();
    _refresh();
  }

  Future<void> _openAvatarEditor() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AvatarPage(
          repo: widget.habitRepo,
          avatarRepo: widget.avatarRepo,
          audio: widget.audio,
          settingsRepo: widget.settingsRepo,
          dataVersion: widget.dataVersion,
          onDataChanged: widget.onDataChanged,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _handleEdit(UserSetting settings) async {
    if (settings.profileAvatarMode == 'custom') {
      await _pickCustomPhoto();
      return;
    }
    await _openAvatarEditor();
  }

  Widget _sourceOption({
    required BuildContext context,
    required bool selected,
    required String label,
    required Widget leading,
    required BorderRadius borderRadius,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outline,
                  width: 2,
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: selected ? 8 : 0,
                  height: selected ? 8 : 0,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            leading,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Picture'),
      ),
      body: FutureBuilder<_ProfilePictureVm>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = snap.data!;
          final settings = vm.settings;
          final selectedMode = settings.profileAvatarMode == 'custom'
              ? 'custom'
              : 'avatar';
          final avatarOnlySettings = settings.copyWith(
            profileAvatarMode: 'character',
          );

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ProfileAvatar(
                      settings: settings,
                      equipped: vm.equipped,
                      size: 112,
                      borderWidth: 3,
                      showEdit: true,
                      onEdit: () => _handleEdit(settings),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Material(
                    color: scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.28),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _sourceOption(
                          context: context,
                          selected: selectedMode == 'custom',
                          label: 'Custom Photo',
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                          leading: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              size: 17,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () => _selectCustom(settings),
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          endIndent: 16,
                          color: scheme.outline.withValues(alpha: 0.25),
                        ),
                        _sourceOption(
                          context: context,
                          selected: selectedMode == 'avatar',
                          label: 'My Avatar',
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                          leading: ProfileAvatar(
                            settings: avatarOnlySettings,
                            equipped: vm.equipped,
                            size: 30,
                            borderWidth: 1.6,
                          ),
                          onTap: _selectAvatar,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This image is shown on your profile and activity.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
