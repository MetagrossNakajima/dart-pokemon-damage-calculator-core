import 'dart:convert';
import 'dart:io';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../support/effects_fixtures.dart' as effects;
import '../support/pokemon_patch.dart';
import '../support/value_objects_fixtures.dart' show valid;

HitResult hit({
  PokemonStateDto? attacker,
  PokemonStateDto? defender,
  MoveDto? move,
  BattleFieldDto? field,
  int hitIndex = 0,
}) =>
    (calculateDamage(
              valid(
                DamageRequest.fromDto(
                  DamageRequestDto(
                    attacker: attacker ?? effects.p(),
                    defender: defender ?? effects.p(),
                    move: move ?? effects.m(),
                    field: field ?? effects.f(),
                    hitIndex: hitIndex,
                  ),
                ),
              ),
            )
            as Success<DamageResult>)
        .value
        .hits
        .single;

PokemonStateDto fixturePokemon(Map<String, dynamic> p) => effects.p(
  ability: (p['ability'] as String?)?.replaceAll(' ', ''),
  item: (p['item'] as String?)?.replaceAll(' ', ''),
  hp: p['hp'] as int?,
  boosted: p['boostedStat'] == null
      ? null
      : Stat.values.byName(p['boostedStat'] as String),
  stats: {
    Stat.atk: 101,
    Stat.def: 103,
    Stat.spa: 101,
    Stat.spd: 103,
    for (final entry in (p['stats'] as Map<String, dynamic>? ?? {}).entries)
      Stat.values.byName(entry.key): entry.value as int,
  },
);

void main() {
  final fixtures =
      jsonDecode(
            File('test/fixtures/ability_activation.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  for (final c in (fixtures['cases'] as List).cast<Map<String, dynamic>>()) {
    test('activated Smogon rolls ${c['id']}', () {
      final result = hit(
        attacker: fixturePokemon(c['attacker'] as Map<String, dynamic>),
        defender: fixturePokemon(c['defender'] as Map<String, dynamic>),
        move: effects.m(
          id: 'Pound',
          type: c['type'] as String,
          power: c['power'] as int,
          category: c['category'] == 'Physical'
              ? Category.physical
              : Category.special,
        ),
      );
      expect(result.rolls, c['rolls']);
    });
  }

  for (final c in [
    ('Overgrow', 'Grass', Category.physical, 40, 150),
    ('Blaze', 'Fire', Category.physical, 40, 150),
    ('Torrent', 'Water', Category.special, 40, 150),
    ('Swarm', 'Bug', Category.physical, 40, 150),
    ('Defeatist', 'Normal', Category.physical, 40, 50),
    ('Defeatist', 'Normal', Category.special, 40, 50),
    ('Stakeout', 'Normal', Category.physical, 40, 200),
    ('Guts', 'Normal', Category.physical, 40, 150),
    ('FlareBoost', 'Normal', Category.special, 60, 100),
    ('ToxicBoost', 'Normal', Category.physical, 60, 100),
    ('SolarPower', 'Normal', Category.special, 40, 150),
    ('FlowerGift', 'Normal', Category.physical, 40, 150),
    ('SandForce', 'Ground', Category.physical, 52, 100),
    ('SandForce', 'Rock', Category.physical, 52, 100),
    ('SandForce', 'Steel', Category.physical, 52, 100),
    ('HadronEngine', 'Normal', Category.special, 40, 133),
    ('OrichalcumPulse', 'Normal', Category.physical, 40, 133),
    ('Analytic', 'Normal', Category.physical, 52, 100),
    ('FlashFire', 'Fire', Category.special, 40, 150),
    ('Plus', 'Normal', Category.special, 40, 150),
    ('Minus', 'Normal', Category.special, 40, 150),
    ('SlowStart', 'Normal', Category.physical, 40, 50),
    ('Protosynthesis', 'Normal', Category.physical, 40, 130),
    ('QuarkDrive', 'Normal', Category.physical, 40, 130),
  ]) {
    test(
      'selected ${c.$1} ${c.$2} ${c.$3.name} activates without prerequisites',
      () {
        final attacker = effects.p(
          ability: c.$1,
          item: c.$1 == 'OrichalcumPulse' ? 'UtilityUmbrella' : null,
          flags: {PokemonFlag.movesFirst: true},
        );
        final move = effects.m(type: c.$2, category: c.$3);
        final result = hit(attacker: attacker, move: move);
        expect(result.power, c.$4);
        expect(result.attack, c.$5);
        final off = hit(
          attacker: PokemonPatch(
            ability: const Replacement(null),
          ).apply(attacker),
          move: move,
        );
        expect(off.power, 40);
        expect(off.attack, 100);
        for (final suppressed in [true, false]) {
          final inactive = hit(
            attacker: PokemonPatch(
              flags: {PokemonFlag.abilitySuppressed: suppressed},
            ).apply(attacker),
            defender: effects.p(ability: suppressed ? null : 'NeutralizingGas'),
            move: move,
          );
          expect(inactive.rolls, off.rolls);
        }
        expect(attacker.currentHp, isNull);
        expect(attacker.status, isNull);
      },
    );
  }

  for (final c in [
    ('FlowerGift', Category.special),
    ('MarvelScale', Category.physical),
    ('GrassPelt', Category.physical),
    ('Protosynthesis', Category.physical),
    ('QuarkDrive', Category.special),
  ]) {
    test('selected defensive ${c.$1} activates without prerequisites', () {
      final defender = effects.p(
        ability: c.$1,
        hp: 1,
        boosted: c.$2 == Category.physical ? Stat.def : Stat.spd,
      );
      final move = effects.m(category: c.$2);
      expect(
        hit(defender: defender, move: move).defense,
        ['Protosynthesis', 'QuarkDrive'].contains(c.$1) ? 130 : 150,
      );
      final off = hit(move: move);
      for (final attacker in ['MoldBreaker', 'NeutralizingGas']) {
        expect(
          hit(
            attacker: effects.p(ability: attacker),
            defender: defender,
            move: move,
          ).rolls,
          attacker == 'MoldBreaker' &&
                  ['Protosynthesis', 'QuarkDrive'].contains(c.$1)
              ? hit(defender: defender, move: move).rolls
              : off.rolls,
        );
      }
      expect(
        hit(
          defender: PokemonPatch(
            flags: {PokemonFlag.abilitySuppressed: true},
          ).apply(defender),
          move: move,
        ).rolls,
        off.rolls,
      );
    });
  }

  for (final c in [
    ('Blaze', 'Water', Category.physical),
    ('Overgrow', 'Fire', Category.special),
    ('Torrent', 'Grass', Category.physical),
    ('Swarm', 'Normal', Category.physical),
    ('FlashFire', 'Water', Category.special),
    ('SandForce', 'Fire', Category.physical),
    ('FlareBoost', 'Normal', Category.physical),
    ('ToxicBoost', 'Normal', Category.special),
    ('Guts', 'Normal', Category.special),
    ('SolarPower', 'Normal', Category.physical),
    ('FlowerGift', 'Normal', Category.special),
    ('Plus', 'Normal', Category.physical),
    ('Minus', 'Normal', Category.physical),
    ('SlowStart', 'Normal', Category.special),
    ('HadronEngine', 'Normal', Category.physical),
    ('OrichalcumPulse', 'Normal', Category.special),
  ]) {
    test('selected ${c.$1} keeps ${c.$2} ${c.$3.name} applicability', () {
      final move = effects.m(type: c.$2, category: c.$3);
      expect(
        hit(
          attacker: effects.p(ability: c.$1),
          move: move,
        ).rolls,
        hit(move: move).rolls,
      );
    });
  }
  for (final c in [
    ('FlowerGift', Category.physical),
    ('MarvelScale', Category.special),
    ('GrassPelt', Category.special),
  ]) {
    test('selected defensive ${c.$1} keeps category applicability', () {
      final move = effects.m(category: c.$2);
      expect(
        hit(
          defender: effects.p(ability: c.$1),
          move: move,
        ).rolls,
        hit(move: move).rolls,
      );
    });
  }

  for (final ability in ['Multiscale', 'ShadowShield']) {
    test('selected $ability ignores HP and keeps first-hit limit', () {
      final defender = effects.p(ability: ability, hp: 1);
      expect(hit(defender: defender).rolls, [
        12,
        12,
        12,
        12,
        12,
        12,
        12,
        12,
        12,
        12,
        13,
        13,
        13,
        13,
        13,
        14,
      ]);
      expect(
        hit(defender: defender, hitIndex: 1).rolls,
        hit(hitIndex: 1).rolls,
      );
    });
  }
  test(
    'selected Tera Shell ignores HP and preserves immunity on every hit',
    () {
      for (final index in [0, 1]) {
        final result = hit(
          defender: effects.p(ability: 'TeraShell', hp: 1),
          hitIndex: index,
        );
        expect(result.rolls, [
          12,
          12,
          12,
          12,
          12,
          12,
          12,
          12,
          12,
          12,
          13,
          13,
          13,
          13,
          13,
          14,
        ]);
        expect(
          hit(
            defender: effects.p(ability: 'TeraShell', hp: 1, types: ['Ghost']),
            hitIndex: index,
          ).rolls,
          List.filled(16, 0),
        );
      }
    },
  );

  test(
    'activation preserves HP weather status and move order for other effects',
    () {
      expect(
        hit(
          attacker: effects.p(ability: 'Blaze', hp: 100),
          move: effects.m(id: 'Eruption', type: 'Fire', power: 150),
        ).power,
        75,
      );
      expect(
        hit(
          attacker: effects.p(ability: 'SolarPower'),
          move: effects.m(
            id: 'WeatherBall',
            power: 50,
            category: Category.special,
          ),
        ).power,
        50,
      );
      expect(
        hit(
          attacker: effects.p(ability: 'Guts'),
          move: effects.m(id: 'Facade'),
        ).power,
        40,
      );
      expect(
        hit(
          attacker: effects.p(ability: 'Guts', status: Status.burn),
          move: effects.m(),
        ).rolls,
        hit(
          attacker: effects.p(ability: 'Guts'),
          move: effects.m(),
        ).rolls,
      );
      for (final first in [true, false]) {
        expect(
          hit(
            attacker: effects.p(
              ability: 'Analytic',
              flags: {PokemonFlag.movesFirst: first},
            ),
            move: effects.m(id: 'BoltBeak', type: 'Electric'),
          ).power,
          first ? 104 : 52,
        );
      }
    },
  );

  test('activation never synthesizes weather terrain or status modifiers', () {
    for (final c in [
      ('SolarPower', 'Fire', Category.special),
      ('OrichalcumPulse', 'Fire', Category.physical),
      ('HadronEngine', 'Electric', Category.special),
      ('GrassPelt', 'Grass', Category.physical),
    ]) {
      final result = hit(
        attacker: effects.p(ability: c.$1),
        defender: effects.p(ability: c.$1 == 'GrassPelt' ? c.$1 : null),
        move: effects.m(type: c.$2, category: c.$3),
      );
      expect(result.power, 40);
      expect(
        result.trace.where((t) => t.id == 'Weather' || t.id == 'Terrain'),
        isEmpty,
      );
    }
    for (final status in [null, Status.burn]) {
      final result = hit(
        attacker: effects.p(ability: 'ToxicBoost', status: status),
      );
      expect(result.power, 60);
      expect(result.trace.any((t) => t.id == 'Burn'), status == Status.burn);
    }
  });

  test('ally Flower Gift assumes activation without sunlight', () {
    expect(
      hit(field: effects.f(effects: {FieldEffect.attackerFlowerGift})).attack,
      150,
    );
    expect(
      hit(
        move: effects.m(category: Category.special),
        field: effects.f(effects: {FieldEffect.defenderFlowerGift}),
      ).defense,
      150,
    );
  });
  test(
    'client-selected shield distributions remain fixed after first attack misses',
    () {
      final firstRolls = hit(
        defender: effects.p(ability: 'Multiscale', hp: 100),
      ).rolls;
      final laterRolls = hit().rolls;
      DamageDistribution distribution(List<int> rolls) {
        final weights = <int, BigInt>{};
        for (final damage in rolls) {
          weights[damage] = (weights[damage] ?? BigInt.zero) + BigInt.one;
        }
        return DamageDistribution(weights);
      }

      final first = distribution(firstRolls);
      final later = distribution(laterRolls);
      final expected = <BigInt, BigInt>{};
      for (final next in later.weights.entries) {
        final missed = BigInt.from(next.key);
        expected[missed] =
            (expected[missed] ?? BigInt.zero) + first.totalWeight * next.value;
        for (final initial in first.weights.entries) {
          final total = BigInt.from(initial.key + next.key);
          expected[total] =
              (expected[total] ?? BigInt.zero) + initial.value * next.value;
        }
      }
      for (final ability in [null, AbilityId.multiscale]) {
        final input = CombinedDamageRequestDto(
          attacks: [
            AttackDto.fromAccuracy(turn: 1, hits: [first], accuracyPercent: 50),
            AttackDto.fromAccuracy(turn: 2, hits: [later]),
          ],
          defender: PokemonPatch(
            ability: Replacement(ability),
          ).apply(effects.p(hp: 100)),
          field: effects.f(),
          setup: BattleSetupDto.none,
        );
        final result =
            (calculateCombinedDamage(
                      valid(CombinedDamageRequest.fromDto(input)),
                    )
                    as Success<CombinedDamageResult>)
                .value;
        expect(result.attackDamage.weights, expected);
        expect(result.finalHp.weights, {
          for (final e in expected.entries) 100 - e.key.toInt(): e.value,
        });
      }
    },
  );
}
