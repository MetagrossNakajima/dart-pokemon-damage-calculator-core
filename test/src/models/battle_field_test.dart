import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;

void main() {
  for (final detailed in [false, true]) {
    test('BattleFieldの往復と値による等価性 / $detailed', () {
      domain.equality(
        valid(BattleField.fromDto(domain.field(detailed: detailed))),
        valid(BattleField.fromDto(domain.field(detailed: detailed))),
      );
    });
  }
}
