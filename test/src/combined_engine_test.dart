import 'package:test/test.dart';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../support/fixed_combined_fixtures.dart' as combined;

import '../support/combined_prefix_fixtures.dart' as prefix_oracle;

import '../support/effect_regressions_fixtures.dart' as regressions;

CombinedDamageRequestDto repeated(
  Map<int, int> first, {
  Map<int, int>? subsequent,
  Map<int, BigInt>? hitCounts,
  PokemonStateDto? defender,
  BattleSetupDto? setup,
  CalculationLimitsDto limits = const CalculationLimitsDto(),
}) => CombinedDamageRequestDto.repeatSingleHit(
  firstHit: combined.distribution(first),
  subsequentHit: subsequent == null ? null : combined.distribution(subsequent),
  hitCounts: hitCounts,
  defender: defender ?? combined.defender(),
  field: BattleFieldDto(format: BattleFormat.single),
  setup: setup ?? BattleSetupDto.none,
  limits: limits,
);

void main() {
  test('combined damage stays BigInt beyond the signed 64-bit limit', () {
    const maxHp = 999;
    const firstDamage = 100;
    const secondDamage = 9223372036854775807;
    final result = combined.run(
      combined.request([
        combined.attack(
          [
            combined.distribution({firstDamage: 2}),
            combined.distribution({secondDamage: 3}),
            combined.distribution({100: 5}),
          ],
          counts: {1: 7, 2: 11, 3: 13},
          conditional: {3: 1},
        ),
      ], pokemon: combined.defender(hp: maxHp)),
    );
    final sum = BigInt.parse('9223372036854775907');
    expect(result.attackDamage.weights, {
      BigInt.from(firstDamage): BigInt.from(210),
      sum: BigInt.from(720),
    });
    expect(result.min, BigInt.from(firstDamage));
    expect(result.max, sum);
    expect(result.attackDamage.totalWeight, BigInt.from(930));
    expect(result.finalHp.weights, {
      maxHp - firstDamage: BigInt.from(210),
      0: BigInt.from(720),
    });
    expect(result.knockout.weight, BigInt.from(720));
    expect(result.knockout.totalWeight, BigInt.from(930));
    expect(result.ko.guaranteedHits, 1);
  });

  test('Sitrus handles maximum HP999 and caps berry healing', () {
    const maxHp = 999;
    final full = combined.run(
      combined.request(
        [
          combined.attack([
            combined.distribution({1: 1}),
          ]),
        ],
        pokemon: combined.defender(
          hp: maxHp,
          currentHp: maxHp,
          item: ItemId.sitrusBerry,
        ),
      ),
    );
    expect(full.finalHp.weights, {maxHp - 1: BigInt.one});
    expect(full.finalStates.single.state.itemConsumed, isFalse);

    final threshold = combined.run(
      combined.request(
        [
          combined.attack([
            combined.distribution({1: 1}),
          ]),
        ],
        pokemon: combined.defender(
          hp: maxHp,
          currentHp: maxHp ~/ 2 + 1,
          item: ItemId.sitrusBerry,
        ),
      ),
    );
    expect(threshold.finalHp.weights, {maxHp ~/ 2 + maxHp ~/ 4: BigInt.one});
    expect(threshold.finalStates.single.state.itemConsumed, isTrue);

    final repeat = combined.run(
      combined.request(
        [
          combined.attack([
            combined.distribution({1: 1}),
          ]),
        ],
        pokemon: combined.defender(
          hp: maxHp,
          currentHp: maxHp,
          item: ItemId.sitrusBerry,
          itemConsumed: true,
          ability: AbilityId.cudChew,
          cudChewTurn: 1,
        ),
      ),
    );
    expect(repeat.finalHp.weights, {maxHp: BigInt.one});
    expect(repeat.finalStates.single.state.cudChewTurn, isNull);

    final cheekPouch = combined.run(
      combined.request(
        [
          combined.attack([
            combined.distribution({1: 1}),
          ]),
        ],
        pokemon: combined.defender(
          hp: maxHp,
          currentHp: maxHp ~/ 2 + 1,
          item: ItemId.sitrusBerry,
          ability: AbilityId.cheekPouch,
        ),
      ),
    );
    expect(cheekPouch.finalHp.weights, {maxHp: BigInt.one});
  });

  test(
    '256 weighted attacks retain a finite guaranteed knockout probability',
    () {
      final result = combined.run(
        combined.request([
          for (var turn = 1; turn <= 256; turn++)
            combined.attack([
              combined.distribution({1: 16}),
            ], turn: turn),
        ]),
      );
      final weight = BigInt.one << 1024;
      expect(result.knockout.weight, weight);
      expect(result.knockout.totalWeight, weight);
      expect(result.knockout.guaranteed, isTrue);
      expect(result.knockout.probability, 1.0);
    },
  );
  {
    test('large overkill remains a valid distribution', () {
      final result = combined.run(
        combined.request([
          combined.attack(
            [
              combined.distribution({100000001: 1}),
            ],
            conditional: {1: 1},
          ),
        ]),
      );
      expect(result.ko.guaranteedHits, 1);
      expect(result.attackDamage.weights, {BigInt.from(100000001): BigInt.one});
    });
  }
  {
    CombinedDamageResult calculate(
      PokemonStateDto pokemon, {
      BattleFieldDto? field,
      BattleSetupDto? setup,
      int damage = 20,
    }) => combined.run(
      combined.request(
        [
          combined.attack([
            combined.distribution({damage: 1}),
          ]),
        ],
        pokemon: pokemon,
        field: field,
        setup: setup,
      ),
    );

    void hp(CombinedDamageResult result, int value) =>
        expect(result.finalHp.weights, {value: BigInt.one});

    final gas = BattleFieldDto(
      format: BattleFormat.single,
      effects: {FieldEffect.neutralizingGas},
    );

    test('scheduled Cud Chew requires an active ability at turn end', () {
      for (final suppressed in [false, true]) {
        for (final neutralizingGas in [false, true]) {
          final result = calculate(
            combined.defender(
              currentHp: 60,
              item: ItemId.sitrusBerry,
              ability: AbilityId.cudChew,
              itemConsumed: true,
              cudChewTurn: 1,
              flags: {PokemonFlag.abilitySuppressed: suppressed},
            ),
            field: neutralizingGas ? gas : null,
          );
          final active = !suppressed && !neutralizingGas;
          hp(result, active ? 65 : 40);
          expect(
            result.finalStates.single.state.cudChewTurn,
            active ? null : 1,
          );
          expect(result.finalStates.single.state.itemConsumed, isTrue);
        }
      }
    });

    final room = BattleFieldDto(
      format: BattleFormat.single,
      effects: {FieldEffect.magicRoom},
    );

    final sand = BattleFieldDto(
      format: BattleFormat.single,
      weather: Weather.sandstorm,
    );

    test(
      'item disabling conditions prevent Sitrus and consumed items stay disabled',
      () {
        for (final pokemon in [
          combined.defender(
            currentHp: 60,
            item: ItemId.sitrusBerry,
            ability: AbilityId.klutz,
          ),
          combined.defender(
            currentHp: 60,
            item: ItemId.sitrusBerry,
            itemConsumed: true,
          ),
          combined.defender(
            currentHp: 60,
            item: ItemId.sitrusBerry,
            flags: {PokemonFlag.itemSuppressed: true},
          ),
        ]) {
          hp(calculate(pokemon), 40);
        }
        hp(
          calculate(
            combined.defender(currentHp: 60, item: ItemId.sitrusBerry),
            field: room,
          ),
          40,
        );
        hp(
          calculate(
            combined.defender(
              currentHp: 60,
              item: ItemId.sitrusBerry,
              ability: AbilityId.klutz,
            ),
            field: gas,
          ),
          65,
        );
        hp(
          calculate(
            combined.defender(
              currentHp: 60,
              item: ItemId.sitrusBerry,
              ability: AbilityId.klutz,
              flags: {PokemonFlag.abilitySuppressed: true},
            ),
          ),
          65,
        );
      },
    );

    test(
      'Ability Shield protection honors consumption suppression and Magic Room',
      () {
        hp(
          calculate(
            combined.defender(
              status: Status.poison,
              ability: AbilityId.magicGuard,
              item: ItemId.abilityShield,
            ),
            field: gas,
          ),
          80,
        );
        for (final pokemon in [
          combined.defender(
            status: Status.poison,
            ability: AbilityId.magicGuard,
            item: ItemId.abilityShield,
            itemConsumed: true,
          ),
          combined.defender(
            status: Status.poison,
            ability: AbilityId.magicGuard,
            item: ItemId.abilityShield,
            flags: {PokemonFlag.itemSuppressed: true},
          ),
        ]) {
          hp(calculate(pokemon, field: gas), 68);
        }
        hp(
          calculate(
            combined.defender(
              status: Status.poison,
              ability: AbilityId.magicGuard,
              item: ItemId.abilityShield,
            ),
            field: BattleFieldDto(
              format: BattleFormat.single,
              effects: {FieldEffect.magicRoom, FieldEffect.neutralizingGas},
            ),
          ),
          68,
        );
        hp(
          calculate(
            combined.defender(
              status: Status.poison,
              ability: AbilityId.magicGuard,
              flags: {PokemonFlag.abilitySuppressed: true},
            ),
          ),
          68,
        );
        hp(
          calculate(
            combined.defender(ability: AbilityId.neutralizingGas),
            field: gas,
          ),
          80,
        );
      },
    );

    test('suppressed healing abilities leave ordinary Sitrus healing', () {
      for (final ability in [
        AbilityId.ripen,
        AbilityId.cheekPouch,
        AbilityId.cudChew,
      ]) {
        final result = calculate(
          combined.defender(
            currentHp: 60,
            item: ItemId.sitrusBerry,
            ability: ability,
          ),
          field: gas,
        );
        hp(result, 65);
        expect(result.finalStates.single.state.cudChewTurn, isNull);
      }
    });

    test(
      'Sitrus threshold includes half HP and zero damage does not trigger',
      () {
        hp(
          calculate(
            combined.defender(currentHp: 51, item: ItemId.sitrusBerry),
            damage: 1,
          ),
          75,
        );
        hp(
          calculate(
            combined.defender(currentHp: 52, item: ItemId.sitrusBerry),
            damage: 1,
          ),
          51,
        );
        hp(
          calculate(
            combined.defender(currentHp: 40, item: ItemId.sitrusBerry),
            damage: 0,
          ),
          40,
        );
      },
    );

    test('boots protect hazards until consumed or disabled', () {
      final setup = BattleSetupDto(
        entryHazards: EntryHazardsDto(stealthRock: true, spikesLayers: 3),
      );
      hp(
        calculate(combined.defender(item: ItemId.heavyDutyBoots), setup: setup),
        80,
      );
      hp(
        calculate(
          combined.defender(item: ItemId.heavyDutyBoots, itemConsumed: true),
          setup: setup,
        ),
        43,
      );
      hp(
        calculate(
          combined.defender(item: ItemId.heavyDutyBoots),
          setup: setup,
          field: room,
        ),
        43,
      );
    });

    test(
      'Spikes grounding respects flying levitate Eelevate balloon explicit flags and gravity',
      () {
        final setup = BattleSetupDto(
          entryHazards: EntryHazardsDto(spikesLayers: 3),
        );
        for (final pokemon in [
          combined.defender(types: [PokemonType.flying]),
          combined.defender(ability: AbilityId.levitate),
          combined.defender(ability: AbilityId.eelevate),
          combined.defender(item: ItemId.airBalloon),
          combined.defender(flags: {PokemonFlag.grounded: false}),
        ]) {
          hp(calculate(pokemon, setup: setup), 80);
        }
        for (final pokemon in [
          combined.defender(item: ItemId.airBalloon, itemConsumed: true),
          combined.defender(ability: AbilityId.eelevate, item: ItemId.ironBall),
          combined.defender(
            ability: AbilityId.eelevate,
            flags: {PokemonFlag.abilitySuppressed: true},
          ),
          combined.defender(types: [PokemonType.flying], item: ItemId.ironBall),
          combined.defender(
            types: [PokemonType.flying],
            flags: {PokemonFlag.grounded: true},
          ),
        ]) {
          hp(calculate(pokemon, setup: setup), 55);
        }
        hp(
          calculate(
            combined.defender(types: [PokemonType.flying]),
            setup: setup,
            field: BattleFieldDto(format: BattleFormat.single, gravity: true),
          ),
          55,
        );
        hp(
          calculate(
            combined.defender(ability: AbilityId.levitate),
            setup: setup,
            field: gas,
          ),
          55,
        );
        hp(
          calculate(
            combined.defender(item: ItemId.airBalloon),
            setup: setup,
            field: room,
          ),
          55,
        );
        hp(
          calculate(
            combined.defender(
              types: [PokemonType.flying],
              item: ItemId.ironBall,
            ),
            setup: setup,
            field: room,
          ),
          80,
        );
      },
    );

    test('Spikes one and two layers round down independently', () {
      hp(
        calculate(
          combined.defender(),
          setup: BattleSetupDto(entryHazards: EntryHazardsDto(spikesLayers: 1)),
        ),
        68,
      );
      hp(
        calculate(
          combined.defender(),
          setup: BattleSetupDto(entryHazards: EntryHazardsDto(spikesLayers: 2)),
        ),
        64,
      );
    });

    test(
      'terastallized type determines grounding and hazard effectiveness',
      () {
        final pokemon = PokemonStateDto(
          profile: PokemonProfileDto(
            id: PokemonId.pikachu,
            types: [PokemonType.flying],
            weight: 50,
          ),
          stats: const StatsDto(
            hp: 100,
            atk: 100,
            def: 100,
            spa: 100,
            spd: 100,
            spe: 100,
          ),
          teraType: TeraType.steel,
        );
        hp(
          calculate(
            pokemon,
            setup: BattleSetupDto(
              entryHazards: EntryHazardsDto(stealthRock: true, spikesLayers: 3),
            ),
          ),
          49,
        );
      },
    );

    test(
      'sand immunity uses active abilities types and unconsumed goggles',
      () {
        for (final type in [
          PokemonType.rock,
          PokemonType.ground,
          PokemonType.steel,
        ]) {
          hp(calculate(combined.defender(types: [type]), field: sand), 80);
        }
        for (final ability in [
          AbilityId.sandVeil,
          AbilityId.sandRush,
          AbilityId.sandForce,
          AbilityId.overcoat,
          AbilityId.magicGuard,
        ]) {
          hp(calculate(combined.defender(ability: ability), field: sand), 80);
        }
        hp(
          calculate(combined.defender(item: ItemId.safetyGoggles), field: sand),
          80,
        );
        hp(
          calculate(
            combined.defender(item: ItemId.safetyGoggles, itemConsumed: true),
            field: sand,
          ),
          74,
        );
        hp(
          calculate(
            combined.defender(
              item: ItemId.safetyGoggles,
              flags: {PokemonFlag.itemSuppressed: true},
            ),
            field: sand,
          ),
          74,
        );
        hp(
          calculate(
            combined.defender(
              ability: AbilityId.overcoat,
              flags: {PokemonFlag.abilitySuppressed: true},
            ),
            field: sand,
          ),
          74,
        );
      },
    );

    test(
      'burn Heatproof Magic Guard and poison healing use distinct rounding',
      () {
        hp(calculate(combined.defender(status: Status.burn)), 74);
        hp(
          calculate(
            combined.defender(
              status: Status.burn,
              ability: AbilityId.heatproof,
            ),
          ),
          77,
        );
        hp(
          calculate(
            combined.defender(
              status: Status.burn,
              ability: AbilityId.heatproof,
            ),
            field: gas,
          ),
          74,
        );
        hp(
          calculate(
            combined.defender(
              status: Status.burn,
              ability: AbilityId.magicGuard,
            ),
          ),
          80,
        );
        final healed = calculate(
          combined.defender(
            currentHp: 60,
            status: Status.poison,
            ability: AbilityId.poisonHeal,
          ),
        );
        hp(healed, 52);
        expect(healed.finalStates.single.state.toxicCounter, isNull);
        hp(
          calculate(
            combined.defender(
              currentHp: 60,
              status: Status.poison,
              ability: AbilityId.poisonHeal,
            ),
            field: gas,
          ),
          28,
        );
        final toxic = calculate(
          combined.defender(status: Status.toxic, toxicCounter: 15),
        );
        hp(toxic, 0);
        expect(toxic.finalStates.single.state.toxicCounter, 15);
      },
    );

    test(
      'lethal residuals stop healing status updates and scheduled Cud Chew',
      () {
        hp(
          calculate(
            combined.defender(
              currentHp: 5,
              status: Status.poison,
              item: ItemId.leftovers,
            ),
            damage: 0,
            field: sand,
          ),
          0,
        );
        hp(
          calculate(
            combined.defender(
              currentHp: 5,
              status: Status.burn,
              item: ItemId.leftovers,
            ),
            damage: 0,
          ),
          5,
        );
        hp(
          calculate(
            combined.defender(
              currentHp: 5,
              status: Status.burn,
              item: ItemId.sitrusBerry,
              ability: AbilityId.cudChew,
              itemConsumed: true,
              cudChewTurn: 1,
            ),
            damage: 0,
          ),
          0,
        );
        final scheduled = calculate(
          combined.defender(
            currentHp: 60,
            item: ItemId.sitrusBerry,
            ability: AbilityId.cudChew,
            itemConsumed: true,
            cudChewTurn: 1,
          ),
        );
        hp(scheduled, 65);
        hp(
          calculate(
            combined.defender(
              currentHp: 60,
              item: ItemId.sitrusBerry,
              ability: AbilityId.cudChew,
              itemConsumed: true,
              cudChewTurn: 1,
            ),
            field: room,
          ),
          40,
        );
      },
    );

    test('Leftovers skip full HP and consumed item and cap recovery', () {
      hp(calculate(combined.defender(item: ItemId.leftovers), damage: 0), 100);
      hp(
        calculate(
          combined.defender(item: ItemId.leftovers, itemConsumed: true),
        ),
        80,
      );
      hp(
        calculate(
          combined.defender(currentHp: 99, item: ItemId.leftovers),
          damage: 0,
        ),
        100,
      );
    });
  }
  {
    const fourOrFive = prefix_oracle.AttackInput(
      [
        {1: 1},
        {1: 1},
        {1: 1},
        {1: 1},
        {1: 1},
      ],
      {4: 1, 5: 1},
    );

    test(
      'four and five hits share their prefix within a 16 operation budget',
      () {
        final result = combined.run(
          combined.request([
            fourOrFive.dto,
          ], limits: const CalculationLimitsDto(maxOperations: 16)),
        );
        expect(result.attackDamage.weights, {
          BigInt.from(4): BigInt.one,
          BigInt.from(5): BigInt.one,
        });
        expect(result.finalHp.weights, {96: BigInt.one, 95: BigInt.one});
        expect(result.knockout.weight, BigInt.zero);
        expect(result.knockout.totalWeight, BigInt.two);
        expect(result.ko.status, KoStatus.notApplicable);
        prefix_oracle.expectOracle(
          result,
          prefix_oracle.enumerate([fourOrFive]),
        );
      },
    );

    test(
      'four and five hits reject a 15 operation budget and earlier limits',
      () {
        // These boundaries also exercise the input scan, hit advance and prefix
        // collection. The successful 16-operation result is tested separately.
        for (final limit in [6, 7, 13, 15]) {
          prefix_oracle.expectBudgetFailure(
            combined.request([
              fourOrFive.dto,
            ], limits: CalculationLimitsDto(maxOperations: limit)),
          );
        }
      },
    );

    test(
      'state limit applies when collecting different hit-count prefixes',
      () {
        prefix_oracle.expectBudgetFailure(
          combined.request([
            fourOrFive.dto,
          ], limits: const CalculationLimitsDto(maxStates: 1)),
        );
        final result = combined.run(
          combined.request([
            fourOrFive.dto,
          ], limits: const CalculationLimitsDto(maxStates: 2)),
        );
        prefix_oracle.expectOracle(
          result,
          prefix_oracle.enumerate([fourOrFive]),
        );
      },
    );

    test(
      'knockout stopping still charges the terminal-state operation budget',
      () {
        const attack = prefix_oracle.AttackInput(
          [
            {1: 1},
            {5: 7},
          ],
          {2: 1},
        );
        for (final limit in [4, 5, 6]) {
          prefix_oracle.expectBudgetFailure(
            combined.request(
              [attack.dto],
              pokemon: combined.defender(hp: 1),
              limits: CalculationLimitsDto(maxOperations: limit),
            ),
          );
        }
        final result = combined.run(
          combined.request(
            [attack.dto],
            pokemon: combined.defender(hp: 1),
            limits: const CalculationLimitsDto(maxOperations: 7),
          ),
        );
        expect(result.attackDamage.weights, {BigInt.from(1): BigInt.from(7)});
        expect(result.finalHp.weights, {0: BigInt.from(7)});
        expect(result.knockout.weight, BigInt.from(7));
        expect(result.knockout.totalWeight, BigInt.from(7));
        prefix_oracle.expectOracle(
          result,
          prefix_oracle.enumerate([attack], maxHp: 1, currentHp: 1),
        );
      },
    );

    const hits = [
      {10: 1, 20: 1},
      {30: 1, 40: 2},
    ];

    test(
      'larger conditional maximum does not inflate actual integer weights',
      () {
        const attack = prefix_oracle.AttackInput(
          hits,
          {0: 3, 1: 7},
          conditional: {2: 1},
        );
        final result = combined.run(
          combined.request([attack.dto], pokemon: combined.defender(hp: 50)),
        );
        expect(result.attackDamage.weights, {
          BigInt.from(0): BigInt.from(6),
          BigInt.from(10): BigInt.from(7),
          BigInt.from(20): BigInt.from(7),
        });
        expect(result.knockout.weight, BigInt.zero);
        expect(result.knockout.totalWeight, BigInt.from(20));
        expect(result.ko.status, KoStatus.limitReached);
        expect(result.ko.possibleHits, 1);
        expect(result.ko.guaranteedHits, isNull);
        prefix_oracle.expectOracle(
          result,
          prefix_oracle.enumerate([attack], maxHp: 50, currentHp: 50),
        );
      },
    );

    test(
      'larger actual maximum retains its own denominator and conditional KO',
      () {
        const attack = prefix_oracle.AttackInput(
          hits,
          {0: 1, 2: 2},
          conditional: {1: 1},
        );
        final result = combined.run(
          combined.request([attack.dto], pokemon: combined.defender(hp: 50)),
        );
        expect(result.attackDamage.weights, {
          BigInt.from(0): BigInt.from(6),
          BigInt.from(40): BigInt.two,
          BigInt.from(50): BigInt.from(6),
          BigInt.from(60): BigInt.from(4),
        });
        expect(result.knockout.weight, BigInt.from(10));
        expect(result.knockout.totalWeight, BigInt.from(18));
        expect(result.ko.status, KoStatus.limitReached);
        expect(result.ko.possibleHits, isNull);
        expect(result.ko.guaranteedHits, isNull);
        prefix_oracle.expectOracle(
          result,
          prefix_oracle.enumerate([attack], maxHp: 50, currentHp: 50),
        );
      },
    );

    test(
      'same count candidates share KO reachability despite different weights',
      () {
        for (final conditional in [
          {1: 1, 2: 99},
          {1: 99, 2: 1},
        ]) {
          final attack = prefix_oracle.AttackInput(
            const [
              {20: 1},
              {20: 1},
            ],
            const {1: 99, 2: 1},
            conditional: conditional,
          );
          final two = combined.run(
            combined.request([
              attack.dto,
              attack.dto,
            ], pokemon: combined.defender(hp: 60)),
          );
          expect(two.attackDamage.weights, {
            BigInt.from(40): BigInt.from(9801),
            BigInt.from(60): BigInt.from(199),
          });
          expect(two.finalHp.weights, {
            20: BigInt.from(9801),
            0: BigInt.from(199),
          });
          expect(two.knockout.weight, BigInt.from(199));
          expect(two.knockout.totalWeight, BigInt.from(10000));
          expect(two.ko.status, KoStatus.limitReached);
          expect(two.ko.possibleHits, 2);
          expect(two.ko.guaranteedHits, isNull);
          prefix_oracle.expectOracle(
            two,
            prefix_oracle.enumerate([attack, attack], maxHp: 60, currentHp: 60),
          );
          final result = combined.run(
            combined.request([
              attack.dto,
              attack.dto,
              attack.dto,
            ], pokemon: combined.defender(hp: 60)),
          );
          expect(result.ko.status, KoStatus.resolved);
          expect(result.ko.possibleHits, 2);
          expect(result.ko.guaranteedHits, 3);
          expect(result.attackDamage.weights, {
            BigInt.from(60): BigInt.from(1000000),
          });
          expect(result.finalHp.weights, {0: BigInt.from(1000000)});
          expect(result.knockout.weight, BigInt.from(1000000));
          expect(result.knockout.totalWeight, BigInt.from(1000000));
          prefix_oracle.expectOracle(
            result,
            prefix_oracle.enumerate(
              [attack, attack, attack],
              maxHp: 60,
              currentHp: 60,
            ),
          );
        }
      },
    );

    test(
      'shared conditional prefix collection observes the operation limit',
      () {
        const attack = prefix_oracle.AttackInput(
          [
            {1: 1},
          ],
          {0: 1},
          conditional: {1: 1},
        );
        for (final limit in [5, 7]) {
          prefix_oracle.expectBudgetFailure(
            combined.request([
              attack.dto,
            ], limits: CalculationLimitsDto(maxOperations: limit)),
          );
        }
        final result = combined.run(
          combined.request([
            attack.dto,
          ], limits: const CalculationLimitsDto(maxOperations: 8)),
        );
        expect(result.ko.status, KoStatus.limitReached);
        expect(result.ko.possibleHits, isNull);
        expect(result.ko.guaranteedHits, isNull);
        prefix_oracle.expectOracle(result, prefix_oracle.enumerate([attack]));
      },
    );

    test(
      'separated conditional execution observes hit and collection budgets',
      () {
        const first = prefix_oracle.AttackInput(
          [
            {1: 1},
          ],
          {0: 1, 1: 1},
          conditional: {1: 1},
        );
        const second = prefix_oracle.AttackInput(
          [
            {1: 1},
          ],
          {1: 1},
          conditional: {1: 1},
        );
        for (final limit in [18, 19, 22]) {
          prefix_oracle.expectBudgetFailure(
            combined.request([
              first.dto,
              second.dto,
            ], limits: CalculationLimitsDto(maxOperations: limit)),
          );
        }
        final result = combined.run(
          combined.request([
            first.dto,
            second.dto,
          ], limits: const CalculationLimitsDto(maxOperations: 23)),
        );
        expect(result.attackDamage.weights, {
          BigInt.from(1): BigInt.one,
          BigInt.from(2): BigInt.one,
        });
        expect(result.ko.status, KoStatus.limitReached);
        expect(result.ko.possibleHits, isNull);
        expect(result.ko.guaranteedHits, isNull);
        prefix_oracle.expectOracle(
          result,
          prefix_oracle.enumerate([first, second]),
        );
      },
    );

    test('separated conditional branches alone can exceed the state limit', () {
      const first = prefix_oracle.AttackInput(
        [
          {1: 1},
        ],
        {0: 1},
        conditional: {1: 1},
      );
      const second = prefix_oracle.AttackInput(
        [
          {1: 1, 2: 1},
        ],
        {0: 1},
        conditional: {1: 1},
      );
      prefix_oracle.expectBudgetFailure(
        combined.request([
          first.dto,
          second.dto,
        ], limits: const CalculationLimitsDto(maxStates: 1)),
      );
      final result = combined.run(
        combined.request([
          first.dto,
          second.dto,
        ], limits: const CalculationLimitsDto(maxStates: 2)),
      );
      expect(result.finalHp.weights, {100: BigInt.one});
      expect(result.attackDamage.weights, {BigInt.from(0): BigInt.one});
      expect(result.ko.status, KoStatus.limitReached);
      expect(result.ko.possibleHits, isNull);
      expect(result.ko.guaranteedHits, isNull);
      prefix_oracle.expectOracle(
        result,
        prefix_oracle.enumerate([first, second]),
      );
    });

    test(
      'multiple counts with berries and knockout stopping match full path enumeration',
      () {
        const first = prefix_oracle.AttackInput(
          [
            {0: 1, 35: 2},
            {20: 2, 120: 1},
            {0: 3, 15: 1},
            {10: 1, 90: 2},
            {5: 2, 160: 1},
          ],
          {0: 2, 1: 3, 2: 5, 4: 7, 5: 11},
        );
        const second = prefix_oracle.AttackInput(
          [
            {0: 1, 30: 2},
            {1: 1, 70: 3},
          ],
          {0: 1, 1: 2, 2: 3},
        );
        final result = combined.run(
          combined.request(
            [first.dto, second.dto],
            pokemon: combined.defender(currentHp: 80, item: ItemId.sitrusBerry),
          ),
        );
        final oracle = prefix_oracle.enumerate(
          [first, second],
          currentHp: 80,
          sitrus: true,
        );
        prefix_oracle.expectOracle(result, oracle);
        expect(result.attackDamage.totalWeight, BigInt.from(653184));
        expect(result.knockout.weight, greaterThan(BigInt.zero));
        expect(result.knockout.weight, lessThan(result.knockout.totalWeight));
        expect(result.ko.status, KoStatus.notApplicable);
        expect(
          result.finalStates.where((s) => s.state.itemConsumed),
          isNotEmpty,
        );
        expect(
          result.finalStates.where((s) => !s.state.itemConsumed),
          isNotEmpty,
        );
      },
    );
  }
  {
    CombinedDamageResult resolve(
      PokemonStateDto pokemon, {
      Terrain? terrain,
      Weather? weather,
    }) => combined.run(
      combined.request(
        [
          combined.attack([
            combined.distribution({0: 1}),
          ]),
        ],
        pokemon: pokemon,
        field: BattleFieldDto(
          format: BattleFormat.single,
          terrain: terrain,
          weather: weather,
        ),
      ),
    );

    test('terrain and Leftovers heal before poison, including misses', () {
      final full = resolve(
        combined.defender(item: ItemId.leftovers, status: Status.poison),
        terrain: Terrain.grass,
      );
      expect(full.finalHp.weights, {88: BigInt.one});
      final low = resolve(
        combined.defender(
          currentHp: 5,
          item: ItemId.leftovers,
          status: Status.poison,
        ),
        terrain: Terrain.grass,
      );
      expect(low.finalHp.weights, {5: BigInt.one});
      expect(low.attackDamage.weights, {BigInt.from(0): BigInt.one});
      expect(low.knockout.weight, BigInt.zero);
      expect(
        resolve(
          combined.defender(
            currentHp: 5,
            item: ItemId.leftovers,
            status: Status.poison,
          ),
        ).finalHp.weights,
        {0: BigInt.one},
      );
    });

    test('sand knockout stops all later recovery', () {
      expect(
        resolve(
          combined.defender(currentHp: 5, item: ItemId.leftovers),
          terrain: Terrain.grass,
          weather: Weather.sandstorm,
        ).finalHp.weights,
        {0: BigInt.one},
      );
    });

    test('Grassy Terrain recovery floors, caps and requires grounding', () {
      expect(
        resolve(
          combined.defender(hp: 101, currentHp: 80),
          terrain: Terrain.grass,
        ).finalHp.weights,
        {86: BigInt.one},
      );
      expect(
        resolve(
          combined.defender(currentHp: 99),
          terrain: Terrain.grass,
        ).finalHp.weights,
        {100: BigInt.one},
      );
      expect(
        resolve(
          combined.defender(hp: 8, currentHp: 7),
          terrain: Terrain.grass,
        ).finalHp.weights,
        {8: BigInt.one},
      );
      for (final pokemon in [
        combined.defender(currentHp: 80, types: [PokemonType.flying]),
        combined.defender(currentHp: 80, ability: AbilityId.levitate),
        combined.defender(currentHp: 80, item: ItemId.airBalloon),
      ]) {
        expect(resolve(pokemon, terrain: Terrain.grass).finalHp.weights, {
          80: BigInt.one,
        });
      }
      expect(
        resolve(
          combined.defender(
            currentHp: 80,
            item: ItemId.airBalloon,
            itemConsumed: true,
          ),
          terrain: Terrain.grass,
        ).finalHp.weights,
        {86: BigInt.one},
      );
    });

    test(
      'berry interrupts sand, then terrain, poison and next turn Cud Chew',
      () {
        final result = combined.run(
          combined.request(
            [
              combined.attack([
                combined.distribution({0: 1}),
              ]),
              combined.attack([
                combined.distribution({0: 1}),
              ], turn: 2),
            ],
            pokemon: combined.defender(
              currentHp: 55,
              item: ItemId.sitrusBerry,
              ability: AbilityId.cudChew,
              status: Status.poison,
            ),
            field: BattleFieldDto(
              format: BattleFormat.single,
              terrain: Terrain.grass,
              weather: Weather.sandstorm,
            ),
          ),
        );
        expect(result.finalHp.weights, {81: BigInt.one});
        expect(result.finalStates.single.state.itemConsumed, isTrue);
        expect(result.finalStates.single.state.cudChewTurn, isNull);
      },
    );
  }
  {
    group('Combined HP processing respects the same active effects', () {
      const hazards = EntryHazardsDto(stealthRock: true, spikesLayers: 3);

      test('Magic Guard prevents Stealth Rock and three layers of Spikes', () {
        // Smogon desc.ts getHazards guards both hazards with Magic Guard.
        regressions.expectHp(
          regressions.combine(
            defender: regressions.pokemon(ability: AbilityId.magicGuard),
            hazards: hazards,
          ),
          200,
        );
      });

      test('Suppressed Magic Guard allows the full 75 HP of entry hazards', () {
        for (final suppressed in [true, false]) {
          regressions.expectHp(
            regressions.combine(
              defender: regressions.pokemon(
                ability: AbilityId.magicGuard,
                flags: {PokemonFlag.abilitySuppressed: suppressed},
              ),
              field: regressions.defaultField(
                effects: suppressed ? {} : {FieldEffect.neutralizingGas},
              ),
              hazards: hazards,
            ),
            125,
          );
        }
      });

      test(
        'Ability Shield protects Magic Guard from gas during entry hazards',
        () {
          regressions.expectHp(
            regressions.combine(
              defender: regressions.pokemon(
                ability: AbilityId.magicGuard,
                item: ItemId.abilityShield,
              ),
              field: regressions.defaultField(
                effects: {FieldEffect.neutralizingGas},
              ),
              hazards: hazards,
            ),
            200,
          );
        },
      );

      test(
        'Manual initial damage still applies through Magic Guard and triggers berries',
        () {
          regressions.expectHp(
            regressions.combine(
              defender: regressions.pokemon(
                ability: AbilityId.magicGuard,
                item: ItemId.sitrusBerry,
              ),
              hazards: hazards,
              initialDamages: [110],
            ),
            140,
            itemConsumed: true,
          );
          regressions.expectHp(
            regressions.combine(
              defender: regressions.pokemon(
                ability: AbilityId.magicGuard,
                item: ItemId.sitrusBerry,
              ),
              hazards: hazards,
              initialDamages: [200],
            ),
            0,
          );
        },
      );

      for (final ability in [AbilityId.airLock, AbilityId.cloudNine]) {
        test(
          '${ability.value} suppresses sand damage in combined HP processing',
          () {
            // util.ts checkAirLock clears effective weather before desc.ts residuals.
            regressions.expectHp(
              regressions.combine(
                defender: regressions.pokemon(ability: ability),
                field: regressions.defaultField(weather: Weather.sandstorm),
              ),
              200,
            );
          },
        );

        test('Suppressed ${ability.value} permits the 12 HP sand residual', () {
          for (final suppressed in [true, false]) {
            regressions.expectHp(
              regressions.combine(
                defender: regressions.pokemon(
                  ability: ability,
                  flags: {PokemonFlag.abilitySuppressed: suppressed},
                ),
                field: regressions.defaultField(
                  weather: Weather.sandstorm,
                  effects: suppressed ? {} : {FieldEffect.neutralizingGas},
                ),
              ),
              188,
            );
          }
        });

        test(
          'Ability Shield preserves ${ability.value} weather suppression against gas',
          () {
            regressions.expectHp(
              regressions.combine(
                defender: regressions.pokemon(
                  ability: ability,
                  item: ItemId.abilityShield,
                ),
                field: regressions.defaultField(
                  weather: Weather.sandstorm,
                  effects: {FieldEffect.neutralizingGas},
                ),
              ),
              200,
            );
          },
        );
      }
    });
  }
  {
    test(
      'two independent sixteen rolls produce all 256 exact combinations',
      () {
        final rolls = combined.distribution({
          for (var i = 1; i <= 16; i++) i: 1,
        });
        final result = combined.run(
          combined.request([
            combined.attack([rolls, rolls]),
          ]),
        );
        expect(result.attackDamage.totalWeight, BigInt.from(256));
        expect(result.attackDamage.weights, {
          for (var i = 2; i <= 32; i++)
            BigInt.from(i): BigInt.from(i <= 17 ? i - 1 : 33 - i),
        });
        expect(result.finalHp.weights, {
          for (var i = 2; i <= 32; i++)
            100 - i: BigInt.from(i <= 17 ? i - 1 : 33 - i),
        });
      },
    );

    test('different hit count denominators are normalized exactly', () {
      final result = combined.run(
        combined.request([
          combined.attack(
            [
              combined.distribution({10: 1, 20: 1}),
              combined.distribution({1: 1, 2: 2}),
            ],
            counts: {0: 1, 1: 1, 2: 1},
          ),
        ]),
      );
      expect(result.attackDamage.weights, {
        BigInt.from(0): BigInt.from(6),
        BigInt.from(10): BigInt.from(3),
        BigInt.from(20): BigInt.from(3),
        BigInt.from(11): BigInt.one,
        BigInt.from(12): BigInt.two,
        BigInt.from(21): BigInt.one,
        BigInt.from(22): BigInt.two,
      });
      expect(result.attackDamage.totalWeight, BigInt.from(18));
    });

    test('tiny probabilities retain integer weight without truncation', () {
      final enormous = BigInt.one << 200;
      final result = combined.run(
        combined.request([
          AttackDto(
            turn: 1,
            hits: [
              DamageDistribution({100: BigInt.one, 0: enormous}),
            ],
            hitCounts: {1: BigInt.one},
          ),
        ]),
      );
      expect(result.knockout.weight, BigInt.one);
      expect(result.knockout.totalWeight, enormous + BigInt.one);
    });

    test(
      'conditional one hit KO is separate from 70 and 91 percent knockout',
      () {
        final hit = combined.attack(
          [
            combined.distribution({100: 1}),
          ],
          counts: {0: 3, 1: 7},
          conditional: {1: 1},
        );
        final one = combined.run(combined.request([hit]));
        expect(one.ko.possibleHits, 1);
        expect(one.ko.guaranteedHits, 1);
        expect(one.knockout.weight, BigInt.from(7));
        expect(one.knockout.totalWeight, BigInt.from(10));
        final two = combined.run(combined.request([hit, hit]));
        expect(two.knockout.weight, BigInt.from(91));
        expect(two.knockout.totalWeight, BigInt.from(100));
        expect(two.attackDamage.weights, {
          BigInt.from(0): BigInt.from(9),
          BigInt.from(100): BigInt.from(91),
        });
      },
    );

    test(
      'Triple Axel supplied counts return knockout but no conditional KO',
      () {
        final result = combined.run(
          combined.request([
            combined.attack(
              [
                combined.distribution({20: 1}),
                combined.distribution({40: 1}),
                combined.distribution({60: 1}),
              ],
              counts: {0: 100, 1: 90, 2: 81, 3: 729},
            ),
          ]),
        );
        expect(result.knockout.weight, BigInt.from(729));
        expect(result.knockout.totalWeight, BigInt.from(1000));
        expect(result.ko.status, KoStatus.notApplicable);
        expect(result.attackDamage.weights, {
          BigInt.from(0): BigInt.from(100),
          BigInt.from(20): BigInt.from(90),
          BigInt.from(60): BigInt.from(81),
          BigInt.from(120): BigInt.from(729),
        });
      },
    );

    test('conditional KO distinguishes possible two from guaranteed three', () {
      final a = combined.attack(
        [
          combined.distribution({40: 1, 60: 1}),
        ],
        conditional: {1: 1},
      );
      final result = combined.run(
        combined.request([a, a, a], pokemon: combined.defender(hp: 120)),
      );
      expect(result.ko.status, KoStatus.resolved);
      expect(result.ko.possibleHits, 2);
      expect(result.ko.guaranteedHits, 3);
      expect(
        combined.run(combined.request([a])).ko.status,
        KoStatus.limitReached,
      );
    });

    test('zero hits advance turns and apply leftovers and poison', () {
      final miss = combined.attack(
        [
          combined.distribution({999: 1}),
        ],
        counts: {0: 1},
      );
      final result = combined.run(
        combined.request(
          [
            miss,
            combined.attack(
              [
                combined.distribution({999: 1}),
              ],
              turn: 2,
              counts: {0: 1},
            ),
          ],
          pokemon: combined.defender(
            currentHp: 60,
            item: ItemId.leftovers,
            status: Status.poison,
          ),
        ),
      );
      expect(result.finalHp.weights, {48: BigInt.one});
      expect(result.attackDamage.weights, {BigInt.from(0): BigInt.one});
    });

    test('Sitrus heals between hits and cannot heal lethal damage', () {
      final result = combined.run(
        combined.request([
          combined.attack([
            combined.distribution({20: 1}),
            combined.distribution({20: 1}),
          ]),
        ], pokemon: combined.defender(currentHp: 60, item: ItemId.sitrusBerry)),
      );
      expect(result.finalHp.weights, {45: BigInt.one});
      expect(result.finalStates.single.state.itemConsumed, isTrue);
      final lethal = combined.run(
        combined.request([
          combined.attack([
            combined.distribution({120: 1}),
            combined.distribution({20: 1}),
          ]),
        ], pokemon: combined.defender(item: ItemId.sitrusBerry)),
      );
      expect(lethal.finalHp.weights, {0: BigInt.one});
      expect(lethal.attackDamage.weights, {BigInt.from(120): BigInt.one});
      expect(lethal.finalStates.single.state.itemConsumed, isFalse);
    });

    test('initial hazards then integer damage each trigger Sitrus', () {
      final result = combined.run(
        combined.request(
          [
            combined.attack([
              combined.distribution({0: 1}),
            ]),
          ],
          pokemon: combined.defender(
            currentHp: 65,
            item: ItemId.sitrusBerry,
            types: [PokemonType.fire],
          ),
          setup: BattleSetupDto(
            entryHazards: EntryHazardsDto(stealthRock: true, spikesLayers: 1),
            initialDamages: [10, 0],
          ),
        ),
      );
      expect(result.finalHp.weights, {43: BigInt.one});
      expect(result.attackDamage.weights, {BigInt.from(0): BigInt.one});
      expect(result.finalStates.single.state.itemConsumed, isTrue);
    });

    test('initial knockout stops all hits and end of turn healing', () {
      final result = combined.run(
        combined.request(
          [
            combined.attack(
              [
                combined.distribution({100: 1}),
              ],
              conditional: {1: 1},
            ),
          ],
          pokemon: combined.defender(currentHp: 10, item: ItemId.leftovers),
          setup: BattleSetupDto(initialDamages: [10, 20]),
        ),
      );
      expect(result.finalHp.weights, {0: BigInt.one});
      expect(result.attackDamage.weights, {BigInt.from(0): BigInt.one});
      expect(result.ko.guaranteedHits, 0);
    });

    test('sand status leftovers order and toxic counters are preserved', () {
      final result = combined.run(
        combined.request(
          [
            combined.attack([
              combined.distribution({20: 1}),
            ]),
          ],
          pokemon: combined.defender(
            item: ItemId.leftovers,
            status: Status.poison,
          ),
          field: BattleFieldDto(
            format: BattleFormat.single,
            weather: Weather.sandstorm,
          ),
        ),
      );
      expect(result.finalHp.weights, {68: BigInt.one});
      final toxic = combined.run(
        combined.request([
          combined.attack([
            combined.distribution({20: 1}),
          ]),
        ], pokemon: combined.defender(status: Status.toxic, toxicCounter: 3)),
      );
      expect(toxic.finalHp.weights, {62: BigInt.one});
      expect(toxic.finalStates.single.state.toxicCounter, 4);
      final heal = combined.run(
        combined.request(
          [
            combined.attack([
              combined.distribution({20: 1}),
            ]),
          ],
          pokemon: combined.defender(
            currentHp: 60,
            status: Status.toxic,
            toxicCounter: 3,
            ability: AbilityId.poisonHeal,
          ),
        ),
      );
      expect(heal.finalHp.weights, {52: BigInt.one});
      expect(heal.finalStates.single.state.toxicCounter, 4);
    });

    test('Ripen Cheek Pouch and scheduled Cud Chew retain healing rules', () {
      CombinedDamageResult berry(AbilityId ability) => combined.run(
        combined.request(
          [
            combined.attack([
              combined.distribution({20: 1}),
            ]),
          ],
          pokemon: combined.defender(
            currentHp: 60,
            item: ItemId.sitrusBerry,
            ability: ability,
          ),
        ),
      );
      expect(berry(AbilityId.ripen).finalHp.weights, {90: BigInt.one});
      expect(berry(AbilityId.cheekPouch).finalHp.weights, {98: BigInt.one});
      final chew = combined.run(
        combined.request(
          [
            combined.attack([
              combined.distribution({20: 1}),
            ]),
            combined.attack([
              combined.distribution({20: 1}),
            ], turn: 2),
          ],
          pokemon: combined.defender(
            currentHp: 60,
            item: ItemId.sitrusBerry,
            ability: AbilityId.cudChew,
          ),
        ),
      );
      expect(chew.finalHp.weights, {70: BigInt.one});
      expect(chew.finalStates.single.state.cudChewTurn, isNull);
    });

    test('same HP branches retain different item consumption state', () {
      final result = combined.run(
        combined.request([
          combined.attack([
            combined.distribution({0: 1, 25: 1}),
          ]),
        ], pokemon: combined.defender(currentHp: 60, item: ItemId.sitrusBerry)),
      );
      expect(result.finalHp.weights, {60: BigInt.two});
      expect(result.finalStates, hasLength(2));
      expect(result.finalStates.map((s) => s.state.itemConsumed).toSet(), {
        false,
        true,
      });
    });

    test(
      'complexity budget is shared by all attacks and conditional evaluation',
      () {
        final dto = combined.request([
          combined.attack(
            [
              combined.distribution({10: 1, 20: 1}),
            ],
            conditional: {1: 1},
          ),
        ], limits: const CalculationLimitsDto(maxOperations: 1));
        final validated =
            (CombinedDamageRequest.fromDto(dto) as Valid<CombinedDamageRequest>)
                .value;
        final result = calculateCombinedDamage(validated);
        expect(result, isA<Failure<CombinedDamageResult>>());
        expect((result as Failure).kind, FailureKind.complexityExceeded);
      },
    );

    test('invalid input is rejected before initial knockout', () {
      for (final dto in [
        combined.request([
          combined.attack([
            combined.distribution({-1: 1}),
          ]),
        ], setup: BattleSetupDto(initialDamages: [100])),
        combined.request([
          combined.attack([
            combined.distribution({1: 0}),
          ]),
        ]),
        combined.request([
          combined.attack(
            [
              combined.distribution({1: 1}),
            ],
            counts: {2: 1},
          ),
        ]),
        combined.request([
          combined.attack(
            [
              combined.distribution({1: 1}),
            ],
            counts: {-1: 1},
          ),
        ]),
        combined.request([
          combined.attack(
            [
              combined.distribution({1: 1}),
            ],
            conditional: {0: 1},
          ),
        ]),
        combined.request([
          combined.attack([
            combined.distribution({1: 1}),
          ], turn: 2),
        ]),
        combined.request([
          combined.attack([
            combined.distribution({1: 1}),
          ]),
        ], setup: BattleSetupDto(initialDamages: [-1])),
      ]) {
        expect(
          CombinedDamageRequest.fromDto(dto),
          isA<Invalid<CombinedDamageRequest>>(),
        );
      }
    });
  }
  {
    test(
      'all phases share operation limits including conditional execution',
      () {
        final a = combined.attack(
          [
            combined.distribution({1: 1}),
          ],
          conditional: {1: 1},
        );
        for (var maximum = 1; maximum < 7; maximum++) {
          final r =
              (CombinedDamageRequest.fromDto(
                        combined.request(
                          [a],
                          limits: CalculationLimitsDto(maxOperations: maximum),
                        ),
                      )
                      as Valid<CombinedDamageRequest>)
                  .value;
          final failure =
              calculateCombinedDamage(r) as Failure<CombinedDamageResult>;
          expect(
            failure.kind,
            FailureKind.complexityExceeded,
            reason: '$maximum',
          );
          expect(failure.path, 'distribution');
        }
        expect(
          combined
              .run(
                combined.request([
                  a,
                ], limits: const CalculationLimitsDto(maxOperations: 7)),
              )
              .finalHp
              .weights,
          {99: BigInt.one},
        );
      },
    );

    test('state limit applies to a hit and to merged different hit counts', () {
      final cases = [
        combined.attack([
          combined.distribution({1: 1, 2: 1}),
        ]),
        combined.attack(
          [
            combined.distribution({1: 1}),
          ],
          counts: {0: 1, 1: 1},
        ),
        combined.attack(
          [
            combined.distribution({1: 1, 2: 1}),
          ],
          counts: {0: 1},
          conditional: {1: 1},
        ),
      ];
      for (final a in cases) {
        final r =
            (CombinedDamageRequest.fromDto(
                      combined.request([
                        a,
                      ], limits: const CalculationLimitsDto(maxStates: 1)),
                    )
                    as Valid<CombinedDamageRequest>)
                .value;
        expect(
          (calculateCombinedDamage(r) as Failure).kind,
          FailureKind.complexityExceeded,
        );
      }
    });

    test('same HP item branches produce different later healing', () {
      final r = combined.run(
        combined.request([
          combined.attack([
            combined.distribution({40: 1, 65: 1}),
          ]),
          combined.attack([
            combined.distribution({30: 1}),
          ]),
        ], pokemon: combined.defender(item: ItemId.sitrusBerry)),
      );
      expect(r.finalHp.weights, {55: BigInt.one, 30: BigInt.one});
      expect(r.attackDamage.weights, {
        BigInt.from(70): BigInt.one,
        BigInt.from(95): BigInt.one,
      });
    });

    test('unequal denominators remain exact after lethal hit stopping', () {
      final r = combined.run(
        combined.request([
          combined.attack(
            [
              combined.distribution({1: 1, 2: 1}),
              combined.distribution({3: 1, 4: 2}),
            ],
            counts: {0: 1, 1: 1, 2: 1},
          ),
        ], pokemon: combined.defender(hp: 1)),
      );
      expect(r.attackDamage.weights, {
        BigInt.from(0): BigInt.from(6),
        BigInt.from(1): BigInt.from(6),
        BigInt.from(2): BigInt.from(6),
      });
      expect(r.finalHp.weights, {1: BigInt.from(6), 0: BigInt.from(12)});
      expect(r.knockout.totalWeight, BigInt.from(18));
    });

    test('a miss does not switch the supplied later distribution', () {
      final r = combined.run(
        combined.request(
          [
            combined.attack(
              [
                combined.distribution({10: 1}),
              ],
              counts: {0: 1},
            ),
            combined.attack([
              combined.distribution({20: 1}),
            ]),
          ],
          pokemon: combined.defender(
            ability: AbilityId.multiscale,
            item: ItemId.chilanBerry,
          ),
        ),
      );
      expect(r.attackDamage.weights, {BigInt.from(20): BigInt.one});
      expect(r.finalHp.weights, {80: BigInt.one});
      expect(r.finalStates.single.state.itemConsumed, isFalse);
    });

    test(
      'Disguise is supplied as manual initial damage, without automatic blocking',
      () {
        final r = combined.run(
          combined.request(
            [
              combined.attack([
                combined.distribution({20: 1}),
                combined.distribution({20: 1}),
              ]),
            ],
            pokemon: combined.defender(ability: AbilityId.disguise),
            setup: BattleSetupDto(initialDamages: [12]),
          ),
        );
        expect(r.finalHp.weights, {48: BigInt.one});
        expect(r.attackDamage.weights, {BigInt.from(40): BigInt.one});
        final ordinary = combined.run(
          combined.request([
            combined.attack([
              combined.distribution({20: 1}),
            ]),
          ], pokemon: combined.defender(ability: AbilityId.disguise)),
        );
        expect(ordinary.finalHp.weights, {80: BigInt.one});
      },
    );

    test(
      'explicit Unnerve prevents berry consumption and scheduled reconsumption',
      () {
        final field = BattleFieldDto(
          format: BattleFormat.single,
          effects: {FieldEffect.unnerve},
        );
        final r = combined.run(
          combined.request(
            [
              combined.attack([
                combined.distribution({20: 1}),
              ]),
            ],
            field: field,
            pokemon: combined.defender(
              currentHp: 60,
              item: ItemId.sitrusBerry,
              ability: AbilityId.cudChew,
              cudChewTurn: 1,
            ),
          ),
        );
        expect(r.finalHp.weights, {40: BigInt.one});
        expect(r.finalStates.single.state.itemConsumed, isFalse);
        expect(r.finalStates.single.state.cudChewTurn, 1);
      },
    );

    test(
      'equal HP and accumulated damage retain item consumption snapshots',
      () {
        final r = combined.run(
          combined.request([
            combined.attack([
              combined.distribution({0: 1, 60: 1}),
              combined.distribution({140: 1, 200: 1}),
            ]),
          ], pokemon: combined.defender(item: ItemId.sitrusBerry)),
        );
        expect(r.finalHp.weights, {0: BigInt.from(4)});
        expect(r.attackDamage.weights, {
          BigInt.from(140): BigInt.one,
          BigInt.from(200): BigInt.two,
          BigInt.from(260): BigInt.one,
        });
        expect(r.finalStates, hasLength(4));
        expect(
          r.finalStates
              .where((s) => s.state.itemConsumed)
              .fold(BigInt.zero, (sum, s) => sum + s.weight),
          BigInt.two,
        );
        expect(
          r.finalStates
              .where((s) => !s.state.itemConsumed)
              .fold(BigInt.zero, (sum, s) => sum + s.weight),
          BigInt.two,
        );
      },
    );
  }

  test('反復入力は確定1〜4発を区別する', () {
    final cases = [
      (100, 1, KoCategory.oneHit),
      (50, 2, KoCategory.twoHits),
      (34, 3, KoCategory.threeHits),
      (25, 4, KoCategory.fourHits),
    ];
    for (final (damage, count, category) in cases) {
      final result = combined.run(repeated({damage: 1}));
      expect(result.ko.status, KoStatus.resolved);
      expect(result.ko.possibleHits, count);
      expect(result.ko.guaranteedHits, count);
      expect(result.ko.category, category);
      expect(result.ko.evaluatedAttacks, 4);
      expect(result.finalHp.weights, {0: BigInt.one});
      expect(result.attackDamage.weights, {
        BigInt.from(damage * count): BigInt.one,
      });
      expect(result.knockout.guaranteed, isTrue);
    }
  });

  test('4回未確定は5発以上として正確な回数を捏造しない', () {
    final result = combined.run(repeated({24: 1}));
    expect(result.ko.status, KoStatus.limitReached);
    expect(result.ko.possibleHits, isNull);
    expect(result.ko.guaranteedHits, isNull);
    expect(result.ko.category, KoCategory.fiveOrMore);
    expect(result.finalHp.weights, {4: BigInt.one});
    expect(result.attackDamage.weights, {BigInt.from(96): BigInt.one});
    expect(result.knockout.weight, BigInt.zero);
  });

  test('0ダメージと0を含む分布も5発以上の区分に含める', () {
    for (final weights in [
      {0: 1},
      {0: 1, 100: 1},
    ]) {
      final result = combined.run(repeated(weights));
      expect(result.ko.status, KoStatus.limitReached);
      expect(result.ko.guaranteedHits, isNull);
      expect(result.ko.category, KoCategory.fiveOrMore);
      expect(result.finalHp.weights[100], BigInt.one);
    }
    final possible = combined.run(repeated({0: 1, 100: 1}));
    expect(possible.ko.possibleHits, 1);
    expect(possible.knockout.weight, BigInt.from(15));
    expect(possible.knockout.totalWeight, BigInt.from(16));
  });

  test('4回後の撃破率は外れ込みで確定数は命中前提', () {
    final result = combined.run(
      repeated({40: 1}, hitCounts: {0: BigInt.one, 1: BigInt.one}),
    );
    expect(result.ko.guaranteedHits, 3);
    expect(result.ko.category, KoCategory.threeHits);
    expect(result.knockout.weight, BigInt.from(5));
    expect(result.knockout.totalWeight, BigInt.from(16));
    expect(result.finalHp.weights, {
      0: BigInt.from(5),
      20: BigInt.from(6),
      60: BigInt.from(4),
      100: BigInt.one,
    });
    expect(result.attackDamage.weights, {
      BigInt.from(120): BigInt.from(5),
      BigInt.from(80): BigInt.from(6),
      BigInt.from(40): BigInt.from(4),
      BigInt.from(0): BigInt.one,
    });
  });

  test('全外れでも命中前提の確定数と実際のHPを区別する', () {
    final result = combined.run(repeated({100: 1}, hitCounts: {0: BigInt.one}));
    expect(result.ko.guaranteedHits, 1);
    expect(result.ko.category, KoCategory.oneHit);
    expect(result.knockout.weight, BigInt.zero);
    expect(result.finalHp.weights, {100: BigInt.one});
    expect(result.attackDamage.weights, {BigInt.from(0): BigInt.one});
  });

  test('オボン込みでは確定2発が確定3発になる', () {
    final without = combined.run(repeated({60: 1}));
    final withBerry = combined.run(
      repeated({60: 1}, defender: combined.defender(item: ItemId.sitrusBerry)),
    );
    expect(without.ko.guaranteedHits, 2);
    expect(withBerry.ko.possibleHits, 3);
    expect(withBerry.ko.guaranteedHits, 3);
    expect(withBerry.ko.category, KoCategory.threeHits);
    expect(withBerry.attackDamage.weights, {BigInt.from(180): BigInt.one});
    expect(withBerry.finalHp.weights, {0: BigInt.one});
    expect(withBerry.finalStates.single.state.itemConsumed, isTrue);
  });

  test('オボン込みの乱数分布で撃破可能2発と確定4発を区別する', () {
    final result = combined.run(
      repeated({
        40: 1,
        60: 1,
      }, defender: combined.defender(item: ItemId.sitrusBerry)),
    );
    expect(result.ko.possibleHits, 2);
    expect(result.ko.guaranteedHits, 4);
    expect(result.ko.category, KoCategory.fourHits);
    expect(result.finalHp.weights, {0: BigInt.from(16)});
    expect(result.knockout.guaranteed, isTrue);
    expect(result.finalStates.any((s) => s.state.itemConsumed), isTrue);
    expect(result.finalStates.any((s) => !s.state.itemConsumed), isTrue);
  });

  test('致死ダメージではオボンを消費しない', () {
    final result = combined.run(
      repeated({100: 1}, defender: combined.defender(item: ItemId.sitrusBerry)),
    );
    expect(result.ko.guaranteedHits, 1);
    expect(result.finalStates.single.state.currentHp, 0);
    expect(result.finalStates.single.state.itemConsumed, isFalse);
  });

  test('初撃用と後続用の分布を固定して使う', () {
    final result = combined.run(repeated({20: 1}, subsequent: {40: 1}));
    expect(result.ko.possibleHits, 3);
    expect(result.ko.guaranteedHits, 3);
    expect(result.attackDamage.weights, {BigInt.from(100): BigInt.one});
    expect(result.finalHp.weights, {0: BigInt.one});
  });

  test('初撃が外れても後続用の分布へ進む', () {
    final result = combined.run(
      repeated(
        {100: 1},
        subsequent: {0: 1},
        hitCounts: {0: BigInt.one, 1: BigInt.one},
      ),
    );
    expect(result.ko.guaranteedHits, 1);
    expect(result.knockout.weight, BigInt.from(8));
    expect(result.knockout.totalWeight, BigInt.from(16));
    expect(result.finalHp.weights, {0: BigInt.from(8), 100: BigInt.from(8)});
  });

  test('反復は1回1ターンとして終了時回復を反映する', () {
    final result = combined.run(
      repeated({50: 1}, defender: combined.defender(item: ItemId.leftovers)),
    );
    expect(result.ko.guaranteedHits, 3);
    expect(result.attackDamage.weights, {BigInt.from(150): BigInt.one});
    expect(result.finalHp.weights, {0: BigInt.one});
  });

  test('初期処理は反復開始時に一度だけ適用する', () {
    final result = combined.run(
      repeated(
        {10: 1},
        subsequent: {0: 1},
        setup: BattleSetupDto(initialDamages: [10]),
      ),
    );
    expect(result.finalHp.weights, {80: BigInt.one});
    expect(result.attackDamage.weights, {BigInt.from(10): BigInt.one});
  });

  test('攻撃前撃破を確定0発として区別する', () {
    final result = combined.run(
      repeated({20: 1}, setup: BattleSetupDto(initialDamages: [100])),
    );
    expect(result.ko.status, KoStatus.resolved);
    expect(result.ko.possibleHits, 0);
    expect(result.ko.guaranteedHits, 0);
    expect(result.ko.category, KoCategory.alreadyKnockedOut);
    expect(result.attackDamage.weights, {BigInt.from(0): BigInt.one});
  });

  test('短い攻撃列の未確定を5発以上と誤表示しない', () {
    final result = combined.run(
      combined.request([
        combined.attack(
          [
            combined.distribution({20: 1}),
          ],
          conditional: {1: 1},
        ),
      ]),
    );
    expect(result.ko.evaluatedAttacks, 1);
    expect(result.ko.guaranteedHits, isNull);
    expect(result.ko.category, KoCategory.undetermined);
    expect(result.finalHp.weights, {80: BigInt.one});
  });

  test('明示した5回以上の攻撃列も正確な回数を保持する', () {
    final result = combined.run(
      combined.request([
        for (var turn = 1; turn <= 6; turn++)
          combined.attack(
            [
              combined.distribution({20: 1}),
            ],
            turn: turn,
            conditional: {1: 1},
          ),
      ]),
    );
    expect(result.ko.evaluatedAttacks, 6);
    expect(result.ko.status, KoStatus.resolved);
    expect(result.ko.possibleHits, 5);
    expect(result.ko.guaranteedHits, 5);
    expect(result.ko.category, KoCategory.fiveOrMore);
    expect(result.attackDamage.weights, {BigInt.from(100): BigInt.one});
  });

  test('連続技は攻撃列で扱い確定数は技の使用回数で数える', () {
    final result = combined.run(
      combined.request([
        for (var turn = 1; turn <= 2; turn++)
          combined.attack(
            [
              combined.distribution({20: 1}),
              combined.distribution({30: 1}),
            ],
            turn: turn,
            conditional: {2: 1},
          ),
      ]),
    );
    expect(result.ko.guaranteedHits, 2);
    expect(result.ko.category, KoCategory.twoHits);
    expect(result.attackDamage.weights, {BigInt.from(100): BigInt.one});
  });

  test('ヒットごとに命中判定する連続技は確定数対象外を維持する', () {
    final result = combined.run(
      combined.request([
        combined.attack(
          [
            combined.distribution({20: 1}),
            combined.distribution({30: 1}),
          ],
          counts: {0: 1, 1: 1, 2: 1},
        ),
      ]),
    );
    expect(result.ko.status, KoStatus.notApplicable);
    expect(result.ko.category, KoCategory.notApplicable);
    expect(result.finalHp.weights, {
      100: BigInt.one,
      80: BigInt.one,
      50: BigInt.one,
    });
  });

  test('反復入力と明示した4回分の攻撃列は一致する', () {
    final first = combined.distribution({10: 1, 20: 2});
    final subsequent = combined.distribution({20: 1, 40: 3});
    final pokemon = combined.defender(
      item: ItemId.sitrusBerry,
      status: Status.toxic,
      toxicCounter: 1,
    );
    final setup = BattleSetupDto(initialDamages: [5]);
    final counts = {0: BigInt.one, 1: BigInt.from(3)};
    final expanded = combined.run(
      CombinedDamageRequestDto.repeatSingleHit(
        firstHit: first,
        subsequentHit: subsequent,
        hitCounts: counts,
        defender: pokemon,
        field: BattleFieldDto(format: BattleFormat.single),
        setup: setup,
      ),
    );
    final explicit = combined.run(
      combined.request(
        [
          for (var turn = 1; turn <= 4; turn++)
            AttackDto(
              turn: turn,
              hits: [turn == 1 ? first : subsequent],
              hitCounts: counts,
              conditionalHitCounts: {1: BigInt.one},
            ),
        ],
        pokemon: pokemon,
        setup: setup,
      ),
    );
    expect(expanded.finalHp.weights, explicit.finalHp.weights);
    expect(expanded.attackDamage.weights, explicit.attackDamage.weights);
    expect(expanded.knockout.weight, explicit.knockout.weight);
    expect(expanded.knockout.totalWeight, explicit.knockout.totalWeight);
    expect(expanded.ko.status, explicit.ko.status);
    expect(expanded.ko.possibleHits, explicit.ko.possibleHits);
    expect(expanded.ko.guaranteedHits, explicit.ko.guaranteedHits);
    expect(expanded.ko.category, explicit.ko.category);
    expect(
      [
        for (final s in expanded.finalStates)
          (
            s.state.currentHp,
            s.state.itemConsumed,
            s.state.toxicCounter,
            s.weight,
          ),
      ],
      [
        for (final s in explicit.finalStates)
          (
            s.state.currentHp,
            s.state.itemConsumed,
            s.state.toxicCounter,
            s.weight,
          ),
      ],
    );
  });

  test('反復入力は不変な攻撃列へ展開し往復でも等価になる', () {
    final first = combined.distribution({20: 1});
    final next = combined.distribution({30: 1});
    final counts = {0: BigInt.one, 1: BigInt.two};
    final dto = CombinedDamageRequestDto.repeatSingleHit(
      firstHit: first,
      subsequentHit: next,
      hitCounts: counts,
      defender: combined.defender(),
      field: BattleFieldDto(format: BattleFormat.single),
      setup: BattleSetupDto.none,
    );
    counts.clear();
    expect(dto.attacks.map((a) => a.turn), [1, 2, 3, 4]);
    expect(dto.attacks.map((a) => a.hits.single), [first, next, next, next]);
    expect(dto.attacks.last.hitCounts, {0: BigInt.one, 1: BigInt.two});
    expect(() => dto.attacks.clear(), throwsUnsupportedError);
    expect(() => dto.attacks.first.hitCounts.clear(), throwsUnsupportedError);
    final request =
        (CombinedDamageRequest.fromDto(dto) as Valid<CombinedDamageRequest>)
            .value;
    final copy =
        (CombinedDamageRequest.fromDto(request.toDto)
                as Valid<CombinedDamageRequest>)
            .value;
    expect(copy, request);
    expect(copy.hashCode, request.hashCode);
  });

  test('反復入力の不正な分布と命中重みは既存の位置で検証する', () {
    final cases = [
      (
        repeated({}),
        'combinedDamageRequest.attacks[0].hits[0]',
        ValidationCode.required,
      ),
      (
        repeated({-1: 1}),
        'combinedDamageRequest.attacks[0].hits[0][-1].damage',
        ValidationCode.outOfRange,
      ),
      (
        repeated({20: 1}, subsequent: {20: 0}),
        'combinedDamageRequest.attacks[1].hits[0][20].weight',
        ValidationCode.outOfRange,
      ),
      (
        repeated({20: 1}, hitCounts: {}),
        'combinedDamageRequest.attacks[0].hitCounts',
        ValidationCode.required,
      ),
      (
        repeated({20: 1}, hitCounts: {2: BigInt.one}),
        'combinedDamageRequest.attacks[0].hitCounts[2]',
        ValidationCode.outOfRange,
      ),
      (
        repeated({20: 1}, hitCounts: {1: BigInt.zero}),
        'combinedDamageRequest.attacks[0].hitCounts[1].weight',
        ValidationCode.outOfRange,
      ),
    ];
    for (final (dto, path, code) in cases) {
      final result =
          CombinedDamageRequest.fromDto(dto) as Invalid<CombinedDamageRequest>;
      expect(result.errors, contains(ValidationError(path, code)));
    }
  });

  test('反復入力も共有計算量制限を使い途中結果を返さない', () {
    for (final limits in [
      const CalculationLimitsDto(maxOperations: 1),
      const CalculationLimitsDto(maxStates: 1),
    ]) {
      final dto = repeated({1: 1, 2: 1}, limits: limits);
      final request =
          (CombinedDamageRequest.fromDto(dto) as Valid<CombinedDamageRequest>)
              .value;
      final result =
          calculateCombinedDamage(request) as Failure<CombinedDamageResult>;
      expect(result.kind, FailureKind.complexityExceeded);
      expect(result.path, 'distribution');
    }
  });
}
