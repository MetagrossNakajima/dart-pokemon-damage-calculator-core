part of '../dto.dart';

/// 複数の攻撃列を合成するための、未検証入力DTO。
final class CombinedDamageRequestDto {
  CombinedDamageRequestDto({
    required List<AttackDto> attacks,
    required this.defender,
    required this.field,
    required this.setup,
    this.limits = const CalculationLimitsDto(),
  }) : attacks = List.unmodifiable(attacks);

  /// 通常技の単発攻撃を、連続する4ターンの攻撃列へ展開する。
  ///
  /// 1ターン目に [firstHit]、2〜4ターン目に [subsequentHit] を使う。
  /// [subsequentHit] の省略時は [firstHit] を繰り返す。
  /// 初撃が外れても、後続の分布は指定した前提で固定する。
  ///
  /// [accuracyPercent] は0〜100の整数で、省略時は必中とする。
  /// [hitCounts] を指定すると、その整数重みを優先する。
  /// 確定数は命中前提で計算する。
  /// 入力検証の位置は [CombinedDamageRequestDto.new] と同じ攻撃列の位置を使う。
  factory CombinedDamageRequestDto.repeatSingleHit({
    required DamageDistribution firstHit,
    DamageDistribution? subsequentHit,
    int accuracyPercent = 100,
    Map<int, BigInt>? hitCounts,
    required PokemonStateDto defender,
    required BattleFieldDto field,
    required BattleSetupDto setup,
    CalculationLimitsDto limits = const CalculationLimitsDto(),
  }) => CombinedDamageRequestDto(
    attacks: [
      for (var turn = 1; turn <= 4; turn++)
        if (hitCounts == null)
          AttackDto.fromAccuracy(
            turn: turn,
            hits: [turn == 1 ? firstHit : subsequentHit ?? firstHit],
            accuracyPercent: accuracyPercent,
          )
        else
          AttackDto(
            turn: turn,
            hits: [turn == 1 ? firstHit : subsequentHit ?? firstHit],
            hitCounts: hitCounts,
            conditionalHitCounts: {1: BigInt.one},
          ),
    ],
    defender: defender,
    field: field,
    setup: setup,
    limits: limits,
  );

  final List<AttackDto> attacks;
  final PokemonStateDto defender;
  final BattleFieldDto field;
  final BattleSetupDto setup;
  final CalculationLimitsDto limits;
}
