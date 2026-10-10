import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;

void main() {
  for (final detailed in [false, true]) {
    test('BattleSetupの往復と値による等価性 / $detailed', () {
      const h = EntryHazardsDto(stealthRock: true, spikesLayers: 3);
      final setup = BattleSetupDto(entryHazards: h, initialDamages: [25]);
      domain.equality(
        valid(BattleSetup.fromDto(setup)),
        valid(BattleSetup.fromDto(setup)),
      );
    });
  }
  test('既定値と型付き参照', () {
    expect(BattleSetup.none.initialDamages, isEmpty);
    expect(BattleSetup.none.entryHazards.spikesLayers.value, 0);
  });
}
