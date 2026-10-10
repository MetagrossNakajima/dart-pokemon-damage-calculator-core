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
import '../../support/effect_regressions_fixtures.dart' as regressions;

void main() {
  group('追加特性の無効化', () {
    // Smogon cf95cb685b6cbbda1ea5f9dc783f62e3c3e3e900 / Gen 9。
    // Lv50、HP200、その他の実数値100、両者ノーマルタイプで16乱数を取得。
    final cases = [
      (
        name: 'こんがりボディ',
        condition: '炎技',
        ability: 'WellBakedBody',
        move: effects.m(
          id: 'Flamethrower',
          type: 'Fire',
          power: 90,
          category: Category.special,
        ),
        rolls: [34, 35, 35, 36, 36, 36, 37, 37, 38, 38, 38, 39, 39, 40, 40, 41],
      ),
      (
        name: 'どしょく',
        condition: '地面技',
        ability: 'EarthEater',
        move: effects.m(id: 'Earthquake', type: 'Ground', power: 100),
        rolls: [39, 39, 40, 40, 40, 41, 41, 42, 42, 43, 43, 44, 44, 45, 45, 46],
      ),
      (
        name: 'かぜのり',
        condition: '風技',
        ability: 'WindRider',
        move: effects.m(
          id: 'Hurricane',
          type: 'Flying',
          power: 110,
          category: Category.special,
          flags: {MoveFlag.wind},
        ),
        rolls: [42, 43, 43, 44, 44, 45, 45, 46, 46, 47, 47, 48, 48, 49, 49, 50],
      ),
    ];

    for (final c in cases) {
      test('${c.condition} → ${c.name}', () {
        regressions.expectRolls(
          calculator.damage(
            d: effects.p(ability: c.ability),
            m: c.move,
          ),
          List.filled(16, 0),
        );
      });

      test('${c.name}はかたやぶり系で無視できる', () {
        for (final ability in ['MoldBreaker', 'Teravolt', 'Turboblaze']) {
          regressions.expectRolls(
            calculator.damage(
              a: effects.p(ability: ability),
              d: effects.p(ability: c.ability),
              m: c.move,
            ),
            c.rolls,
          );
        }
      });

      test('${c.name}は有効なとくせいガードで守られる', () {
        for (final ability in ['MoldBreaker', 'NeutralizingGas']) {
          regressions.expectRolls(
            calculator.damage(
              a: effects.p(ability: ability),
              d: effects.p(ability: c.ability, item: 'AbilityShield'),
              m: c.move,
            ),
            List.filled(16, 0),
          );
        }
      });

      test('${c.name}は特性抑制とガスで効果を失う', () {
        regressions.expectRolls(
          calculator.damage(
            d: effects.p(
              ability: c.ability,
              flags: {PokemonFlag.abilitySuppressed: true},
            ),
            m: c.move,
          ),
          c.rolls,
        );
        regressions.expectRolls(
          calculator.damage(
            a: effects.p(ability: 'NeutralizingGas'),
            d: effects.p(ability: c.ability),
            m: c.move,
          ),
          c.rolls,
        );
      });

      test('${c.name}は対象外の技を無効化しない', () {
        regressions.expectRolls(
          calculator.damage(
            d: effects.p(ability: c.ability),
            m: effects.m(type: 'Dragon'),
          ),
          regressions.neutralRolls,
        );
      });
    }

    test('かぜのりは風フラグのない飛行技を無効化しない', () {
      regressions.expectRolls(
        calculator.damage(
          d: effects.p(ability: 'WindRider'),
          m: effects.m(
            id: 'Hurricane',
            type: 'Flying',
            power: 110,
            category: Category.special,
          ),
        ),
        cases.last.rolls,
      );
    });

    test('どしょくはじゅうりょく下のサウザンアローも無効化する', () {
      regressions.expectRolls(
        calculator.damage(
          d: effects.p(ability: 'EarthEater'),
          m: effects.m(id: 'ThousandArrows', type: 'Ground', power: 90),
          f: effects.f(gravity: true),
        ),
        List.filled(16, 0),
      );
    });
  });
  {
    test('typing, immunity, gravity, dual types and Freeze Dry', () {
      expect(calculator.damage(d: calculator.pokemon(types: ['Ghost'])).max, 0);
      expect(
        calculator.damage(d: calculator.pokemon(types: ['Rock', 'Steel'])).max,
        7,
      );
      expect(
        calculator
            .damage(
              d: calculator.pokemon(types: ['Water', 'Flying']),
              m: calculator.move(id: 'FreezeDry', type: 'Ice'),
            )
            .max,
        76,
      );
      for (final gravity in [false, true]) {
        for (final ability in [null, 'Levitate']) {
          for (final type in ['Normal', 'Flying']) {
            for (final bypass in [null, 'MoldBreaker']) {
              final r = calculator.damage(
                a: calculator.pokemon(ability: bypass),
                d: calculator.pokemon(types: [type], ability: ability),
                m: calculator.move(type: 'Ground'),
                f: BattleFieldDto(
                  format: BattleFormat.single,
                  gravity: gravity,
                ),
              );
              final immune =
                  !gravity &&
                  (type == 'Flying' || ability == 'Levitate' && bypass == null);
              expect(r.max, immune ? 0 : 19);
            }
          }
        }
      }
      expect(
        calculator
            .damage(
              a: calculator.pokemon(stat: 1),
              d: calculator.pokemon(stat: 999, reflect: true),
              m: calculator.move(power: 1),
            )
            .min,
        1,
      );
    });
  }
  {
    test('type traces use actual multipliers and floor damage', () {
      for (final (types, multiplier) in [
        (['Normal'], 1.0),
        (['Grass'], 2.0),
        (['Grass', 'Ice'], 4.0),
        (['Water'], 0.5),
        (['Water', 'Rock'], 0.25),
      ]) {
        final result = effects.hit(
          d: effects.p(types: types),
          move: effects.m(type: 'Fire'),
        );
        final trace = result.trace.firstWhere((entry) => entry.id == 'Type');
        expect(trace.numerator, multiplier);
        expect(trace.denominator, 1);
        expect(trace.after, (trace.before * multiplier).floor());
      }
    });

    for (final id in ['Scrappy', 'MindsEye']) {
      test('ghost bypass $id', () {
        expect(
          effects
              .hit(
                a: effects.p(ability: id),
                d: effects.p(types: ['Ghost']),
              )
              .rolls
              .last,
          28,
        );
        expect(
          effects
              .hit(
                a: effects.p(ability: id),
                d: effects.p(types: ['Ghost', 'Rock']),
              )
              .rolls
              .last,
          14,
        );
        expect(
          effects
              .hit(
                a: effects.p(ability: id),
                d: effects.p(types: ['Ghost']),
                move: effects.m(type: 'Psychic'),
              )
              .rolls
              .last,
          19,
        );
      });
    }

    test('Ring Target removes type immunity but not ability immunity', () {
      expect(
        effects
            .hit(
              d: effects.p(types: ['Ghost'], item: 'RingTarget'),
            )
            .rolls
            .last,
        28,
      );
      expect(
        effects
            .hit(
              d: effects.p(ability: 'Levitate', item: 'RingTarget'),
              move: effects.m(type: 'Ground'),
            )
            .rolls
            .last,
        0,
      );
    });

    test('Flying Press multiplies fighting and flying matchups', () {
      expect(
        effects
            .hit(
              move: effects.m(id: 'FlyingPress', type: 'Fighting'),
              d: effects.p(types: ['Grass', 'Normal']),
            )
            .rolls
            .last,
        76,
      );
      expect(
        effects
            .hit(
              move: effects.m(id: 'FlyingPress', type: 'Fighting'),
              d: effects.p(types: ['Ghost']),
            )
            .rolls
            .last,
        0,
      );
    });

    final immuneCases = [
      ('FlashFire', 'Fire', <MoveFlag>{}),
      ('WaterAbsorb', 'Water', <MoveFlag>{}),
      ('StormDrain', 'Water', <MoveFlag>{}),
      ('DrySkin', 'Water', <MoveFlag>{}),
      ('VoltAbsorb', 'Electric', <MoveFlag>{}),
      ('LightningRod', 'Electric', <MoveFlag>{}),
      ('MotorDrive', 'Electric', <MoveFlag>{}),
      ('SapSipper', 'Grass', <MoveFlag>{}),
      ('Soundproof', 'Normal', {MoveFlag.sound}),
      ('Bulletproof', 'Normal', {MoveFlag.bullet}),
    ];

    for (final c in immuneCases) {
      test('immunity and bypass ${c.$1}', () {
        expect(
          effects
              .hit(
                d: effects.p(ability: c.$1),
                move: effects.m(type: c.$2, flags: c.$3),
              )
              .rolls
              .last,
          0,
        );
        expect(
          effects
              .hit(
                a: effects.p(ability: 'MoldBreaker'),
                d: effects.p(ability: c.$1),
                move: effects.m(type: c.$2, flags: c.$3),
              )
              .rolls
              .last,
          greaterThan(0),
        );
        expect(
          effects
              .hit(
                d: effects.p(ability: c.$1),
                move: effects.m(type: 'Dragon'),
              )
              .rolls
              .last,
          19,
        );
      });
    }

    test('Wonder Guard uses the final dual-type effectiveness', () {
      expect(
        effects
            .hit(
              d: effects.p(ability: 'WonderGuard', types: ['Bug', 'Ghost']),
            )
            .rolls
            .last,
        0,
      );
      expect(
        effects
            .hit(
              d: effects.p(ability: 'WonderGuard', types: ['Bug', 'Ghost']),
              move: effects.m(type: 'Fire'),
            )
            .rolls
            .last,
        38,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'MoldBreaker'),
              d: effects.p(ability: 'WonderGuard'),
              move: effects.m(type: 'Dragon'),
            )
            .rolls
            .last,
        19,
      );
    });
  }
  {
    group('Ground immunity separates typing from ability and item immunity', () {
      test(
        'Ring Target removes Flying immunity without grounding the holder',
        () {
          regressions.expectRolls(
            regressions.damage(
              defender: regressions.pokemon(
                types: [PokemonType.flying],
                item: ItemId.ringTarget,
              ),
            ),
            regressions.neutralRolls,
          );
          // Ring Target affects the type chart, not spikes grounding (util.ts).
          regressions.expectHp(
            regressions.combine(
              defender: regressions.pokemon(
                types: [PokemonType.flying],
                item: ItemId.ringTarget,
              ),
              hazards: const EntryHazardsDto(
                stealthRock: true,
                spikesLayers: 3,
              ),
            ),
            150,
          );
        },
      );

      test('Ring Target does not remove Levitate immunity', () {
        for (final type in [PokemonType.normal, PokemonType.flying]) {
          regressions.expectRolls(
            regressions.damage(
              defender: regressions.pokemon(
                types: [type],
                ability: AbilityId.levitate,
                item: ItemId.ringTarget,
              ),
            ),
            List.filled(16, 0),
          );
        }
      });

      test('Gravity and Iron Ball bypass Flying and Levitate immunity', () {
        for (final item in [null, ItemId.ironBall]) {
          regressions.expectRolls(
            regressions.damage(
              defender: regressions.pokemon(
                types: [PokemonType.flying],
                ability: AbilityId.levitate,
                item: item,
              ),
              field: regressions.defaultField(gravity: item == null),
            ),
            regressions.neutralRolls,
          );
        }
      });

      test('Air Balloon grants Ground immunity until consumed or gravity', () {
        regressions.expectRolls(
          regressions.damage(
            defender: regressions.pokemon(item: ItemId.airBalloon),
          ),
          List.filled(16, 0),
        );
        regressions.expectRolls(
          regressions.damage(
            defender: regressions.pokemon(
              item: ItemId.airBalloon,
              itemConsumed: true,
            ),
          ),
          regressions.neutralRolls,
        );
        regressions.expectRolls(
          regressions.damage(
            defender: regressions.pokemon(item: ItemId.airBalloon),
            field: regressions.defaultField(gravity: true),
          ),
          regressions.neutralRolls,
        );
      });
    });

    group('Stellar effectiveness still runs ability immunity checks', () {
      final attacker = regressions.pokemon(
        tera: TeraType.stellar,
        flags: {PokemonFlag.stellarBoostAvailable: false},
      );

      test(
        'Stellar Tera Blast cannot damage a non-Tera Wonder Guard holder',
        () {
          regressions.expectRolls(
            regressions.damage(
              attacker: attacker,
              defender: regressions.pokemon(ability: AbilityId.wonderGuard),
              id: MoveId.teraBlast,
              type: PokemonType.normal,
            ),
            List.filled(16, 0),
          );
        },
      );

      test(
        'Stellar Tera Blast is super effective against a Tera Wonder Guard holder',
        () {
          // Tera Blast power100 has base damage46; used Stellar boost has no STAB.
          regressions.expectRolls(
            regressions.damage(
              attacker: attacker,
              defender: regressions.pokemon(
                ability: AbilityId.wonderGuard,
                tera: TeraType.grass,
              ),
              id: MoveId.teraBlast,
              type: PokemonType.normal,
            ),
            regressions.stellarSuperEffectiveRolls,
          );
        },
      );
    });
  }
}
