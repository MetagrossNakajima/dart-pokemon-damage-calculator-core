import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import '../../support/pokemon_patch.dart';
import 'package:test/test.dart';
import '../../support/effects_fixtures.dart' as effects;
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

void main() {
  {
    test('weight modifiers use decagram truncation and can be suppressed', () {
      expect(
        effects
            .hit(
              d: effects.p(ability: 'HeavyMetal'),
              move: effects.m(id: 'LowKick'),
            )
            .power,
        100,
      );
      expect(
        effects
            .hit(
              d: effects.p(ability: 'LightMetal'),
              move: effects.m(id: 'LowKick'),
            )
            .power,
        60,
      );
      expect(
        effects
            .hit(
              d: effects.p(item: 'FloatStone'),
              move: effects.m(id: 'LowKick'),
            )
            .power,
        60,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'MoldBreaker'),
              d: effects.p(ability: 'HeavyMetal'),
              move: effects.m(id: 'LowKick'),
            )
            .power,
        80,
      );
      final small = PokemonPatch(
        weight: 0.1,
      ).apply(effects.p(ability: 'LightMetal', item: 'FloatStone'));
      expect(
        effects
            .hit(
              d: small,
              move: effects.m(id: 'LowKick'),
            )
            .power,
        20,
      );
    });
  }
  {
    test('contact is removed by gloves and Long Reach', () {
      final move = effects.m(flags: {MoveFlag.contact, MoveFlag.punch});
      expect(
        effects
            .hit(
              a: effects.p(ability: 'ToughClaws'),
              move: move,
            )
            .power,
        52,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'ToughClaws', item: 'PunchingGlove'),
              move: move,
            )
            .power,
        44,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'LongReach'),
              d: effects.p(ability: 'Fluffy'),
              move: move,
            )
            .rolls
            .last,
        28,
      );
    });
  }
}
