import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;

void main() {
  for (final detailed in [false, true]) {
    test('Attackの往復と値による等価性 / $detailed', () {
      final a = AttackDto(
        turn: 1,
        hits: [
          DamageDistribution({20: BigInt.one}),
        ],
        hitCounts: {0: BigInt.one, 1: BigInt.two},
        conditionalHitCounts: detailed ? {1: BigInt.one} : null,
      );
      domain.equality(valid(Attack.fromDto(a)), valid(Attack.fromDto(a)));
    });
  }
}
