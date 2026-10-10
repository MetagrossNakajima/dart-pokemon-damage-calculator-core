import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;
import '../../support/domain_model_materialization_fixtures.dart'
    as materialization;

void main() {
  {
    test('合算リクエストは攻撃列と分布を一度だけ生成して保持する', () {
      final request = materialization.value(
        CombinedDamageRequest.fromDto(
          CombinedDamageRequestDto(
            defender: materialization.makePokemon(),
            field: materialization.field(),
            setup: BattleSetupDto(
              entryHazards: const EntryHazardsDto(
                stealthRock: true,
                spikesLayers: 3,
              ),
              initialDamages: [0, 7],
            ),
            limits: const CalculationLimitsDto(maxOperations: 1, maxStates: 1),
            attacks: [
              AttackDto(
                turn: 1,
                hits: [
                  DamageDistribution({7: BigInt.two, 0: BigInt.one}),
                  DamageDistribution({11: BigInt.one}),
                ],
                hitCounts: {0: BigInt.one, 2: BigInt.two},
                conditionalHitCounts: {2: BigInt.one},
              ),
              AttackDto(
                turn: 2,
                hits: [
                  DamageDistribution({13: BigInt.one}),
                ],
                hitCounts: {1: BigInt.one},
              ),
            ],
          ),
        ),
      );
      expect(request.defender, same(request.defender));
      expect(request.field, same(request.field));
      expect(request.setup, same(request.setup));
      expect(request.limits, same(request.limits));
      expect(request.attacks, same(request.attacks));
      final attack = request.attacks.first;
      expect(attack, same(request.attacks.first));
      expect(attack.turn, same(attack.turn));
      expect(attack.turn.value, 1);
      expect(attack.hits, same(attack.hits));
      expect(attack.hits.first, same(attack.hits.first));
      expect(attack.hits.first.min, 0);
      expect(attack.hits.first.max, 7);
      expect(attack.hits.first.totalWeight, BigInt.from(3));
      expect(attack.hitCounts, {0: BigInt.one, 2: BigInt.two});
      expect(attack.conditionalHitCounts, {2: BigInt.one});
      expect(request.attacks.last.conditionalHitCounts, isNull);
      expect(request.setup.entryHazards, same(request.setup.entryHazards));
      expect(
        request.setup.entryHazards.spikesLayers,
        same(request.setup.entryHazards.spikesLayers),
      );
      expect(request.setup.entryHazards.stealthRock, isTrue);
      expect(request.setup.entryHazards.spikesLayers.value, 3);
      expect(request.setup.initialDamages, [0, 7]);
      expect(request.limits.maxOperations, same(request.limits.maxOperations));
      expect(request.limits.maxStates, same(request.limits.maxStates));
      expect(request.limits.maxOperations.value, 1);
      expect(request.limits.maxStates.value, 1);
      final roundTrip = materialization.value(
        CombinedDamageRequest.fromDto(request.toDto),
      );
      expect(roundTrip, request);
      expect(roundTrip.hashCode, request.hashCode);
      expect(request.attacks, same(request.attacks));
      expect(() => request.attacks.clear(), throwsUnsupportedError);
      expect(() => attack.hits.clear(), throwsUnsupportedError);
      expect(() => attack.hitCounts.clear(), throwsUnsupportedError);
      expect(
        () => attack.conditionalHitCounts!.clear(),
        throwsUnsupportedError,
      );
      expect(() => attack.hits.first.weights.clear(), throwsUnsupportedError);
      expect(
        () => request.setup.initialDamages.clear(),
        throwsUnsupportedError,
      );
    });
  }
  {
    test('空の複合リクエストで例外を投げず両方の欠落を返す', () {
      final dto = CombinedDamageRequestDto(
        attacks: [],
        defender: domain.pokemon(),
        field: domain.field(),
        setup: BattleSetupDto.none,
      );
      final result =
          CombinedDamageRequest.fromDto(dto) as Invalid<CombinedDamageRequest>;
      expect(result.errors, [
        const ValidationError(
          'combinedDamageRequest.attacks',
          ValidationCode.required,
        ),
      ]);
    });
  }
  for (final detailed in [false, true]) {
    test('CombinedDamageRequestの往復と値による等価性 / $detailed', () {
      final p = domain.pokemon(detailed: detailed);
      final a = AttackDto(
        turn: 1,
        hits: [
          DamageDistribution({20: BigInt.one}),
        ],
        hitCounts: {0: BigInt.one, 1: BigInt.two},
        conditionalHitCounts: detailed ? {1: BigInt.one} : null,
      );
      const h = EntryHazardsDto(stealthRock: true, spikesLayers: 3);
      final setup = BattleSetupDto(entryHazards: h, initialDamages: [25]);
      final combined = CombinedDamageRequestDto(
        attacks: [a],
        defender: p,
        field: domain.field(),
        setup: setup,
      );
      domain.equality(
        valid(CombinedDamageRequest.fromDto(combined)),
        valid(CombinedDamageRequest.fromDto(combined)),
      );
    });
  }
}
