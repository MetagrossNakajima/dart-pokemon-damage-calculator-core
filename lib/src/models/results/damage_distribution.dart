part of '../dto.dart';

/// 小さな確率も失わず、すべての分岐を整数の重みで表すダメージ分布。
final class DamageDistribution {
  DamageDistribution(Map<int, BigInt> weights)
    : weights = Map.unmodifiable(weights);
  final Map<int, BigInt> weights;
  BigInt get totalWeight =>
      weights.values.fold(BigInt.zero, (total, weight) => total + weight);
  int get min => weights.keys.reduce(
    (minimum, damage) => minimum < damage ? minimum : damage,
  );
  int get max => weights.keys.reduce(
    (maximum, damage) => maximum > damage ? maximum : damage,
  );
}
