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
import '../../support/input_adapter.dart' as adapter;
import '../../support/calculator_fixtures.dart' as calculator;
import '../../support/pokemon_patch.dart';

import '../../support/effects_fixtures.dart' as effects;

void main() {
  {
    test(
      'full HP shields distinguish bypassable and unbypassable abilities',
      () {
        final a = calculator.pokemon(ability: 'MoldBreaker');
        expect(
          calculator
              .damage(
                a: a,
                d: calculator.pokemon(ability: 'Multiscale'),
              )
              .max,
          28,
        );
        expect(
          calculator
              .damage(
                a: a,
                d: calculator.pokemon(ability: 'ShadowShield'),
              )
              .max,
          14,
        );
        expect(
          calculator
              .damage(
                d: calculator.pokemon(ability: 'Multiscale', fullHp: false),
              )
              .max,
          28,
        );
      },
    );

    for (final weather in [null, ...Weather.values]) {
      for (final type in ['Fire', 'Water', 'Rock', 'Ice', 'Normal']) {
        for (final category in Category.values) {
          test('weather $weather $type $category', () {
            final r = calculator.damage(
              d: calculator.pokemon(
                types: [type],
                stat: 101,
                item: 'AssaultVest',
              ),
              m: calculator.move(type: type, category: category, spread: true),
              f: BattleFieldDto(format: BattleFormat.double, weather: weather),
            );
            final boosted =
                weather == Weather.sandstorm &&
                    type == 'Rock' &&
                    category == Category.special ||
                weather == Weather.snow &&
                    type == 'Ice' &&
                    category == Category.physical;
            final defense = boosted ? 151 : 101;
            expect(
              r.hits.single.defense,
              category == Category.special
                  ? (defense * 1.5 - 0.00001).round()
                  : defense,
            );
            expect(r.hits.single.trace.any((t) => t.id == 'Spread'), true);
          });
        }
      }
    }

    for (final format in BattleFormat.values) {
      for (final category in Category.values) {
        test('screens $format $category', () {
          final r = calculator.damage(
            d: calculator.pokemon(reflect: true, lightScreen: true),
            m: calculator.move(category: category),
            f: BattleFieldDto(format: format),
          );
          expect(
            r.hits.single.trace.firstWhere((t) => t.id == 'Screen').numerator,
            format == BattleFormat.single ? 2048 : 2732,
          );
        });
      }
    }
  }
  {
    final finalCases = [
      (
        'Neuroforce',
        5120,
        effects.p(ability: 'Neuroforce'),
        effects.p(types: ['Grass']),
        effects.m(type: 'Fire'),
        false,
      ),
      (
        'Sniper',
        6144,
        effects.p(ability: 'Sniper'),
        effects.p(),
        effects.m(),
        true,
      ),
      (
        'TintedLens',
        8192,
        effects.p(ability: 'TintedLens'),
        effects.p(types: ['Rock']),
        effects.m(),
        false,
      ),
      (
        'FluffyContact',
        2048,
        effects.p(),
        effects.p(ability: 'Fluffy'),
        effects.m(flags: {MoveFlag.contact}),
        false,
      ),
      (
        'WaveShield',
        2048,
        effects.p(),
        effects.p(ability: 'WaveShield'),
        effects.m(flags: {MoveFlag.contact}),
        false,
      ),
      (
        'PunkRock',
        2048,
        effects.p(),
        effects.p(ability: 'PunkRock'),
        effects.m(flags: {MoveFlag.sound}),
        false,
      ),
      (
        'IceScales',
        2048,
        effects.p(),
        effects.p(ability: 'IceScales'),
        effects.m(category: Category.special),
        false,
      ),
      (
        'SolidRock',
        3072,
        effects.p(),
        effects.p(ability: 'SolidRock', types: ['Grass']),
        effects.m(type: 'Fire'),
        false,
      ),
      (
        'Filter',
        3072,
        effects.p(),
        effects.p(ability: 'Filter', types: ['Grass']),
        effects.m(type: 'Fire'),
        false,
      ),
      (
        'PrismArmor',
        3072,
        effects.p(),
        effects.p(ability: 'PrismArmor', types: ['Grass']),
        effects.m(type: 'Fire'),
        false,
      ),
      (
        'FluffyFire',
        8192,
        effects.p(),
        effects.p(ability: 'Fluffy'),
        effects.m(type: 'Fire'),
        false,
      ),
      (
        'ExpertBelt',
        4915,
        effects.p(item: 'ExpertBelt'),
        effects.p(types: ['Grass']),
        effects.m(type: 'Fire'),
        false,
      ),
    ];

    for (final c in finalCases) {
      test('final modifier ${c.$1}', () {
        final hit = effects.hit(a: c.$3, d: c.$4, move: c.$5, crit: c.$6);
        expect(
          hit.trace
              .firstWhere(
                (t) => t.id == c.$1 && t.stage == ModifierStage.damageModifier,
              )
              .numerator,
          c.$2,
        );
        final base = calculator.damage(
          a: PokemonPatch(
            ability: const Replacement(null),
            item: const Replacement(null),
          ).apply(c.$3),
          d: PokemonPatch(ability: const Replacement(null)).apply(c.$4),
          m: c.$5,
          crit: c.$6,
        );
        // The factor acts after random, STAB, effectiveness and burn.
        final expected = (base.max * c.$2 * 2 + 4095) ~/ (8192);
        expect(hit.rolls.last, expected);
      });
    }

    test('friend guard, unnerve, ripen and wall removal', () {
      expect(
        effects
            .hit(field: effects.f(effects: {FieldEffect.friendGuard}))
            .rolls
            .last,
        21,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'Unnerve'),
              d: effects.p(item: 'ChilanBerry'),
            )
            .rolls
            .last,
        28,
      );
      expect(
        effects
            .hit(
              d: effects.p(ability: 'Ripen', item: 'ChilanBerry'),
            )
            .rolls
            .last,
        7,
      );
      for (final id in ['BrickBreak', 'RagingBull']) {
        final defender = PokemonPatch(reflect: true).apply(effects.p());
        expect(
          effects
              .hit(
                d: defender,
                move: effects.m(id: id),
              )
              .rolls
              .last,
          28,
        );
      }
    });

    test(
      'defensive abilities which resist Mold Breaker retain their reduction',
      () {
        expect(
          effects
              .hit(
                a: effects.p(ability: 'MoldBreaker'),
                d: effects.p(ability: 'PrismArmor', types: ['Grass']),
                move: effects.m(type: 'Fire'),
              )
              .rolls
              .last,
          28,
        );
        expect(
          effects
              .hit(
                a: effects.p(ability: 'MoldBreaker'),
                d: effects.p(ability: 'SolidRock', types: ['Grass']),
                move: effects.m(type: 'Fire'),
              )
              .rolls
              .last,
          38,
        );
      },
    );
  }
  {
    test('Parental Bond second hit applies quarter modifier', () {
      final result = calculator.ok(
        adapter.calculateDamage(
          DamageRequestDto(
            attacker: effects.p(ability: 'ParentalBond'),
            defender: effects.p(),
            move: effects.m(),
            field: effects.f(),
            hitIndex: 1,
          ),
        ),
      );
      expect(result.hits.single.trace.any((t) => t.id == 'ParentalBond'), true);
      expect(result.min, 6);
      expect(result.max, 7);
    });
  }
}
