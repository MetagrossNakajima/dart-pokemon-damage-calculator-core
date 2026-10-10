import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;
import '../../support/input_adapter.dart' show pokemonId, moveId;
import '../../support/domain_model_materialization_fixtures.dart'
    as materialization;

void main() {
  {
    test('任意値がない状態もDTO往復で保持する', () {
      final pokemon = materialization.value(
        PokemonState.fromDto(materialization.makePokemon(detailed: false)),
      );
      expect(pokemon.ability, isNull);
      expect(pokemon.item, isNull);
      expect(pokemon.currentHp, isNull);
      expect(pokemon.toxicCounter, isNull);
      expect(pokemon.cudChewTurn, isNull);
      expect(pokemon.teraType, isNull);
      expect(pokemon.status, isNull);
      expect(pokemon.boostedStat, isNull);
      expect(pokemon.reflect, isFalse);
      expect(pokemon.lightScreen, isFalse);
      expect(pokemon.itemConsumed, isFalse);
      final roundTrip = materialization.value(
        PokemonState.fromDto(pokemon.toDto),
      );
      expect(roundTrip, pokemon);
      expect(roundTrip.hashCode, pokemon.hashCode);
    });
  }
  {
    test('独立したエラーを入力順に集約し、依存する比較を省く', () {
      final bad = PokemonStateDto(
        profile: PokemonProfileDto(
          id: pokemonId('test'),
          types: [PokemonType.normal, PokemonType.normal, PokemonType.fire],
          weight: double.nan,
        ),
        stats: const StatsDto(
          hp: 0,
          atk: 0,
          def: 100,
          spa: 100,
          spd: 100,
          spe: 100,
        ),
        stages: const StatStagesDto(atk: 7),
        ability: null,
        item: null,
        currentHp: 2,
        status: Status.toxic,
        boostedStat: Stat.hp,
        faintedAllies: -1,
        timesHit: 101,
      );
      final result = PokemonState.fromDto(bad) as Invalid<PokemonState>;
      expect(result.errors.map((e) => e.path), [
        'pokemonState.profile.types',
        'pokemonState.profile.types',
        'pokemonState.profile.weight',
        'pokemonState.stats.hp',
        'pokemonState.stats.atk',
        'pokemonState.stages.atk',
        'pokemonState.toxicCounter',
        'pokemonState.boostedStat',
        'pokemonState.faintedAllies',
        'pokemonState.timesHit',
      ]);
      final source = DamageRequestDto(
        attacker: bad,
        defender: bad,
        move: MoveDto(
          id: moveId('test'),
          type: PokemonType.normal,
          power: -1,
          category: Category.physical,
        ),
        field: BattleFieldDto(format: BattleFormat.single),
      );
      final request = DamageRequest.fromDto(source) as Invalid<DamageRequest>;
      expect(request.errors.length, greaterThan(20));
      expect(request.errors.last.path, 'damageRequest.move.power');
    });

    test('大きな最大HP・現在HPを合算でも受け付ける', () {
      final largeStats = StatsDto(
        hp: 2000000,
        atk: 100,
        def: 100,
        spa: 100,
        spd: 100,
        spe: 100,
      );
      final p = valid(
        PokemonState.fromDto(
          PokemonStateDto(
            profile: domain.pokemon().profile,
            stats: largeStats,
            currentHp: 1500000,
          ),
        ),
      );
      expect(p.stats.hp.value, 2000000);
      expect(p.currentHp!.value, 1500000);
      final request = valid(
        CombinedDamageRequest.fromDto(
          CombinedDamageRequestDto.repeatSingleHit(
            firstHit: DamageDistribution({2000000: BigInt.one}),
            defender: p.toDto,
            field: BattleFieldDto(format: BattleFormat.single),
            setup: BattleSetupDto.none,
          ),
        ),
      );
      expect(
        (calculateCombinedDamage(request) as Success<CombinedDamageResult>)
            .value
            .ko
            .guaranteedHits,
        1,
      );
      final tooHigh = PokemonStateDto(
        profile: domain.pokemon().profile,
        stats: largeStats,
        currentHp: 2000001,
      );
      expect(PokemonState.fromDto(tooHigh), isA<Invalid<PokemonState>>());
    });
  }
  for (final detailed in [false, true]) {
    test('PokemonStateの往復と値による等価性 / $detailed', () {
      final p = domain.pokemon(detailed: detailed);
      domain.equality(
        valid(PokemonState.fromDto(p)),
        valid(PokemonState.fromDto(domain.pokemon(detailed: detailed))),
      );
    });
  }
}
