part of '../dto.dart';

/// リクエスト内の各攻撃が共有する、未検証の場の状態DTO。
final class BattleFieldDto {
  BattleFieldDto({
    required this.format,
    this.weather,
    this.gravity = false,
    this.terrain,
    Set<FieldEffect> effects = const {},
  }) : effects = Set.unmodifiable(effects);
  final BattleFormat format;
  final Weather? weather;
  final bool gravity;
  final Terrain? terrain;
  final Set<FieldEffect> effects;
}
