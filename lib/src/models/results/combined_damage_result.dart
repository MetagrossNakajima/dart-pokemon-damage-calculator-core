part of '../dto.dart';

/// 固定分布の攻撃列を合算した不変な結果。
final class CombinedDamageResult {
  CombinedDamageResult({
    required this.referenceHp,
    required this.finalHp,
    required this.attackDamage,
    required this.knockout,
    required this.ko,
    required List<WeightedBattleState> finalStates,
  }) : finalStates = List.unmodifiable(finalStates);
  final int referenceHp;
  final DamageDistribution finalHp;

  /// 実行したヒットの算出ダメージ合計。過剰ダメージを含む。
  final CombinedDamageDistribution attackDamage;
  final KnockoutProbability knockout;
  final KoInfo ko;
  final List<WeightedBattleState> finalStates;
  BigInt get min => attackDamage.min;
  BigInt get max => attackDamage.max;
}
