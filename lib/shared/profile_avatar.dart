import 'dart:io';
import 'package:flutter/material.dart';
import '../db/app_db.dart';
import '../features/avatar/avatar_repository.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.settings,
    required this.equipped,
    required this.size,
    this.borderWidth = 3,
    this.showEdit = false,
    this.onEdit,
  });

  final UserSetting settings;
  final Map<String, String> equipped;
  final double size;
  final double borderWidth;
  final bool showEdit;
  final VoidCallback? onEdit;

  IconData _characterIcon() {
    final headId = equipped[AvatarRepository.slotHead];
    final bodyId = equipped[AvatarRepository.slotBody];
    final accessoryId = equipped[AvatarRepository.slotAccessory];
    final preferredId = headId ?? bodyId ?? accessoryId;
    if (preferredId != null) {
      for (final item in AvatarRepository.catalog) {
        if (item.id == preferredId) return item.icon;
      }
    }
    return Icons.person_rounded;
  }

  Color _toneColor(ColorScheme scheme, CosmeticTone? tone) {
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
      default:
        return scheme.primary;
    }
  }

  CosmeticTone? _characterTone() {
    final headId = equipped[AvatarRepository.slotHead];
    final bodyId = equipped[AvatarRepository.slotBody];
    final accessoryId = equipped[AvatarRepository.slotAccessory];
    final preferredId = headId ?? bodyId ?? accessoryId;
    if (preferredId != null) {
      for (final item in AvatarRepository.catalog) {
        if (item.id == preferredId) return item.tone;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mode = settings.profileAvatarMode;
    final path = settings.profileAvatarPath.trim();
    final hasCustom = mode == 'custom' && path.isNotEmpty;
    final icon = _characterIcon();
    final tone = _characterTone();
    final iconColor = _toneColor(scheme, tone);

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.8),
          width: borderWidth,
        ),
        color: scheme.surface,
      ),
      child: ClipOval(
        child: hasCustom
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(icon, size: size * 0.45, color: iconColor),
                ),
              )
            : Center(
                child: Icon(icon, size: size * 0.45, color: iconColor),
              ),
      ),
    );

    if (!showEdit) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
                border: Border.all(
                  color: scheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.edit_rounded,
                size: size * 0.14,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
