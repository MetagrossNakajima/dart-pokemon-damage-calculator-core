import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../support/input_adapter.dart' as adapter;
import '../support/calculator_fixtures.dart' as calculator;
import '../support/effects_fixtures.dart' as effects;
import '../support/pokemon_patch.dart';

String _id(String value) => value.replaceAll(RegExp('[^a-zA-Z0-9]'), '');

PokemonStateDto _pokemon(Map<String, dynamic> p, Map<String, dynamic> side) {
  final stats = (p['stats'] as Map<String, dynamic>?) ?? {};
  final ranks = (p['ranks'] as Map<String, dynamic>?) ?? {};
  return PokemonStateDto(
    profile: PokemonProfileDto(
      id: adapter.pokemonId(p['id'] as String? ?? 'Mew'),
      types: ((p['types'] as List?) ?? ['Normal'])
          .cast<String>()
          .map(adapter.pokemonType)
          .toList(),
      weight: 50,
    ),
    stats: StatsDto.fromMap({
      for (final stat in Stat.values)
        stat: (stats[stat.name] as int?) ?? (stat == Stat.hp ? 200 : 100),
    }),
    stages: StatStagesDto.fromMap({
      for (final stat in Stat.values) stat: (ranks[stat.name] as int?) ?? 0,
    }),
    ability: adapter.abilityId(
      p['ability'] == null ? null : _id(p['ability'] as String),
    ),
    item: adapter.itemId(p['item'] == null ? null : _id(p['item'] as String)),
    status: p['status'] == 'brn' ? Status.burn : null,
    currentHp: p['hp'] as int?,
    teraType: adapter.teraType(p['tera'] as String?),
    flags: {
      PokemonFlag.charge: p['charge'] == true || side['isCharge'] == true,
    },
    sideConditions: SideConditions(
      reflect: side['isReflect'] == true,
      lightScreen: side['isLightScreen'] == true,
    ),
  );
}

void main() {
  test('collision boosts use chart effectiveness before Tera Shell', () {
    for (final id in ['CollisionCourse', 'ElectroDrift']) {
      final hit = effects.hit(
        move: effects.m(id: id, type: 'Fire', power: 100),
        d: effects.p(ability: 'TeraShell', types: ['Grass']),
      );
      expect(hit.power, 133);
      expect(
        hit.trace.where(
          (t) => t.id == id && t.stage == ModifierStage.damageModifier,
        ),
        isEmpty,
      );
      expect(hit.trace.firstWhere((t) => t.id == 'Type').numerator, 0.5);
    }
  });

  test(
    'ally Steely Spirit affects attack independently of the user ability',
    () {
      for (final category in [Category.physical, Category.special]) {
        final hit = effects.hit(
          a: effects.p(ability: 'SteelySpirit'),
          move: effects.m(type: 'Steel', category: category),
          field: effects.f(effects: {FieldEffect.steelySpirit}),
        );
        expect(hit.power, 60);
        expect(hit.attack, 150);
        expect(
          hit.trace.firstWhere((t) => t.id == 'AllySteelySpirit').stage,
          ModifierStage.attackModifier,
        );
      }
    },
  );

  test('Infiltrator bypasses both screens only while active', () {
    for (final category in [Category.physical, Category.special]) {
      final defender = PokemonPatch(
        reflect: true,
        lightScreen: true,
      ).apply(effects.p());
      for (final suppressed in [false, true]) {
        final result = calculator.damage(
          a: effects.p(
            ability: 'Infiltrator',
            flags: {PokemonFlag.abilitySuppressed: suppressed},
          ),
          d: defender,
          m: effects.m(category: category),
        );
        final ordinary = calculator.damage(m: effects.m(category: category));
        if (suppressed) {
          expect(result.max, lessThan(ordinary.max));
          expect(
            result.hits.single.trace.where((t) => t.id == 'Screen'),
            isNotEmpty,
          );
        } else {
          expect(result.distribution.weights, ordinary.distribution.weights);
          expect(
            result.hits.single.trace.where((t) => t.id == 'Screen'),
            isEmpty,
          );
        }
      }
    }
  });

  test(
    'selected Tera Shell requires an effective ability and preserves immunity',
    () {
      final move = effects.m(type: 'Fire');
      for (final defender in [
        effects.p(
          ability: 'TeraShell',
          flags: {PokemonFlag.abilitySuppressed: true},
        ),
      ]) {
        expect(
          calculator.damage(d: defender, m: move).distribution.weights,
          calculator.damage(m: move).distribution.weights,
        );
      }
      expect(
        calculator
            .damage(
              a: effects.p(ability: 'MoldBreaker'),
              d: effects.p(ability: 'TeraShell'),
              m: move,
            )
            .distribution
            .weights,
        calculator.damage(m: move).distribution.weights,
      );
      expect(
        calculator
            .damage(
              d: effects.p(ability: 'TeraShell', types: ['Ghost']),
            )
            .max,
        0,
      );
      final shielded = effects.hit(
        a: effects.p(ability: 'MoldBreaker'),
        d: effects.p(ability: 'TeraShell', item: 'AbilityShield'),
        move: move,
      );
      expect(shielded.trace.firstWhere((t) => t.id == 'Type').numerator, 0.5);
    },
  );

  test('Brine doubles exactly at half HP including odd maximum HP', () {
    for (final maxHp in [200, 201]) {
      for (final hp in [maxHp ~/ 2 - 1, maxHp ~/ 2, maxHp ~/ 2 + 1]) {
        final defender = PokemonPatch(
          stats: {Stat.hp: maxHp},
          currentHp: Replacement(hp),
        ).apply(effects.p());
        final hit = effects.hit(
          d: defender,
          move: effects.m(id: 'Brine', power: 65),
        );
        expect(hit.power, hp <= maxHp ~/ 2 ? 130 : 65);
      }
    }
  });

  test(
    'Stored Power and Power Trip sum positive ranks and ignore negative ranks',
    () {
      for (final id in ['StoredPower', 'PowerTrip']) {
        final move = effects.m(id: id, power: 1);
        expect(effects.hit(move: move).power, 20);
        expect(
          effects
              .hit(
                a: effects.p(
                  ranks: {
                    Stat.atk: 2,
                    Stat.def: -6,
                    Stat.spa: 3,
                    Stat.spd: 1,
                    Stat.spe: 4,
                  },
                ),
                move: move,
              )
              .power,
          220,
        );
        expect(
          effects
              .hit(
                a: effects.p(ranks: {Stat.spa: -1}),
                move: move,
              )
              .power,
          20,
        );
      }
    },
  );

  test('Knock Off distinguishes held, consumed, and unremovable items', () {
    final move = effects.m(id: 'KnockOff', power: 65);
    final held = effects.p(ability: 'Klutz', item: 'Leftovers');
    expect(effects.hit(d: held, move: move).power, 97);
    expect(
      effects
          .hit(d: PokemonPatch(itemConsumed: true).apply(held), move: move)
          .power,
      65,
    );
    expect(
      effects
          .hit(
            d: effects.p(
              item: 'Leftovers',
              flags: {PokemonFlag.itemRemovable: false},
            ),
            move: move,
          )
          .power,
      65,
    );
    expect(
      effects
          .hit(
            d: held,
            move: move,
            field: effects.f(effects: {FieldEffect.magicRoom}),
          )
          .power,
      97,
    );
  });

  test(
    'Photon Geyser and Stellar Starstorm compare ranked stats and keep ties special',
    () {
      for (final id in ['PhotonGeyser', 'TeraStarstorm']) {
        final move = effects.m(id: id, category: Category.physical);
        final attacker = effects.p(id: 'Terapagos-Stellar', tera: 'Stellar');
        final defender = effects.p(stats: {Stat.def: 80, Stat.spd: 140});
        expect(effects.hit(a: attacker, d: defender, move: move).defense, 140);
        expect(
          effects
              .hit(
                a: PokemonPatch(ranks: {Stat.atk: 1}).apply(attacker),
                d: defender,
                move: move,
              )
              .defense,
          80,
        );
      }
      final normalized = effects.hit(
        a: effects.p(ability: 'Normalize', stats: {Stat.atk: 200}),
        d: effects.p(types: ['Ghost']),
        move: effects.m(
          id: 'PhotonGeyser',
          type: 'Psychic',
          category: Category.special,
        ),
      );
      expect(normalized.attack, 200);
      expect(normalized.rolls, List.filled(16, 0));
    },
  );

  test('As One suppresses berries only while its ability is active', () {
    for (final ability in ['AsOneGlastrier', 'AsOneSpectrier']) {
      for (final suppressed in [false, true]) {
        final hit = effects.hit(
          a: effects.p(
            ability: ability,
            flags: {PokemonFlag.abilitySuppressed: suppressed},
          ),
          d: effects.p(item: 'OccaBerry', types: ['Grass']),
          move: effects.m(type: 'Fire'),
        );
        expect(
          hit.trace.where((t) => t.id == 'OccaBerry').isNotEmpty,
          suppressed,
        );
      }
    }
  });

  test(
    'Flying Ground overrides keep other matchups after independent grounding',
    () {
      for (final id in ['Earthquake', 'ThousandArrows']) {
        final move = effects.m(id: id, type: 'Ground');
        final defender = effects.p(types: ['Flying', 'Fire'], item: 'IronBall');
        double effectiveness(PokemonStateDto d, {BattleFieldDto? f}) => effects
            .hit(d: d, move: move, field: f)
            .trace
            .firstWhere((t) => t.id == 'Type')
            .numerator
            .toDouble();
        expect(effectiveness(defender), 1);
        expect(effectiveness(defender, f: effects.f(gravity: true)), 2);
        expect(
          effectiveness(
            PokemonPatch(flags: {PokemonFlag.grounded: true}).apply(defender),
          ),
          2,
        );
        expect(
          effectiveness(
            effects.p(types: ['Flying', 'Fire'], item: 'RingTarget'),
          ),
          2,
        );
        expect(
          effectiveness(
            effects.p(
              types: ['Flying', 'Fire'],
              ability: 'Klutz',
              item: 'IronBall',
            ),
          ),
          id == 'ThousandArrows' ? 1 : 0,
        );
      }
      final nonFlying = effects.hit(
        d: effects.p(ability: 'Levitate', types: ['Fire']),
        move: effects.m(id: 'ThousandArrows', type: 'Ground'),
      );
      expect(nonFlying.trace.firstWhere((t) => t.id == 'Type').numerator, 2);
    },
  );

  test(
    'Raging Bull Normalize overrides forms but does not act when suppressed',
    () {
      for (final id in [
        'Tauros-Paldea-Blaze',
        'Tauros-Paldea-Aqua',
        'Tauros-Paldea-Combat',
      ]) {
        final move = effects.m(id: 'RagingBull');
        final hit = effects.hit(
          a: effects.p(id: id, ability: 'Normalize'),
          move: move,
        );
        expect(hit.power, 48);
        expect(
          hit.rolls,
          calculator.damage(m: effects.m(power: 48)).hits.single.rolls,
        );
      }
      final hit = effects.hit(
        a: effects.p(
          id: 'Tauros-Paldea-Blaze',
          ability: 'Normalize',
          flags: {PokemonFlag.abilitySuppressed: true},
        ),
        d: effects.p(types: ['Grass']),
        move: effects.m(id: 'RagingBull'),
      );
      expect(hit.rolls.last, 38);
    },
  );

  test('Mold Breaker removes Aura Break unless Ability Shield protects it', () {
    for (final item in [null, 'AbilityShield']) {
      final hit = effects.hit(
        a: effects.p(ability: 'MoldBreaker'),
        d: effects.p(ability: 'AuraBreak', item: item),
        move: effects.m(type: 'Fairy'),
        field: effects.f(effects: {FieldEffect.fairyAura}),
      );
      expect(hit.power, item == null ? 53 : 30);
    }
  });

  final cases =
      (jsonDecode(
                File('test/fixtures/issue_regressions.json').readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  for (final c in cases) {
    test(
      'issue #${c['issue']} case ${c['case']} matches every Smogon roll',
      () {
        final f = c['field'] as Map<String, dynamic>;
        final attackerSide = (f['attackerSide'] as Map<String, dynamic>?) ?? {};
        final defenderSide = (f['defenderSide'] as Map<String, dynamic>?) ?? {};
        final m = c['move'] as Map<String, dynamic>;
        final result = calculator.damage(
          crit: m['crit'] == true,
          a: _pokemon(c['attacker'] as Map<String, dynamic>, attackerSide),
          d: _pokemon(c['defender'] as Map<String, dynamic>, defenderSide),
          m: MoveDto(
            id: adapter.moveId(_id(m['id'] as String)),
            power: m['power'] as int,
            type: adapter.pokemonType(m['type'] as String),
            category: m['category'] == 'Physical'
                ? Category.physical
                : Category.special,
            flags: ((m['flags'] as List?) ?? [])
                .cast<String>()
                .map((name) => MoveFlag.values.byName(name))
                .toSet(),
          ),
          f: BattleFieldDto(
            format: BattleFormat.single,
            weather: f['weather'] == 'Sun' ? Weather.sunlight : null,
            terrain: switch (f['terrain']) {
              'Electric' => Terrain.electric,
              'Grassy' => Terrain.grass,
              'Psychic' => Terrain.psychic,
              'Misty' => Terrain.misty,
              _ => null,
            },
            effects: {
              if (attackerSide['isHelpingHand'] == true)
                FieldEffect.helpingHand,
              if (attackerSide['isPowerSpot'] == true) FieldEffect.powerSpot,
              if (attackerSide['isSteelySpirit'] == true)
                FieldEffect.steelySpirit,
              if (f['isFairyAura'] == true) FieldEffect.fairyAura,
            },
          ),
        );
        expect(result.hits.single.rolls, (c['rolls'] as List).cast<int>());
      },
    );
  }
}
