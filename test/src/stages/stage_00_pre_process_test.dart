import 'dart:convert';
import 'dart:io';
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
import '../../support/input_adapter.dart' as adapter;

void main() {
  {
    final cases =
        jsonDecode(File('test/fixtures/spec_audit.json').readAsStringSync())
            as List<dynamic>;

    for (final weather in [Weather.sandstorm, Weather.snow]) {
      for (final ability in ['CloudNine', 'AirLock']) {
        for (final onAttacker in [true, false]) {
          for (final attackerAbility
              in onAttacker ? [ability] : [null, 'MegaSol']) {
            test(
              'umbrella Weather Ball under $weather with $ability '
              'on ${onAttacker ? 'attacker' : 'defender'} / $attackerAbility',
              () {
                for (final types in [
                  ['Grass'],
                  ['Ghost'],
                ]) {
                  final attacker = effects.p(
                    ability: attackerAbility,
                    item: 'UtilityUmbrella',
                  );
                  final defender = effects.p(
                    ability: onAttacker ? null : ability,
                    types: types,
                  );
                  final actual = effects.hit(
                    a: attacker,
                    d: defender,
                    move: effects.m(
                      id: 'WeatherBall',
                      power: 50,
                      category: Category.special,
                    ),
                    field: effects.f(weather: weather),
                  );
                  // 天候無効化後は参照元と同じNormal・威力50。
                  // 草への乱数全体とゴーストへの無効でタイプ変化も検出する。
                  final normal = effects.hit(
                    a: attacker,
                    d: defender,
                    move: effects.m(power: 50, category: Category.special),
                    field: effects.f(weather: weather),
                  );
                  expect(actual.power, 50);
                  expect(actual.rolls, normal.rolls);
                }
              },
            );
          }
        }
      }
    }

    test('inactive umbrella and suppressed MegaSol use active effects', () {
      final normalRain = cases.cast<Map<String, dynamic>>().singleWhere(
        (c) =>
            c['name'] == 'WeatherBall' &&
            c['weather'] == 'Rain' &&
            c['ability'] == null &&
            c['item'] == null,
      );
      for (final variant in [
        (
          PokemonPatch(
            itemConsumed: true,
          ).apply(effects.p(item: 'UtilityUmbrella')),
          effects.f(weather: Weather.rain),
        ),
        (
          effects.p(
            item: 'UtilityUmbrella',
            flags: {PokemonFlag.itemSuppressed: true},
          ),
          effects.f(weather: Weather.rain),
        ),
        (
          effects.p(item: 'UtilityUmbrella'),
          effects.f(weather: Weather.rain, effects: {FieldEffect.magicRoom}),
        ),
      ]) {
        final result =
            adapter.calculateDamage(
                  DamageRequestDto(
                    attacker: variant.$1,
                    defender: effects.p(),
                    move: effects.m(
                      id: 'WeatherBall',
                      power: 50,
                      category: Category.special,
                    ),
                    field: variant.$2,
                  ),
                )
                as adapter.Success<DamageResult>;
        expect(result.value.hits.first.power, 100);
        expect(result.value.hits.first.rolls, normalRain['rolls']);
      }
      final blocked =
          adapter.calculateDamage(
                DamageRequestDto(
                  attacker: effects.p(
                    ability: 'MegaSol',
                    item: 'UtilityUmbrella',
                    flags: {PokemonFlag.abilitySuppressed: true},
                  ),
                  defender: effects.p(),
                  move: effects.m(
                    id: 'WeatherBall',
                    power: 50,
                    category: Category.special,
                  ),
                  field: effects.f(weather: Weather.rain),
                ),
              )
              as adapter.Success<DamageResult>;
      final umbrellaRain = cases.cast<Map<String, dynamic>>().singleWhere(
        (c) =>
            c['name'] == 'WeatherBall' &&
            c['weather'] == 'Rain' &&
            c['ability'] == null &&
            c['item'] == 'UtilityUmbrella',
      );
      expect(blocked.value.hits.first.power, 50);
      expect(blocked.value.hits.first.rolls, umbrellaRain['rolls']);
    });
  }
  {
    for (final entry in {
      'Galvanize': 'Electric',
      'Aerilate': 'Flying',
      'Pixilate': 'Fairy',
      'Refrigerate': 'Ice',
      'Dragonize': 'Dragon',
    }.entries) {
      test('conversion ${entry.key}', () {
        final a = effects.p(ability: entry.key, types: [entry.value]);
        expect(effects.hit(a: a).power, 48);
        expect(
          effects.hit(a: a).rolls.last,
          34,
        ); // power48 -> base23 -> STAB34.5 rounds34.
        expect(
          effects
              .hit(
                a: a,
                move: effects.m(type: 'Fire'),
              )
              .power,
          40,
        );
      });
    }

    test('weather and terrain preprocessing', () {
      for (final w in Weather.values) {
        expect(
          effects
              .hit(
                move: effects.m(id: 'WeatherBall', power: 50),
                field: effects.f(weather: w),
              )
              .power,
          100,
        );
      }
      expect(
        effects
            .hit(
              move: effects.m(id: 'WeatherBall', power: 50),
              a: effects.p(ability: 'CloudNine'),
              field: effects.f(weather: Weather.rain),
            )
            .power,
        50,
      );
      expect(
        effects
            .hit(
              move: effects.m(id: 'WeatherBall', power: 50),
              d: effects.p(ability: 'AirLock'),
              field: effects.f(weather: Weather.rain),
            )
            .power,
        50,
      );
      expect(
        effects
            .hit(
              move: effects.m(id: 'TerrainPulse', power: 50),
              field: effects.f(terrain: Terrain.misty),
            )
            .power,
        100,
      );
      expect(
        effects
            .hit(
              move: effects.m(id: 'TerrainPulse', power: 50),
              a: effects.p(types: ['Flying']),
              field: effects.f(terrain: Terrain.misty),
            )
            .power,
        50,
      );
      expect(
        effects
            .hit(
              move: effects.m(id: 'RagingBull'),
              a: effects.p(id: 'Tauros-Paldea-Blaze'),
              d: effects.p(types: ['Grass']),
            )
            .rolls
            .last,
        38,
      );
    });
  }
  {
    test(
      'Tera Blast chooses the greater ranked attack and preserves ties as special',
      () {
        final move = effects.m(
          id: 'TeraBlast',
          power: 80,
          category: Category.special,
        );
        expect(
          effects
              .hit(
                a: effects.p(tera: 'Fire', stats: {Stat.atk: 150}),
                move: move,
              )
              .attack,
          150,
        );
        expect(
          effects
              .hit(
                a: effects.p(
                  tera: 'Fire',
                  stats: {Stat.atk: 150},
                  ranks: {Stat.spa: 2},
                ),
                move: move,
              )
              .attack,
          200,
        );
        expect(
          effects
              .hit(
                a: effects.p(tera: 'Fire'),
                d: effects.p(stats: {Stat.spd: 140, Stat.def: 80}),
                move: move,
              )
              .defense,
          140,
        );
        expect(
          effects
              .hit(
                a: effects.p(ability: 'Pixilate'),
                move: move,
              )
              .power,
          96,
        );
      },
    );

    test('Tera Starstorm becomes Stellar for Terapagos-Stellar', () {
      final result = effects.hit(
        a: effects.p(id: 'Terapagos-Stellar'),
        move: effects.m(id: 'TeraStarstorm'),
      );

      expect(result.rolls.last, 19);
      expect(
        result.trace.firstWhere((entry) => entry.id == 'Type').numerator,
        1,
      );
    });
  }
}
