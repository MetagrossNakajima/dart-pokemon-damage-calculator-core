import '../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import 'package:pokemon_damage_calculator_core/src/battle_effects.dart'
    as battle;
import '../support/effects_fixtures.dart' as effects;
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../support/effect_regressions_fixtures.dart' as regressions;

void main() {
  group('issue #44 Neutralizing Gas', () {
    const exceptions = [
      AbilityId.asOneGlastrier,
      AbilityId.asOneSpectrier,
      AbilityId.battleBond,
      AbilityId.comatose,
      AbilityId.disguise,
      AbilityId.gulpMissile,
      AbilityId.iceFace,
      AbilityId.multitype,
      AbilityId.neutralizingGas,
      AbilityId.powerConstruct,
      AbilityId.rksSystem,
      AbilityId.schooling,
      AbilityId.shieldsDown,
      AbilityId.stanceChange,
      AbilityId.teraShift,
      AbilityId.zenMode,
      AbilityId.zerotoHero,
    ];
    test(
      'gas exceptions survive both sources and explicit suppression wins',
      () {
        for (final ability in exceptions) {
          for (final fieldGas in [false, true]) {
            final field =
                (BattleField.fromDto(
                          regressions.defaultField(
                            effects: fieldGas
                                ? {FieldEffect.neutralizingGas}
                                : {},
                          ),
                        )
                        as Valid<BattleField>)
                    .value;
            final opponent =
                (PokemonState.fromDto(
                          regressions.pokemon(
                            ability: AbilityId.neutralizingGas,
                          ),
                        )
                        as Valid<PokemonState>)
                    .value;
            for (final suppressed in [false, true]) {
              final pokemon =
                  (PokemonState.fromDto(
                            regressions.pokemon(
                              ability: ability,
                              flags: {
                                PokemonFlag.abilitySuppressed: suppressed,
                              },
                            ),
                          )
                          as Valid<PokemonState>)
                      .value;
              expect(
                battle.activeAbility(
                  pokemon,
                  field,
                  opponent: fieldGas ? null : opponent,
                ),
                suppressed ? null : ability,
                reason: ability.value,
              );
            }
            final shielded =
                (PokemonState.fromDto(
                          regressions.pokemon(
                            ability: ability,
                            item: ItemId.abilityShield,
                            flags: {PokemonFlag.abilitySuppressed: true},
                          ),
                        )
                        as Valid<PokemonState>)
                    .value;
            expect(
              battle.activeAbility(
                shielded,
                field,
                opponent: fieldGas ? null : opponent,
              ),
              ability,
            );
          }
        }
      },
    );
    test('As One blocks Occa Berry under either gas source', () {
      for (final ability in ['AsOneGlastrier', 'AsOneSpectrier']) {
        for (final fieldGas in [false, true]) {
          final hit = effects.hit(
            a: effects.p(ability: ability),
            d: effects.p(
              types: ['Grass'],
              item: 'OccaBerry',
              ability: fieldGas ? null : 'NeutralizingGas',
            ),
            move: effects.m(
              id: 'Flamethrower',
              type: 'Fire',
              power: 90,
              category: Category.special,
            ),
            field: effects.f(
              effects: fieldGas ? {FieldEffect.neutralizingGas} : {},
            ),
          );
          expect(hit.rolls, [
            68,
            70,
            70,
            72,
            72,
            72,
            74,
            74,
            76,
            76,
            76,
            78,
            78,
            80,
            80,
            82,
          ]);
          expect(hit.trace.where((t) => t.id == 'OccaBerry'), isEmpty);
        }
      }
    });
    test('Hex doubles against Comatose under either gas source', () {
      for (final fieldGas in [false, true]) {
        final hit = effects.hit(
          a: effects.p(ability: fieldGas ? null : 'NeutralizingGas'),
          d: effects.p(types: ['Psychic'], ability: 'Comatose'),
          move: effects.m(
            id: 'Hex',
            type: 'Ghost',
            power: 65,
            category: Category.special,
          ),
          field: effects.f(
            effects: fieldGas ? {FieldEffect.neutralizingGas} : {},
          ),
        );
        expect(hit.power, 130);
        expect(hit.rolls, [
          100,
          100,
          102,
          102,
          104,
          106,
          106,
          108,
          108,
          110,
          112,
          112,
          114,
          114,
          116,
          118,
        ]);
      }
    });
  });
  {
    test('suppression, ability shield, magic room and Klutz', () {
      expect(
        effects
            .hit(
              a: effects.p(ability: 'HugePower'),
              d: effects.p(ability: 'NeutralizingGas'),
            )
            .attack,
        100,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'HugePower', item: 'AbilityShield'),
              d: effects.p(ability: 'NeutralizingGas'),
            )
            .attack,
        200,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'HugePower'),
              field: effects.f(effects: {FieldEffect.neutralizingGas}),
            )
            .attack,
        100,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'HugePower', item: 'AbilityShield'),
              field: effects.f(
                effects: {FieldEffect.neutralizingGas, FieldEffect.magicRoom},
              ),
            )
            .attack,
        100,
      );
      expect(
        effects
            .hit(
              a: effects.p(
                item: 'ChoiceBand',
                flags: {PokemonFlag.itemSuppressed: true},
              ),
            )
            .attack,
        100,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'Klutz', item: 'ChoiceBand'),
            )
            .attack,
        100,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'MoldBreaker'),
              d: effects.p(ability: 'BattleArmor', item: 'AbilityShield'),
              crit: true,
            )
            .critical,
        false,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'NeutralizingGas'),
              d: effects.p(ability: 'BattleArmor'),
              crit: true,
            )
            .critical,
        true,
      );
    });
  }
  {
    group('Ability ignoring only removes the explicit ignorable abilities', () {
      for (final ability in [
        null,
        AbilityId.moldBreaker,
        AbilityId.teravolt,
        AbilityId.turboblaze,
      ]) {
        test(
          '${ability?.value ?? "No ability"} preserves Ripen and the Occa Berry quarter modifier',
          () {
            // Ripen is absent from gen789.ts defenderAbilityIgnored; 2x weak *1/4.
            regressions.expectRolls(
              regressions.damage(
                attacker: regressions.pokemon(ability: ability),
                defender: regressions.pokemon(
                  types: [PokemonType.grass],
                  ability: AbilityId.ripen,
                  item: ItemId.occaBerry,
                ),
                type: PokemonType.fire,
              ),
              regressions.ripenRolls,
            );
          },
        );
      }

      test(
        'Ripen suppression and Neutralizing Gas leave the ordinary Occa modifier',
        () {
          for (final suppressed in [true, false]) {
            regressions.expectRolls(
              regressions.damage(
                attacker: regressions.pokemon(ability: AbilityId.moldBreaker),
                defender: regressions.pokemon(
                  types: [PokemonType.grass],
                  ability: AbilityId.ripen,
                  item: ItemId.occaBerry,
                  flags: {PokemonFlag.abilitySuppressed: suppressed},
                ),
                type: PokemonType.fire,
                field: regressions.defaultField(
                  effects: suppressed ? {} : {FieldEffect.neutralizingGas},
                ),
              ),
              regressions.neutralRolls,
            );
          }
        },
      );

      test(
        'Ability Shield protects Wonder Guard from Mold Breaker and gas',
        () {
          for (final effects in [
            <FieldEffect>{},
            {FieldEffect.neutralizingGas},
          ]) {
            regressions.expectRolls(
              regressions.damage(
                attacker: regressions.pokemon(ability: AbilityId.moldBreaker),
                defender: regressions.pokemon(
                  ability: AbilityId.wonderGuard,
                  item: ItemId.abilityShield,
                ),
                field: regressions.defaultField(effects: effects),
              ),
              List.filled(16, 0),
            );
          }
          regressions.expectRolls(
            regressions.damage(
              attacker: regressions.pokemon(ability: AbilityId.moldBreaker),
              defender: regressions.pokemon(ability: AbilityId.wonderGuard),
            ),
            regressions.neutralRolls,
          );
          regressions.expectRolls(
            regressions.damage(
              defender: regressions.pokemon(
                ability: AbilityId.wonderGuard,
                item: ItemId.abilityShield,
                flags: {PokemonFlag.itemSuppressed: true},
              ),
              field: regressions.defaultField(
                effects: {FieldEffect.neutralizingGas},
              ),
            ),
            regressions.neutralRolls,
          );
          regressions.expectRolls(
            regressions.damage(
              attacker: regressions.pokemon(ability: AbilityId.moldBreaker),
              defender: regressions.pokemon(
                ability: AbilityId.wonderGuard,
                item: ItemId.abilityShield,
                flags: {PokemonFlag.abilitySuppressed: true},
              ),
            ),
            List.filled(16, 0),
          );
          regressions.expectRolls(
            regressions.damage(
              attacker: regressions.pokemon(ability: AbilityId.moldBreaker),
              defender: regressions.pokemon(
                ability: AbilityId.wonderGuard,
                item: ItemId.abilityShield,
                itemConsumed: true,
              ),
            ),
            regressions.neutralRolls,
          );
        },
      );
    });
  }
}
