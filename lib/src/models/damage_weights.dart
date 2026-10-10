part of 'models.dart';

/// KO計算に使う、検証済みで空でない正確なダメージ分布。
final class DamageWeights extends DomainValue {
  const DamageWeights._(this.weights, this.totalWeight, this.min, this.max);

  final Map<DamageAmount, DistributionWeight> weights;
  final BigInt totalWeight;
  final int min;
  final int max;

  static Validation<DamageWeights> create(Map<int, BigInt> weights) {
    final checks = _Checks();
    return checks.finish(
      _checkDistribution(checks, DamageDistribution(weights), 'distribution'),
    );
  }

  DamageDistribution get toDto => DamageDistribution({
    for (final entry in weights.entries) entry.key.value: entry.value.value,
  });

  @override
  List<Object?> get _properties => [weights];
}
