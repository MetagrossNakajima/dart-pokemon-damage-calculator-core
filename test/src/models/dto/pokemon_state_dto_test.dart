import '../../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import '../../../support/calculator_fixtures.dart' as calculator;
import '../../../support/pokemon_patch.dart';
import '../../../support/effects_fixtures.dart' as effects;
import '../../../support/value_objects_fixtures.dart' show valid;

void main() {
  {
    test('input collections copied and never modified', () {
      final types = [PokemonType.normal];
      final stats = calculator.values(100);
      final ranks = {Stat.atk: 1};
      final p = PokemonStateDto(
        profile: PokemonProfileDto(id: pokemonId('x'), types: types, weight: 1),
        stats: StatsDto.fromMap(stats),
        stages: StatStagesDto.fromMap(ranks),
      );
      types.clear();
      stats.clear();
      ranks.clear();
      expect(p.types, [PokemonType.normal]);
      expect(p.stats.length, 6);
      expect(p.stages[Stat.atk], 1);
      dynamic unrelatedKey = 'atk';
      expect(p.stats[unrelatedKey], isNull);
      expect(p.stages[Stat.hp], isNull);
      calculator.damage(a: p);
      expect(p.stages[Stat.atk], 1);
      expect(() => p.profile.types.clear(), throwsUnsupportedError);
      expect(() => p.stats[Stat.atk] = 2, throwsUnsupportedError);
      expect(() => p.stats.clear(), throwsUnsupportedError);
      expect(() => p.stats.remove(Stat.atk), throwsUnsupportedError);
      expect(() => p.stages[Stat.atk] = 2, throwsUnsupportedError);
      expect(() => p.stages.clear(), throwsUnsupportedError);
      expect(() => p.stages.remove(Stat.atk), throwsUnsupportedError);
    });
  }
  {
    test(
      'typed partial updates distinguish omitted cleared and replaced IDs',
      () {
        final original = effects.p(ability: 'Pressure', item: 'Leftovers');
        final keep = PokemonPatch().apply(original);
        expect(keep.ability, AbilityId.pressure);
        expect(keep.item, ItemId.leftovers);
        final clear = PokemonPatch(
          ability: const Replacement<AbilityId?>(null),
          item: const Replacement<ItemId?>(null),
        ).apply(original);
        expect(clear.ability, isNull);
        expect(clear.item, isNull);
        final future = valid(AbilityId.create('FutureAbility'));
        final replaced = PokemonPatch(
          ability: Replacement(future),
          item: const Replacement(ItemId.choiceBand),
        ).apply(original);
        expect(replaced.ability, future);
        expect(replaced.item, ItemId.choiceBand);
        final snapshot = BattleState.fromDto(replaced);
        expect(snapshot.ability, future);
        expect(snapshot.item, ItemId.choiceBand);
      },
    );
  }
}
