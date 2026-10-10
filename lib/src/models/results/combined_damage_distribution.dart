part of '../dto.dart';

/// 合算ダメージと整数重みを任意精度で保持する不変な分布。
final class CombinedDamageDistribution {
  CombinedDamageDistribution(Map<BigInt, BigInt> weights)
    : weights = Map.unmodifiable(weights);

  final Map<BigInt, BigInt> weights;
  BigInt get totalWeight =>
      weights.values.fold(BigInt.zero, (total, weight) => total + weight);
  BigInt get min => weights.keys.reduce(
    (minimum, damage) => minimum < damage ? minimum : damage,
  );
  BigInt get max => weights.keys.reduce(
    (maximum, damage) => maximum > damage ? maximum : damage,
  );
}
