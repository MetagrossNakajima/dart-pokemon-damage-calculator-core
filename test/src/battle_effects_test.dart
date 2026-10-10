import '../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import '../support/effects_fixtures.dart' as effects;
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../support/effect_regressions_fixtures.dart' as regressions;

void main() {
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
