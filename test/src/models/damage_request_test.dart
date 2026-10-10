import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;
import '../../support/input_adapter.dart' as adapter;
import '../../support/domain_model_materialization_fixtures.dart'
    as materialization;
import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import '../../support/pokemon_patch.dart';
import '../../support/calculator_fixtures.dart' as calculator;
import '../../support/effects_fixtures.dart' as effects;

void main() {
  {
    test('単発リクエストは子モデルと境界値を一度だけ生成して保持する', () {
      final request = materialization.value(
        DamageRequest.fromDto(
          DamageRequestDto(
            attacker: materialization.makePokemon(),
            defender: materialization.makePokemon(),
            move: materialization.move(),
            field: materialization.field(),
            critical: true,
            hitIndex: 2,
          ),
        ),
      );
      final pokemon = request.attacker;
      expect(request.attacker, same(pokemon));
      expect(request.defender, same(request.defender));
      expect(request.move, same(request.move));
      expect(request.field, same(request.field));
      expect(pokemon.profile, same(pokemon.profile));
      expect(pokemon.stats, same(pokemon.stats));
      expect(pokemon.stages, same(pokemon.stages));
      expect(pokemon.profile.weight, same(pokemon.profile.weight));
      expect(pokemon.currentHp, same(pokemon.currentHp));
      expect(pokemon.toxicCounter, same(pokemon.toxicCounter));
      expect(pokemon.cudChewTurn, same(pokemon.cudChewTurn));
      expect(pokemon.faintedAllies, same(pokemon.faintedAllies));
      expect(pokemon.timesHit, same(pokemon.timesHit));
      for (final stat in Stat.values) {
        expect(pokemon.stats[stat], same(pokemon.stats[stat]));
        expect(pokemon.stats[stat].value, materialization.stats[stat]);
        expect(pokemon.stages[stat], same(pokemon.stages[stat]));
      }
      expect(
        pokemon.id,
        materialization.value(PokemonId.create('materialization')),
      );
      expect(pokemon.types, [PokemonType.fire, PokemonType.flying]);
      expect(pokemon.weight, same(pokemon.profile.weight));
      expect(pokemon.weight.value, 999.9);
      expect(pokemon.gender, Gender.female);
      expect(pokemon.reflect, isTrue);
      expect(pokemon.lightScreen, isTrue);
      expect(pokemon.currentHp!.value, 1);
      expect(pokemon.toxicCounter!.value, 15);
      expect(pokemon.cudChewTurn!.value, -1);
      expect(pokemon.faintedAllies.value, 100);
      expect(pokemon.timesHit.value, 100);
      expect(pokemon.stages.atk.value, -6);
      expect(pokemon.stages.def.value, 6);
      expect(request.move.power, same(request.move.power));
      expect(request.move.power.value, 1000);
      expect(request.move.priority, same(request.move.priority));
      expect(request.move.priority.value, -7);
      expect(request.field.format, BattleFormat.double);
      expect(request.field.weather, Weather.rain);
      expect(request.field.gravity, isTrue);
      expect(request.field.terrain, Terrain.electric);
      expect(request.critical, isTrue);
      expect(request.hitIndex, 2);
      final roundTrip = materialization.value(
        DamageRequest.fromDto(request.toDto),
      );
      expect(roundTrip, request);
      expect(roundTrip.hashCode, request.hashCode);
      expect(request.attacker, same(pokemon));
      expect(() => pokemon.types.clear(), throwsUnsupportedError);
      expect(() => pokemon.flags.clear(), throwsUnsupportedError);
      expect(() => request.move.flags.clear(), throwsUnsupportedError);
      expect(() => request.field.effects.clear(), throwsUnsupportedError);
    });

    test('不正な子モデルを構築せず独立したエラーを元の順番で集約する', () {
      final request =
          CombinedDamageRequest.fromDto(
                CombinedDamageRequestDto(
                  attacks: [
                    AttackDto(
                      turn: 0,
                      hits: [
                        DamageDistribution({-1: BigInt.zero, 1: -BigInt.one}),
                      ],
                      hitCounts: {2: BigInt.zero},
                      conditionalHitCounts: {0: BigInt.one},
                    ),
                  ],
                  defender: materialization.makePokemon(detailed: false),
                  field: materialization.field(),
                  setup: BattleSetupDto(
                    initialDamages: [-1],
                    entryHazards: const EntryHazardsDto(spikesLayers: 4),
                  ),
                  limits: const CalculationLimitsDto(
                    maxOperations: 0,
                    maxStates: 0,
                  ),
                ),
              )
              as Invalid<CombinedDamageRequest>;
      expect(request.errors, [
        const ValidationError(
          'combinedDamageRequest.attacks[0].turn',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.attacks[0].hits[0][-1].damage',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.attacks[0].hits[0][-1].weight',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.attacks[0].hits[0][1].weight',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.attacks[0].hitCounts[2]',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.attacks[0].hitCounts[2].weight',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.attacks[0].conditionalHitCounts[0]',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.attacks[0].turn',
          ValidationCode.inconsistent,
        ),
        const ValidationError(
          'combinedDamageRequest.setup.initialDamages[0]',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.setup.entryHazards.spikesLayers',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.limits.maxOperations',
          ValidationCode.outOfRange,
        ),
        const ValidationError(
          'combinedDamageRequest.limits.maxStates',
          ValidationCode.outOfRange,
        ),
      ]);
      expect(DamageWeights.create({}), isA<Invalid<DamageWeights>>());
    });
  }
  {
    test('new input validation and override fields', () {
      for (final p in [
        effects.p(hp: 0),
        effects.p(hp: 201),
        effects.p(fainted: -1),
        effects.p(fainted: 101),
        effects.p(timesHit: -1),
        effects.p(timesHit: 101),
        effects.p(boosted: Stat.hp),
      ]) {
        calculator.failure(
          adapter.calculateDamage(
            DamageRequestDto(
              attacker: p,
              defender: effects.p(),
              move: effects.m(),
              field: effects.f(),
            ),
          ),
          adapter.FailureKind.invalidInput,
        );
      }
      final base = effects.p(
        hp: 50,
        tera: 'Water',
        boosted: Stat.def,
        flags: {PokemonFlag.grounded: true},
      );
      final modified = PokemonPatch(
        currentHp: const Replacement(null),
        teraType: const Replacement(null),
        boostedStat: const Replacement(null),
        gender: Gender.female,
        faintedAllies: 2,
        timesHit: 3,
        flags: {PokemonFlag.grounded: false},
      ).apply(base);
      expect(modified.currentHp, isNull);
      expect(modified.teraType, isNull);
      expect(modified.boostedStat, isNull);
      expect(modified.gender, Gender.female);
      expect(modified.faintedAllies, 2);
      expect(modified.timesHit, 3);
      expect(modified.flags[PokemonFlag.grounded], false);
      final flags = <PokemonFlag, bool>{PokemonFlag.charge: true};
      final immutable = effects.p(flags: flags);
      flags.clear();
      expect(immutable.flags[PokemonFlag.charge], true);
      expect(() => immutable.flags.clear(), throwsUnsupportedError);
      final moveFlags = {MoveFlag.contact};
      final move = effects.m(flags: moveFlags);
      moveFlags.clear();
      expect(move.flags, {MoveFlag.contact});
      final fieldFlags = {FieldEffect.helpingHand};
      final field = effects.f(effects: fieldFlags);
      fieldFlags.clear();
      expect(field.effects, {FieldEffect.helpingHand});
    });
  }
  for (final detailed in [false, true]) {
    test('DamageRequestの往復と値による等価性 / $detailed', () {
      final p = domain.pokemon(detailed: detailed);
      final r = DamageRequestDto(
        attacker: p,
        defender: p,
        move: domain.move(),
        field: domain.field(),
      );
      domain.equality(
        valid(DamageRequest.fromDto(r)),
        valid(DamageRequest.fromDto(r)),
      );
    });
  }
}
