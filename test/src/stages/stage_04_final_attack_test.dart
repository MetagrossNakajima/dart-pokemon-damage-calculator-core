import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../support/calculator_fixtures.dart' as calculator;
import '../../support/effects_fixtures.dart' as effects;

void main() {
  {
    test(
      'critical retains beneficial attacker and negative defender ranks',
      () {
        final h = calculator
            .damage(
              a: calculator.pokemon(ranks: {Stat.atk: 2}),
              d: calculator.pokemon(ranks: {Stat.def: -2}),
              crit: true,
            )
            .hits
            .single;
        expect(h.attack, 200);
        expect(h.defense, 50);
      },
    );
  }
  {
    test('special stat sources, Unaware and ignored defense boosts', () {
      expect(
        effects
            .hit(
              a: effects.p(stats: {Stat.def: 175}),
              move: effects.m(id: 'BodyPress'),
            )
            .attack,
        175,
      );
      expect(
        effects
            .hit(
              d: effects.p(stats: {Stat.atk: 180}, ranks: {Stat.atk: 2}),
              move: effects.m(id: 'FoulPlay'),
            )
            .attack,
        360,
      );
      expect(
        effects
            .hit(
              a: effects.p(ranks: {Stat.atk: 6}),
              d: effects.p(ability: 'Unaware'),
            )
            .attack,
        100,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'Unaware'),
              d: effects.p(ranks: {Stat.def: 6}),
            )
            .defense,
        100,
      );
      for (final id in ['SacredSword', 'ChipAway', 'DarkestLariat']) {
        expect(
          effects
              .hit(
                d: effects.p(ranks: {Stat.def: 6}),
                move: effects.m(id: id),
              )
              .defense,
          100,
        );
      }
      for (final id in ['Psyshock', 'Psystrike', 'SecretSword']) {
        expect(
          effects
              .hit(
                d: effects.p(
                  stats: {Stat.def: 120, Stat.spd: 300},
                  item: 'AssaultVest',
                ),
                move: effects.m(id: id, category: Category.special),
              )
              .defense,
          120,
        );
      }
      expect(
        effects
            .hit(
              d: effects.p(stats: {Stat.def: 120, Stat.spd: 300}),
              field: effects.f(effects: {FieldEffect.wonderRoom}),
            )
            .defense,
        300,
      );
      expect(
        effects
            .hit(
              field: effects.f(
                weather: Weather.sunlight,
                effects: {FieldEffect.attackerFlowerGift},
              ),
            )
            .attack,
        150,
      );
      expect(
        effects
            .hit(
              move: effects.m(category: Category.special),
              field: effects.f(
                weather: Weather.sunlight,
                effects: {FieldEffect.defenderFlowerGift},
              ),
            )
            .defense,
        150,
      );
    });
  }
}
