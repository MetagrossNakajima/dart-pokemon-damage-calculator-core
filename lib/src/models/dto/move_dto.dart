part of '../dto.dart';

/// 呼び出し側が指定する、技の未検証マスターデータと対戦条件のDTO。
final class MoveDto {
  MoveDto({
    required this.id,
    required this.type,
    required this.power,
    required this.category,
    this.spread = false,
    Set<MoveFlag> flags = const {},
    this.priority = 0,
  }) : flags = Set.unmodifiable(flags);
  final MoveId id;
  final PokemonType type;
  final int power;
  final Category category;

  /// この攻撃が実際に複数の対象へ向けられているか。
  final bool spread;
  final Set<MoveFlag> flags;
  final int priority;
}
