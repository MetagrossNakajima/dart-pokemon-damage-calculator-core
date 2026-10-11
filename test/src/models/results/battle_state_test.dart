import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../../support/value_objects_fixtures.dart' show valid;
import '../../../support/input_adapter.dart' show pokemonId;
import '../../../support/domain_models_fixtures.dart' as domain;

void main() {
  test('撃破後の出力は防御条件とHP0を保持する', () {
    final defender = domain.pokemon(detailed: true);
    final request = valid(
      CombinedDamageRequest.fromDto(
        CombinedDamageRequestDto(
          defender: defender,
          field: domain.field(),
          setup: BattleSetupDto.none,
          attacks: [
            AttackDto(
              turn: 1,
              hits: [
                DamageDistribution({250: BigInt.one, 300: BigInt.one}),
              ],
              hitCounts: {1: BigInt.one},
            ),
          ],
        ),
      ),
    );
    final result =
        (calculateCombinedDamage(request) as Success<CombinedDamageResult>)
            .value;
    expect(result.min, BigInt.from(250));
    expect(result.max, BigInt.from(300));
    expect(result.knockout.guaranteed, isTrue);
    expect(result.knockout.probability, 1);
    expect(result.finalHp.weights, {0: BigInt.two});
    for (final branch in result.finalStates) {
      final state = branch.state;
      expect(state.currentHp, 0);
      expect(
        valid(PokemonProfile.fromDto(state.profile)),
        request.defender.profile,
      );
      expect(state.stats, defender.stats);
      expect(state.stages, defender.stages);
      expect(state.ability, AbilityId.skillLink);
      expect(state.item, ItemId.utilityUmbrella);
      expect(state.status, Status.toxic);
      expect(
        state.sideConditions,
        const SideConditions(reflect: true, lightScreen: true),
      );
      expect(state.toxicCounter, 2);
      expect(state.itemConsumed, isFalse);
      expect(state.cudChewTurn, -1);
      expect(state.teraType, TeraType.stellar);
      expect(state.boostedStat, Stat.spa);
      expect(state.faintedAllies, 2);
      expect(state.timesHit, 3);
      expect(state.flags, {
        PokemonFlag.grounded: true,
        PokemonFlag.charge: false,
      });
      expect(state.id, pokemonId('test'));
      expect(state.types, [PokemonType.normal, PokemonType.water]);
      expect(state.weight, 50);
      expect(state.gender, Gender.genderless);
      expect(state.reflect, isTrue);
      expect(state.lightScreen, isTrue);
      expect(() => state.types.clear(), throwsUnsupportedError);
      expect(() => state.flags.clear(), throwsUnsupportedError);
    }
    expect(() => result.finalStates.clear(), throwsUnsupportedError);
    final partial = KnockoutProbability(BigInt.from(7), BigInt.from(10));
    expect(partial.guaranteed, isFalse);
    expect(partial.probability, 0.7);
  });
}
