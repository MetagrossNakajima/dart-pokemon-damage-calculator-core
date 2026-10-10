part of '../dto.dart';

/// リクエストの最初の攻撃前に1回適用する効果のDTO。
final class BattleSetupDto {
  BattleSetupDto({
    this.entryHazards = const EntryHazardsDto(),
    List<int> initialDamages = const [],
  }) : initialDamages = List.unmodifiable(initialDamages);

  static final none = BattleSetupDto();
  final EntryHazardsDto entryHazards;
  final List<int> initialDamages;
}
