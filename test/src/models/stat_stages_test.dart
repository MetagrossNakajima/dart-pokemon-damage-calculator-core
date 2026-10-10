import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;

void main() {
  for (final detailed in [false, true]) {
    test('StatStagesの往復と値による等価性 / $detailed', () {
      final p = domain.pokemon(detailed: detailed);
      domain.equality(
        valid(StatStages.fromDto(p.stages)),
        valid(StatStages.fromDto(p.stages)),
      );
    });
  }
  test('既定値と型付き参照', () {
    final stages = StatStages.zero;
    expect(stages[Stat.hp], isNull);
    for (final stat in Stat.values.where((s) => s != Stat.hp)) {
      expect(stages[stat]!.value, 0);
    }
  });
}
