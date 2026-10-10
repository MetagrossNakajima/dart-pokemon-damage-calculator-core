import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;

void main() {
  for (final detailed in [false, true]) {
    test('Statsの往復と値による等価性 / $detailed', () {
      domain.equality(
        valid(Stats.fromDto(domain.stats)),
        valid(Stats.fromDto(domain.stats)),
      );
    });
  }
  test('既定値と型付き参照', () {
    final s = valid(Stats.fromDto(domain.stats));
    for (final stat in Stat.values) {
      expect(s[stat].value, domain.stats[stat]);
    }
  });
}
