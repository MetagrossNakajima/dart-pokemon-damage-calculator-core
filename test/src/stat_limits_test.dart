import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../support/value_objects_fixtures.dart' show valid;
import '../support/domain_models_fixtures.dart' as domain;
import '../support/effects_fixtures.dart' as effects;

void main() {
  final nonHpStats = Stat.values.where((stat) => stat != Stat.hp);

  test('stats accept1 and999 for every input stat', () {
    for (final value in [1, 999]) {
      final stats = valid(
        Stats.fromDto(
          StatsDto.fromMap({for (final stat in Stat.values) stat: value}),
        ),
      );
      for (final stat in Stat.values) {
        expect(stats[stat].value, value);
      }
    }
  });

  test('stats above999 report their exact validation paths', () {
    for (final stat in nonHpStats) {
      for (final value in [1000, 32768, 65536, 9223372036854775807]) {
        final validation = Stats.fromDto(
          StatsDto.fromMap({...domain.stats, stat: value}),
        );
        expect(validation, isA<Invalid<Stats>>());
        expect((validation as Invalid<Stats>).errors, [
          ValidationError('stats.${stat.name}', ValidationCode.outOfRange),
        ]);
      }
    }
  });

  test('single-hit requests reject oversized stats before division', () {
    for (final stat in nonHpStats) {
      for (final value in [1000, 32768, 65536]) {
        final invalid = effects.p(stats: {stat: value});
        for (final attacker in [false, true]) {
          final validation = DamageRequest.fromDto(
            DamageRequestDto(
              attacker: attacker ? invalid : effects.p(),
              defender: attacker ? effects.p() : invalid,
              move: effects.m(id: 'Pound'),
              field: effects.f(),
            ),
          );
          final side = attacker ? 'attacker' : 'defender';
          expect(validation, isA<Invalid<DamageRequest>>());
          expect((validation as Invalid<DamageRequest>).errors, [
            ValidationError(
              'damageRequest.$side.stats.${stat.name}',
              ValidationCode.outOfRange,
            ),
          ]);
        }
      }
    }
  });

  test('combined requests reject oversized defender stats', () {
    for (final stat in nonHpStats) {
      for (final value in [1000, 32768, 65536]) {
        final validation = CombinedDamageRequest.fromDto(
          CombinedDamageRequestDto.repeatSingleHit(
            firstHit: DamageDistribution({0: BigInt.one}),
            defender: effects.p(stats: {stat: value}),
            field: effects.f(),
            setup: BattleSetupDto.none,
          ),
        );
        expect(validation, isA<Invalid<CombinedDamageRequest>>());
        expect((validation as Invalid<CombinedDamageRequest>).errors, [
          ValidationError(
            'combinedDamageRequest.defender.stats.${stat.name}',
            ValidationCode.outOfRange,
          ),
        ]);
      }
    }
  });

  test('999 defense supports rank6 Fur Coat Eviolite and snow', () {
    final hit = effects.hit(
      d: effects.p(
        stats: {Stat.def: 999},
        ranks: {Stat.def: 6},
        types: ['Ice'],
        ability: 'FurCoat',
        item: 'Eviolite',
        flags: {PokemonFlag.canEvolve: true},
      ),
      move: effects.m(id: 'Pound'),
      field: effects.f(weather: Weather.snow),
    );
    expect(hit.defense, 17982);
    expect(hit.rolls, [...List.filled(15, 1), 3]);
  });

  test('999 special defense supports rank6 Quark Drive scale and sand', () {
    final hit = effects.hit(
      d: effects.p(
        id: 'Clamperl',
        stats: {Stat.spd: 999},
        ranks: {Stat.spd: 6},
        types: ['Rock'],
        ability: 'QuarkDrive',
        item: 'DeepSeaScale',
        boosted: Stat.spd,
      ),
      move: effects.m(id: 'Swift', category: Category.special),
      field: effects.f(weather: Weather.sandstorm, terrain: Terrain.electric),
    );
    expect(hit.defense, 15582);
    expect(hit.rolls, List.filled(16, 1));
  });

  test('defense1 stays calculable after rank-6 and ruin modifiers', () {
    for (final physical in [false, true]) {
      final hit = effects.hit(
        a: effects.p(ability: physical ? 'SwordOfRuin' : 'BeadsOfRuin'),
        d: effects.p(
          stats: {Stat.def: 1, Stat.spd: 1},
          ranks: {Stat.def: -6, Stat.spd: -6},
        ),
        move: effects.m(
          id: physical ? 'Pound' : 'Swift',
          category: physical ? Category.physical : Category.special,
        ),
      );
      expect(hit.defense, 1);
      expect(hit.rolls.first, 2245);
      expect(hit.rolls.last, 2643);
    }
  });
}
