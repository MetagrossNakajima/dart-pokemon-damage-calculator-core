import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../../support/fixed_combined_fixtures.dart' as combined;

void main() {
  final hit = DamageDistribution({30: BigInt.one});
  AttackDto make({
    int accuracy = 100,
    Map<int, int> counts = const {1: 1},
    bool perHit = false,
    int length = 5,
  }) => AttackDto.fromAccuracy(
    turn: 1,
    hits: List.filled(length, hit),
    accuracyPercent: accuracy,
    hitCountWeights: counts,
    accuracyPerHit: perHit,
  );

  test('single hit accuracy generates exact miss and hit weights', () {
    final dto = make(accuracy: 75);
    expect(dto.hitCounts, {0: BigInt.one, 1: BigInt.from(3)});
    expect(dto.conditionalHitCounts, {1: BigInt.one});
    final result = combined.run(combined.request([dto]));
    expect(result.finalHp.weights, {100: BigInt.one, 70: BigInt.from(3)});
    expect(result.knockout.weight, BigInt.zero);
    expect(result.knockout.totalWeight, BigInt.from(4));
  });

  test('multi hit accuracy preserves conditional count probabilities', () {
    final counts = {2: 3, 3: 3, 4: 1, 5: 1};
    final dto = make(accuracy: 75, counts: counts);
    counts.clear();
    expect(dto.hitCounts, {
      0: BigInt.from(8),
      2: BigInt.from(9),
      3: BigInt.from(9),
      4: BigInt.from(3),
      5: BigInt.from(3),
    });
    expect(dto.conditionalHitCounts, {
      2: BigInt.from(3),
      3: BigInt.from(3),
      4: BigInt.one,
      5: BigInt.one,
    });
    expect(() => dto.hitCounts.clear(), throwsUnsupportedError);
    expect(() => dto.conditionalHitCounts!.clear(), throwsUnsupportedError);
    final result = combined.run(combined.request([dto]));
    expect(result.finalHp.weights, {
      100: BigInt.from(8),
      40: BigInt.from(9),
      10: BigInt.from(9),
      0: BigInt.from(6),
    });
    expect(result.knockout.weight, BigInt.from(6));
    expect(result.knockout.totalWeight, BigInt.from(32));
  });

  test('zero and full accuracy omit zero probability outcomes', () {
    expect(make(accuracy: 0).hitCounts, {0: BigInt.one});
    expect(make().hitCounts, {1: BigInt.one});
    expect(make(accuracy: 0).conditionalHitCounts, {1: BigInt.one});
    expect(make(counts: {2: 2, 5: 4}).hitCounts, {
      2: BigInt.one,
      5: BigInt.two,
    });
  });

  test('per hit accuracy stops on the first miss and excludes KO category', () {
    final dto = make(accuracy: 75, counts: {3: 1});
    final perHit = make(accuracy: 75, counts: {3: 1}, perHit: true);
    expect(dto.hitCounts, {0: BigInt.one, 3: BigInt.from(3)});
    expect(perHit.hitCounts, {
      0: BigInt.from(16),
      1: BigInt.from(12),
      2: BigInt.from(9),
      3: BigInt.from(27),
    });
    expect(perHit.conditionalHitCounts, isNull);
    final result = combined.run(combined.request([perHit]));
    expect(result.finalHp.weights, {
      100: BigInt.from(16),
      70: BigInt.from(12),
      40: BigInt.from(9),
      10: BigInt.from(27),
    });
    expect(result.ko.category, KoCategory.notApplicable);
  });

  test('per hit accuracy mixes different maximum counts exactly', () {
    expect(make(accuracy: 50, counts: {1: 1, 3: 1}, perHit: true).hitCounts, {
      0: BigInt.from(8),
      1: BigInt.from(6),
      2: BigInt.one,
      3: BigInt.one,
    });
    expect(make(counts: {5: 1, 2: 1, 3: 1}, perHit: true).hitCounts, {
      5: BigInt.one,
      2: BigInt.one,
      3: BigInt.one,
    });
    expect(make(accuracy: 0, counts: {2: 1}, perHit: true).hitCounts, {
      0: BigInt.one,
    });
  });

  test('large count weights use BigInt products without precision loss', () {
    const large = 9007199254740993;
    final dto = make(accuracy: 1, counts: {1: large, 2: 1});
    expect(dto.hitCounts, {
      0: BigInt.from(large + 1) * BigInt.from(99),
      1: BigInt.from(large),
      2: BigInt.one,
    });
  });

  test('invalid accuracy and count weights fail before expansion', () {
    for (final accuracy in [-1, 101]) {
      expect(() => make(accuracy: accuracy), throwsArgumentError);
    }
    for (final counts in [
      <int, int>{},
      {0: 1},
      {-1: 1},
      {6: 1},
      {1: 0},
      {1: -1},
    ]) {
      expect(() => make(counts: counts), throwsArgumentError);
    }
    expect(() => make(length: 0), throwsArgumentError);
  });
}
