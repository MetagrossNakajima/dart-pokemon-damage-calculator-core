import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../../support/fixed_combined_fixtures.dart' as combined;

void main() {
  test('repeated single hit accepts accuracy and matches explicit attacks', () {
    final first = DamageDistribution({20: BigInt.one});
    final next = DamageDistribution({30: BigInt.one});
    final dto = CombinedDamageRequestDto.repeatSingleHit(
      firstHit: first,
      subsequentHit: next,
      accuracyPercent: 75,
      defender: combined.defender(),
      field: BattleFieldDto(format: BattleFormat.single),
      setup: BattleSetupDto.none,
    );
    expect(dto.attacks.map((a) => a.turn), [1, 2, 3, 4]);
    expect(dto.attacks.map((a) => a.hits.single), [first, next, next, next]);
    for (final attack in dto.attacks) {
      expect(attack.hitCounts, {0: BigInt.one, 1: BigInt.from(3)});
      expect(attack.conditionalHitCounts, {1: BigInt.one});
    }
    final actual = combined.run(dto);
    final explicit = combined.run(
      combined.request([
        for (var turn = 1; turn <= 4; turn++)
          AttackDto(
            turn: turn,
            hits: [turn == 1 ? first : next],
            hitCounts: {0: BigInt.one, 1: BigInt.from(3)},
            conditionalHitCounts: {1: BigInt.one},
          ),
      ]),
    );
    expect(actual.finalHp.weights, explicit.finalHp.weights);
    expect(actual.attackDamage.weights, explicit.attackDamage.weights);
    expect(actual.knockout.weight, BigInt.from(81));
    expect(actual.knockout.totalWeight, BigInt.from(256));
    expect(actual.ko.category, KoCategory.fourHits);
  });
}
