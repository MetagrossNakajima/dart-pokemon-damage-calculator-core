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
import '../../support/state_transition_fixtures.dart' as special_damage;

void main() {
  group('special damage', () {
    final cases = <String, int>{
      'SuperFang': 50,
      'NaturesMadness': 50,
      'Ruination': 50,
      'GuardianofAlola': 75,
      'FinalGambit': 30,
      'Endeavor': 71,
      'SonicBoom': 20,
      'DragonRage': 40,
      'SeismicToss': 50,
      'NightShade': 50,
      'Fissure': 101,
      'SheerCold': 101,
      'HornDrill': 101,
      'Guillotine': 101,
    };
    for (final entry in cases.entries) {
      test('${entry.key} returns one exact fixed outcome', () {
        final result = special_damage.damage(
          special_damage.fixedMove(entry.key),
        );
        expect(result.distribution.weights, {entry.value: BigInt.one});
        expect(result.hits.single.kind, DamageKind.fixed);
        expect(result.hits.single.critical, isFalse);
        expect(result.hits.single.power, 0);
        expect(result.hits.single.attack, 100);
        expect(result.hits.single.defense, 100);
      });
    }

    test('NaturesMadness floors remaining HP without a minimum', () {
      for (final hp in [1, 2, 3, 100, 101]) {
        final result = special_damage.damage(
          special_damage.fixedMove('NaturesMadness', type: 'Fairy'),
          defender: special_damage.pokemon(
            currentHp: hp,
            stats: const StatsDto(
              hp: 101,
              atk: 100,
              def: 100,
              spa: 100,
              spd: 100,
              spe: 100,
            ),
          ),
        );
        expect(result.hits.single.rolls, [hp ~/ 2]);
        expect(result.distribution.weights, {hp ~/ 2: BigInt.one});
        expect(result.hits.single.kind, DamageKind.fixed);
      }
    });

    test('SuperFang and Ruination retain one damage at one HP', () {
      for (final id in ['SuperFang', 'Ruination']) {
        expect(
          special_damage
              .damage(
                special_damage.fixedMove(id),
                defender: special_damage.pokemon(currentHp: 1),
              )
              .distribution
              .weights,
          {1: BigInt.one},
        );
      }
    });

    test('NaturesMadness preserves resistance and ability immunity rules', () {
      for (final c in [
        (types: ['Steel'], ability: null, damage: 50),
        (types: ['Normal'], ability: 'WonderGuard', damage: 0),
      ]) {
        expect(
          special_damage
              .damage(
                special_damage.fixedMove('NaturesMadness', type: 'Fairy'),
                defender: special_damage.pokemon(
                  types: c.types,
                  ability: c.ability,
                ),
              )
              .distribution
              .weights,
          {c.damage: BigInt.one},
        );
      }
      expect(
        special_damage
            .damage(
              special_damage.fixedMove('Ruination', type: 'Dark'),
              defender: special_damage.pokemon(
                ability: 'WonderGuard',
                currentHp: 1,
              ),
            )
            .distribution
            .weights,
        {0: BigInt.one},
      );
    });

    test('fractional moves preserve their individual minimum damage', () {
      final oneHp = special_damage.pokemon(currentHp: 1);
      expect(
        special_damage
            .damage(special_damage.fixedMove('SuperFang'), defender: oneHp)
            .min,
        1,
      );
      expect(
        special_damage
            .damage(
              special_damage.fixedMove('GuardianofAlola'),
              defender: oneHp,
            )
            .min,
        0,
      );
      expect(
        special_damage
            .damage(
              special_damage.fixedMove('Endeavor'),
              attacker: special_damage.pokemon(currentHp: 80),
              defender: special_damage.pokemon(currentHp: 40),
            )
            .min,
        0,
      );
    });

    test(
      'type and ability immunities apply without resistance multipliers',
      () {
        expect(
          special_damage
              .damage(
                special_damage.fixedMove('SuperFang'),
                defender: special_damage.pokemon(
                  types: ['Ghost'],
                  currentHp: 100,
                ),
              )
              .min,
          0,
        );
        expect(
          special_damage
              .damage(
                special_damage.fixedMove('DragonRage', type: 'Dragon'),
                defender: special_damage.pokemon(types: ['Fairy']),
              )
              .min,
          0,
        );
        expect(
          special_damage
              .damage(
                special_damage.fixedMove('SonicBoom'),
                defender: special_damage.pokemon(types: ['Rock']),
              )
              .min,
          20,
        );
        expect(
          special_damage
              .damage(
                special_damage.fixedMove('SheerCold', type: 'Ice'),
                defender: special_damage.pokemon(types: ['Ice']),
              )
              .min,
          0,
        );
      },
    );

    test('OHKO grounding, Scrappy, Sturdy, and Mold Breaker are respected', () {
      expect(
        special_damage
            .damage(
              special_damage.fixedMove('Fissure', type: 'Ground'),
              defender: special_damage.pokemon(types: ['Flying']),
            )
            .min,
        0,
      );
      expect(
        special_damage
            .damage(
              special_damage.fixedMove('Fissure', type: 'Ground'),
              defender: special_damage.pokemon(types: ['Flying']),
              field: BattleFieldDto(format: BattleFormat.single, gravity: true),
            )
            .min,
        100,
      );
      expect(
        special_damage
            .damage(
              special_damage.fixedMove('HornDrill'),
              attacker: special_damage.pokemon(ability: 'Scrappy'),
              defender: special_damage.pokemon(types: ['Ghost']),
            )
            .min,
        100,
      );
      expect(
        special_damage
            .damage(
              special_damage.fixedMove('Guillotine'),
              defender: special_damage.pokemon(ability: 'Sturdy'),
            )
            .min,
        0,
      );
      expect(
        special_damage
            .damage(
              special_damage.fixedMove('Guillotine'),
              attacker: special_damage.pokemon(ability: 'MoldBreaker'),
              defender: special_damage.pokemon(ability: 'Sturdy'),
            )
            .min,
        100,
      );
    });

    test('normal modifiers and Parental Bond do not change fixed damage', () {
      final result = special_damage.damage(
        special_damage.fixedMove('SonicBoom'),
        attacker: special_damage.pokemon(ability: 'ParentalBond'),
        defender: special_damage.pokemon(types: ['Normal', 'Flying']),
        field: BattleFieldDto(
          format: BattleFormat.double,
          weather: Weather.rain,
        ),
      );
      expect(result.distribution.weights, {20: BigInt.one});
      expect(result.hits, hasLength(1));
      expect(result.hits.single.trace, isEmpty);
    });
  });
}
