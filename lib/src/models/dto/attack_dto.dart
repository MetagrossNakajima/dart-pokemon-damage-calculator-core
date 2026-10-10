part of '../dto.dart';

/// 指定ターンに実行する固定分布。命中回数0は外れを表す。
final class AttackDto {
  AttackDto({
    required this.turn,
    required List<DamageDistribution> hits,
    required Map<int, BigInt> hitCounts,
    Map<int, BigInt>? conditionalHitCounts,
  }) : hits = List.unmodifiable(hits),
       hitCounts = Map.unmodifiable(hitCounts),
       conditionalHitCounts = conditionalHitCounts == null
           ? null
           : Map.unmodifiable(conditionalHitCounts);

  /// 命中率と命中時の回数分布から、正確な整数重みを生成します。
  ///
  /// [accuracyPercent] は0〜100の整数です。[hitCountWeights] の省略時は
  /// 1ヒットとし、キーは1〜[hits] の長さ、値は正の整数を指定します。
  /// [accuracyPerHit] が `true` の場合は各ヒットで命中判定し、最初の外れで
  /// 終了します。この方式は確定数の対象外です。
  /// 命中率・回数分布が不正な場合は [ArgumentError] を投げます。
  factory AttackDto.fromAccuracy({
    required int turn,
    required List<DamageDistribution> hits,
    int accuracyPercent = 100,
    Map<int, int> hitCountWeights = const {1: 1},
    bool accuracyPerHit = false,
  }) {
    final validatedAccuracy = switch (AccuracyPercent.create(accuracyPercent)) {
      Valid(:final value) => value,
      Invalid() => throw ArgumentError.value(
        accuracyPercent,
        'accuracyPercent',
      ),
    };
    if (hitCountWeights.isEmpty) {
      throw ArgumentError.value(hitCountWeights, 'hitCountWeights');
    }
    for (final entry in hitCountWeights.entries) {
      if (entry.key < 1 || entry.key > hits.length || entry.value <= 0) {
        throw ArgumentError.value(hitCountWeights, 'hitCountWeights');
      }
    }
    final accuracy = BigInt.from(validatedAccuracy.value);
    final miss = BigInt.from(100 - validatedAccuracy.value);
    final hundred = BigInt.from(100);
    final counts = <int, BigInt>{};
    void add(int count, BigInt weight) {
      if (weight > BigInt.zero) {
        counts[count] = (counts[count] ?? BigInt.zero) + weight;
      }
    }

    if (accuracyPerHit) {
      final maximum = hitCountWeights.keys.reduce((a, b) => a > b ? a : b);
      for (final entry in hitCountWeights.entries) {
        final weight = BigInt.from(entry.value);
        for (var count = 0; count < entry.key; count++) {
          add(
            count,
            weight *
                accuracy.pow(count) *
                miss *
                hundred.pow(maximum - count - 1),
          );
        }
        add(
          entry.key,
          weight * accuracy.pow(entry.key) * hundred.pow(maximum - entry.key),
        );
      }
    } else {
      for (final entry in hitCountWeights.entries) {
        final weight = BigInt.from(entry.value);
        add(0, weight * miss);
        add(entry.key, weight * accuracy);
      }
    }
    final divisor = counts.values.reduce((a, b) => a.gcd(b));
    return AttackDto(
      turn: turn,
      hits: hits,
      hitCounts: counts.map(
        (count, weight) => MapEntry(count, weight ~/ divisor),
      ),
      conditionalHitCounts: accuracyPerHit
          ? null
          : {
              for (final entry in hitCountWeights.entries)
                entry.key: BigInt.from(entry.value),
            },
    );
  }

  final int turn;
  final List<DamageDistribution> hits;
  final Map<int, BigInt> hitCounts;

  /// 命中前提の回数分布。各ヒットで命中判定する攻撃には指定しない。
  final Map<int, BigInt>? conditionalHitCounts;
}
