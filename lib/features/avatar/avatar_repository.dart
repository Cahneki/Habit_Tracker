import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../../db/app_db.dart';

class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.unlockLevel,
    required this.icon,
    required this.color,
    required this.damageBonusPct,
  });

  final String id;
  final String name;
  final String slot; // head, body, accessory
  final int unlockLevel;
  final IconData icon;
  final Color color;
  final double damageBonusPct;
}

class AvatarRepository {
  AvatarRepository(this.db);
  final AppDb db;

  static const String slotHead = 'head';
  static const String slotBody = 'body';
  static const String slotAccessory = 'accessory';

  static const List<CosmeticItem> catalog = [
    CosmeticItem(
      id: 'head_cap',
      name: 'Explorer Cap',
      slot: slotHead,
      unlockLevel: 1,
      icon: Icons.hiking_rounded,
      color: Color(0xFF8B5E34),
      damageBonusPct: 0.02,
    ),
    CosmeticItem(
      id: 'head_crown',
      name: 'Leaf Crown',
      slot: slotHead,
      unlockLevel: 4,
      icon: Icons.emoji_nature_rounded,
      color: Color(0xFF2B8C4A),
      damageBonusPct: 0.03,
    ),
    CosmeticItem(
      id: 'body_tunic',
      name: 'Forest Tunic',
      slot: slotBody,
      unlockLevel: 1,
      icon: Icons.checkroom_rounded,
      color: Color(0xFF4A2C2A),
      damageBonusPct: 0.02,
    ),
    CosmeticItem(
      id: 'body_armor',
      name: 'Bronze Armor',
      slot: slotBody,
      unlockLevel: 6,
      icon: Icons.shield_rounded,
      color: Color(0xFFB0793D),
      damageBonusPct: 0.04,
    ),
    CosmeticItem(
      id: 'acc_pouch',
      name: 'Supply Pouch',
      slot: slotAccessory,
      unlockLevel: 2,
      icon: Icons.backpack_rounded,
      color: Color(0xFF8B5E34),
      damageBonusPct: 0.02,
    ),
    CosmeticItem(
      id: 'acc_compass',
      name: 'Field Compass',
      slot: slotAccessory,
      unlockLevel: 8,
      icon: Icons.explore_rounded,
      color: Color(0xFF3E5C76),
      damageBonusPct: 0.04,
    ),
  ];

  Future<Map<String, String>> getEquipped() async {
    final rows = await db.select(db.equippedCosmetics).get();
    return {for (final r in rows) r.slot: r.cosmeticId};
  }

  Future<void> equip(String slot, String cosmeticId) async {
    await db.into(db.equippedCosmetics).insertOnConflictUpdate(
          EquippedCosmeticsCompanion(
            slot: Value(slot),
            cosmeticId: Value(cosmeticId),
          ),
        );
  }

  Future<void> unequip(String slot) async {
    await (db.delete(db.equippedCosmetics)..where((c) => c.slot.equals(slot)))
        .go();
  }
}
