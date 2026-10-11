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
import '../../support/pokemon_patch.dart';
import '../../support/effects_fixtures.dart' as effects;

void main() {
  {
    for (final a in [
      'Guts',
      'HugePower',
      'PurePower',
      'Adaptability',
      'InnerFocus',
    ]) {
      for (final category in Category.values) {
        for (final status in [null, ...Status.values]) {
          test('attack ability $a $category $status', () {
            final r = calculator.damage(
              a: calculator.pokemon(
                ability: a,
                status: status,
                item: category == Category.physical
                    ? 'ChoiceBand'
                    : 'ChoiceSpecs',
              ),
              m: calculator.move(category: category),
            );
            final physical = category == Category.physical;
            final expected = physical && ['HugePower', 'PurePower'].contains(a)
                ? 300
                : physical && a == 'Guts'
                ? 225
                : 150;
            expect(r.hits.single.attack, expected);
            expect(r.max, greaterThan(0));
          });
        }
      }
    }
  }
  {
    final cases = [
      (
        'SlowStart',
        50,
        effects.p(ability: 'SlowStart'),
        effects.p(),
        effects.m(),
        effects.f(),
      ),
      (
        'Defeatist',
        50,
        effects.p(ability: 'Defeatist', hp: 100),
        effects.p(),
        effects.m(),
        effects.f(),
      ),
      (
        'Transistor',
        130,
        effects.p(ability: 'Transistor'),
        effects.p(),
        effects.m(type: 'Electric'),
        effects.f(),
      ),
      (
        'HadronEngine',
        133,
        effects.p(ability: 'HadronEngine'),
        effects.p(),
        effects.m(category: Category.special),
        effects.f(terrain: Terrain.electric),
      ),
      (
        'OrichalcumPulse',
        133,
        effects.p(ability: 'OrichalcumPulse'),
        effects.p(),
        effects.m(),
        effects.f(weather: Weather.sunlight),
      ),
      (
        'FlowerGift',
        150,
        effects.p(ability: 'FlowerGift'),
        effects.p(),
        effects.m(),
        effects.f(weather: Weather.sunlight),
      ),
      (
        'Overgrow',
        150,
        effects.p(ability: 'Overgrow', hp: 66),
        effects.p(),
        effects.m(type: 'Grass'),
        effects.f(),
      ),
      (
        'Blaze',
        150,
        effects.p(ability: 'Blaze', hp: 66),
        effects.p(),
        effects.m(type: 'Fire'),
        effects.f(),
      ),
      (
        'Torrent',
        150,
        effects.p(ability: 'Torrent', hp: 66),
        effects.p(),
        effects.m(type: 'Water'),
        effects.f(),
      ),
      (
        'Swarm',
        150,
        effects.p(ability: 'Swarm', hp: 66),
        effects.p(),
        effects.m(type: 'Bug'),
        effects.f(),
      ),
      (
        'FlashFire',
        150,
        effects.p(ability: 'FlashFire'),
        effects.p(),
        effects.m(type: 'Fire'),
        effects.f(),
      ),
      (
        'SolarPower',
        150,
        effects.p(ability: 'SolarPower'),
        effects.p(),
        effects.m(category: Category.special),
        effects.f(weather: Weather.sunlight),
      ),
      (
        'Plus',
        150,
        effects.p(ability: 'Plus'),
        effects.p(),
        effects.m(category: Category.special),
        effects.f(),
      ),
      (
        'Minus',
        150,
        effects.p(ability: 'Minus'),
        effects.p(),
        effects.m(category: Category.special),
        effects.f(),
      ),
      (
        'RockyPayload',
        150,
        effects.p(ability: 'RockyPayload'),
        effects.p(),
        effects.m(type: 'Rock'),
        effects.f(),
      ),
      (
        'Steelworker',
        150,
        effects.p(ability: 'Steelworker'),
        effects.p(),
        effects.m(type: 'Steel'),
        effects.f(),
      ),
      (
        'FireMane',
        150,
        effects.p(ability: 'FireMane'),
        effects.p(),
        effects.m(type: 'Fire'),
        effects.f(),
      ),
      (
        'DragonsMaw',
        150,
        effects.p(ability: 'DragonsMaw'),
        effects.p(),
        effects.m(type: 'Dragon'),
        effects.f(),
      ),
      (
        'GorillaTactics',
        150,
        effects.p(ability: 'GorillaTactics'),
        effects.p(),
        effects.m(),
        effects.f(),
      ),
      (
        'WaterBubble',
        200,
        effects.p(ability: 'WaterBubble'),
        effects.p(),
        effects.m(type: 'Water'),
        effects.f(),
      ),
      (
        'Stakeout',
        200,
        effects.p(ability: 'Stakeout'),
        effects.p(),
        effects.m(),
        effects.f(),
      ),
      (
        'Hustle',
        150,
        effects.p(ability: 'Hustle'),
        effects.p(),
        effects.m(),
        effects.f(),
      ),
    ];

    for (final c in cases) {
      test('attack ability ${c.$1}', () {
        expect(
          effects.hit(a: c.$3, d: c.$4, move: c.$5, field: c.$6).attack,
          c.$2,
        );
        final suppressed = PokemonPatch(
          flags: {PokemonFlag.abilitySuppressed: true},
        ).apply(c.$3);
        expect(
          effects.hit(a: suppressed, d: c.$4, move: c.$5, field: c.$6).attack,
          100,
        );
      });
    }

    for (final c in [
      ('ThickFat', 'Ice'),
      ('Heatproof', 'Fire'),
      ('WaterBubble', 'Fire'),
      ('PurifyingSalt', 'Ghost'),
    ]) {
      test('defender attack reduction $c', () {
        expect(
          effects
              .hit(
                d: effects.p(ability: c.$1),
                move: effects.m(type: c.$2),
              )
              .attack,
          50,
        );
        expect(
          effects
              .hit(
                a: effects.p(ability: 'MoldBreaker'),
                d: effects.p(ability: c.$1),
                move: effects.m(type: c.$2),
              )
              .attack,
          100,
        );
      });
    }

    for (final c in [
      ('Cubone', 'ThickClub', Category.physical),
      ('Marowak-Alola', 'ThickClub', Category.physical),
      ('Clamperl', 'DeepSeaTooth', Category.special),
      ('Pikachu', 'LightBall', Category.special),
    ]) {
      test('species attack item $c', () {
        expect(
          effects
              .hit(
                a: effects.p(id: c.$1, item: c.$2),
                move: effects.m(category: c.$3),
              )
              .attack,
          200,
        );
        expect(
          effects
              .hit(
                a: effects.p(item: c.$2),
                move: effects.m(category: c.$3),
              )
              .attack,
          100,
        );
      });
    }

    for (final c in [
      ('VesselofRuin', Category.special, FieldEffect.vesselOfRuin),
      ('TabletsofRuin', Category.physical, FieldEffect.tabletsOfRuin),
    ]) {
      test('ruin attack $c', () {
        expect(
          effects
              .hit(
                d: effects.p(ability: c.$1),
                move: effects.m(category: c.$2),
              )
              .attack,
          75,
        );
        expect(
          effects
              .hit(
                a: effects.p(ability: c.$1),
                d: effects.p(ability: c.$1),
                move: effects.m(category: c.$2),
              )
              .attack,
          100,
        );
        expect(
          effects
              .hit(
                move: effects.m(category: c.$2),
                field: effects.f(effects: {c.$3}),
              )
              .attack,
          75,
        );
      });
    }
  }
}
