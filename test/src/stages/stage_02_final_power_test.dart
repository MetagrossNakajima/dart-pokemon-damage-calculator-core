import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import '../../support/calculator_fixtures.dart' as calculator;
import '../../support/fixed_hit_damage_fixtures.dart' as fixed_hit;

import '../../support/effects_fixtures.dart' as effects;

void main() {
  test('Hex doubles power only for active Comatose', () {
    for (final suppressed in [false, true]) {
      final result = effects.hit(
        move: effects.m(
          id: 'Hex',
          type: 'Ghost',
          power: 65,
          category: Category.special,
        ),
        d: effects.p(
          ability: 'Comatose',
          types: ['Psychic'],
          flags: {PokemonFlag.abilitySuppressed: suppressed},
        ),
      );
      expect(result.power, suppressed ? 65 : 130);
      expect(result.rolls.first, suppressed ? 50 : 100);
      expect(result.rolls.last, suppressed ? 60 : 118);
    }
  });
  {
    for (final status in [null, ...Status.values]) {
      for (final id in ['Facade', 'Hex', 'Acrobatics']) {
        for (final item in [null, 'Leftovers']) {
          test('power condition $id $status $item', () {
            final r = calculator.damage(
              a: calculator.pokemon(status: status, item: item),
              d: calculator.pokemon(status: status),
              m: calculator.move(id: id),
            );
            final doubled = id == 'Acrobatics'
                ? item == null
                : id == 'Hex'
                ? status != null
                : [
                    Status.burn,
                    Status.poison,
                    Status.toxic,
                    Status.paralysis,
                  ].contains(status);
            expect(r.hits.single.power, doubled ? 80 : 40);
          });
        }
      }
    }

    for (final weight in [
      1.0,
      9.9,
      10.0,
      24.9,
      25.0,
      49.9,
      50.0,
      99.9,
      100.0,
      199.9,
      200.0,
    ]) {
      for (final id in ['LowKick', 'GrassKnot']) {
        test('weight $id $weight', () {
          expect(
            calculator
                .damage(
                  d: calculator.pokemon(weight: weight),
                  m: calculator.move(id: id),
                )
                .hits
                .single
                .power,
            weight < 10
                ? 20
                : weight < 25
                ? 40
                : weight < 50
                ? 60
                : weight < 100
                ? 80
                : weight < 200
                ? 100
                : 120,
          );
        });
      }
    }

    for (final ratio in [1.0, 1.99, 2.0, 2.99, 3.0, 3.99, 4.0, 4.99, 5.0]) {
      for (final id in ['HeavySlam', 'HeatCrash']) {
        test('weight ratio $id $ratio', () {
          expect(
            calculator
                .damage(
                  a: calculator.pokemon(weight: ratio * 100),
                  d: calculator.pokemon(weight: 100),
                  m: calculator.move(id: id),
                )
                .hits
                .single
                .power,
            ratio < 2
                ? 40
                : ratio < 3
                ? 60
                : ratio < 4
                ? 80
                : ratio < 5
                ? 100
                : 120,
          );
        });
      }
    }
  }
  {
    for (final entry in {
      MoveId.crushGrip: 120,
      MoveId.wringOut: 120,
      MoveId.hardPress: 100,
    }.entries) {
      test('${entry.key.value} uses full HP power at every current HP', () {
        final full = fixed_hit.damage(entry.key);
        for (final hp in [1, 100, 199]) {
          final partial = fixed_hit.damage(entry.key, hp: hp);
          expect(partial.hits.single.power, entry.value);
          expect(partial.distribution.weights, full.distribution.weights);
        }
      });
    }

    test('fixed full HP power and selected Multiscale ignore current HP', () {
      final full = fixed_hit.damage(
        MoveId.crushGrip,
        ability: AbilityId.multiscale,
      );
      final partial = fixed_hit.damage(
        MoveId.crushGrip,
        hp: 100,
        ability: AbilityId.multiscale,
      );
      expect(full.hits.single.power, 120);
      expect(partial.hits.single.power, 120);
      expect(full.max, 40);
      expect(partial.max, 40);
    });
  }
  {
    test('Normalize lets a Normal Gem be consumed before Acrobatics', () {
      final result = effects.hit(
        a: effects.p(ability: 'Normalize', item: 'NormalGem'),
        move: effects.m(id: 'Acrobatics', type: 'Flying'),
      );

      expect(result.power, 125);
      expect(
        result.trace
            .singleWhere((entry) => entry.stage == ModifierStage.basePower)
            .after,
        80,
      );
      expect(result.trace.any((entry) => entry.id == 'NormalGem'), true);
    });

    test('other power states', () {
      expect(
        effects
            .hit(
              move: effects.m(id: 'GravApple'),
              field: effects.f(gravity: true),
            )
            .power,
        60,
      );
      expect(
        effects
            .hit(
              move: effects.m(id: 'KnockOff'),
              d: effects.p(item: 'Leftovers'),
            )
            .power,
        60,
      );
      expect(
        effects
            .hit(
              move: effects.m(id: 'KnockOff'),
              d: effects.p(
                item: 'Leftovers',
                flags: {PokemonFlag.itemRemovable: false},
              ),
            )
            .power,
        40,
      );
      expect(
        effects
            .hit(
              move: effects.m(type: 'Electric'),
              a: effects.p(flags: {PokemonFlag.charge: true}),
            )
            .power,
        80,
      );
      expect(
        effects
            .hit(
              move: effects.m(type: 'Fire'),
              d: effects.p(ability: 'DrySkin'),
            )
            .power,
        50,
      );
      expect(
        effects
            .hit(
              move: effects.m(type: 'Fire'),
              field: effects.f(effects: {FieldEffect.waterSport}),
            )
            .power,
        13,
      );
      expect(
        effects
            .hit(
              move: effects.m(type: 'Electric'),
              field: effects.f(effects: {FieldEffect.mudSport}),
            )
            .power,
        13,
      );
      expect(
        effects
            .hit(
              move: effects.m(id: 'SolarBeam'),
              field: effects.f(weather: Weather.rain),
            )
            .power,
        20,
      );
      expect(
        effects
            .hit(
              move: effects.m(id: 'SolarBlade'),
              a: effects.p(ability: 'MegaSol'),
              field: effects.f(weather: Weather.rain),
            )
            .power,
        40,
      );
    });
  }
  {
    test('tera minimum excludes priority and natural multi hit moves', () {
      final priority = MoveDto(
        id: moveId('Tackle'),
        type: PokemonType.normal,
        power: 40,
        category: Category.physical,
        priority: 1,
      );
      expect(
        calculator
            .damage(
              a: effects.p(tera: 'Normal'),
              m: priority,
            )
            .hits
            .first
            .power,
        40,
      );
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Normal'),
              move: effects.m(id: 'DoubleKick'),
            )
            .power,
        40,
      );
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Normal', hp: 1),
              move: effects.m(id: 'Eruption'),
            )
            .power,
        1,
      );
    });

    test('Flail and Reversal use every HP-ratio power tier', () {
      for (final (id, hp, expected) in [
        ('Flail', 1, 200),
        ('Reversal', 20, 150),
        ('Flail', 40, 100),
        ('Reversal', 70, 80),
        ('Flail', 130, 40),
        ('Reversal', 200, 20),
      ]) {
        expect(
          effects
              .hit(
                a: effects.p(hp: hp),
                move: effects.m(id: id),
              )
              .power,
          expected,
          reason: '$id at $hp/200 HP',
        );
      }
    });

    test('HP dependent power and volatile counters', () {
      expect(
        effects
            .hit(
              a: effects.p(hp: 100),
              move: effects.m(id: 'Eruption'),
            )
            .power,
        75,
      );
      expect(
        effects
            .hit(
              d: effects.p(hp: 100),
              move: effects.m(id: 'CrushGrip'),
            )
            .power,
        120,
      );
      expect(
        effects
            .hit(
              d: effects.p(hp: 100),
              move: effects.m(id: 'HardPress'),
            )
            .power,
        100,
      );
      expect(
        effects
            .hit(
              a: effects.p(fainted: 3),
              move: effects.m(id: 'LastRespects'),
            )
            .power,
        200,
      );
      expect(
        effects
            .hit(
              a: effects.p(timesHit: 8),
              move: effects.m(id: 'RageFist'),
            )
            .power,
        350,
      );
      expect(
        effects
            .hit(
              a: effects.p(flags: {PokemonFlag.movesFirst: true}),
              move: effects.m(id: 'FishiousRend'),
            )
            .power,
        80,
      );
      expect(
        effects
            .hit(
              d: effects.p(flags: {PokemonFlag.damagedThisTurn: true}),
              move: effects.m(id: 'Assurance'),
            )
            .power,
        80,
      );
    });
  }
}
