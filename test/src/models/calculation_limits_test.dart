import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;

void main() {
  for (final detailed in [false, true]) {
    test('CalculationLimitsの往復と値による等価性 / $detailed', () {
      domain.equality(
        valid(CalculationLimits.fromDto(const CalculationLimitsDto())),
        CalculationLimits.defaults,
      );
    });
  }
}
