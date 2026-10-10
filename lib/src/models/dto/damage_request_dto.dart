part of '../dto.dart';

/// 1回のダメージ計算用の、未検証入力DTO。
final class DamageRequestDto {
  const DamageRequestDto({
    required this.attacker,
    required this.defender,
    required this.move,
    required this.field,
    this.critical = false,
    this.hitIndex = 0,
  });

  final PokemonStateDto attacker;
  final PokemonStateDto defender;
  final MoveDto move;
  final BattleFieldDto field;
  final bool critical;

  /// 0から始まるヒット位置。連続技の威力や親子愛の補正に使用する。
  final int hitIndex;
}
