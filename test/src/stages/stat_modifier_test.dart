import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import '../../support/effects_fixtures.dart' as effects;
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

void main() {
  for (final ability in ['Protosynthesis', 'QuarkDrive']) {
    test('paradox activation, selected stat and tie order $ability', () {
      final field = ability == 'QuarkDrive'
          ? effects.f(terrain: Terrain.electric)
          : effects.f(weather: Weather.sunlight);
      expect(
        effects
            .hit(
              a: effects.p(ability: ability),
              field: field,
            )
            .attack,
        130,
      );
      expect(effects.hit(a: effects.p(ability: ability)).attack, 130);
      expect(
        effects
            .hit(
              a: effects.p(ability: ability, item: 'BoosterEnergy'),
            )
            .attack,
        130,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: ability, boosted: Stat.spe),
              field: field,
            )
            .attack,
        100,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: ability, stats: {Stat.spa: 150}),
              move: effects.m(category: Category.special),
              field: field,
            )
            .attack,
        195,
      );
      expect(
        effects
            .hit(
              d: effects.p(ability: ability, boosted: Stat.def),
              field: field,
            )
            .defense,
        130,
      );
    });
  }
}
