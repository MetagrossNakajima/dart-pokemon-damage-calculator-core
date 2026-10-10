import 'dart:math' as math;
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import 'fixed_combined_fixtures.dart' as combined;

final class AttackInput {
  const AttackInput(this.hits, this.counts, {this.conditional});

  final List<Map<int, int>> hits;
  final Map<int, int> counts;
  final Map<int, int>? conditional;

  AttackDto get dto => combined.attack(
    hits.map(combined.distribution).toList(),
    counts: counts,
    conditional: conditional,
  );
}

typedef RollPath = ({List<int> rolls, BigInt weight});

typedef Outcome = ({int hp, bool consumed, int damage, BigInt weight});

List<RollPath> rollPaths(List<Map<int, int>> hits) {
  var paths = <RollPath>[(rolls: [], weight: BigInt.one)];
  for (final hit in hits) {
    paths = [
      for (final path in paths)
        for (final roll in hit.entries)
          (
            rolls: [...path.rolls, roll.key],
            weight: path.weight * BigInt.from(roll.value),
          ),
    ];
  }
  return paths;
}

List<Outcome> enumerate(
  List<AttackInput> attacks, {
  int maxHp = 100,
  int currentHp = 100,
  bool sitrus = false,
}) {
  var outcomes = <Outcome>[
    (hp: currentHp, consumed: false, damage: 0, weight: BigInt.one),
  ];
  for (final attack in attacks) {
    final maximum = attack.counts.keys.reduce(math.max);
    final paths = rollPaths(attack.hits.take(maximum).toList());
    final next = <Outcome>[];
    for (final before in outcomes) {
      for (final count in attack.counts.entries) {
        for (final path in paths) {
          var hp = before.hp;
          var consumed = before.consumed;
          var damage = before.damage;
          for (final roll in path.rolls.take(count.key)) {
            if (hp == 0) break;
            damage += roll;
            hp = math.max(0, hp - roll);
            if (sitrus && !consumed && roll > 0 && hp > 0 && hp <= maxHp ~/ 2) {
              hp = math.min(maxHp, hp + maxHp ~/ 4);
              consumed = true;
            }
          }
          next.add((
            hp: hp,
            consumed: consumed,
            damage: damage,
            weight: before.weight * BigInt.from(count.value) * path.weight,
          ));
        }
      }
    }
    outcomes = next;
  }
  return outcomes;
}

Map<K, BigInt> weights<T, K>(
  Iterable<T> values,
  K Function(T) key,
  BigInt Function(T) weight,
) {
  final result = <K, BigInt>{};
  for (final value in values) {
    final k = key(value);
    result[k] = (result[k] ?? BigInt.zero) + weight(value);
  }
  return result;
}

void expectOracle(CombinedDamageResult result, List<Outcome> oracle) {
  final hp = weights(oracle, (o) => o.hp, (o) => o.weight);
  final total = oracle.fold(BigInt.zero, (sum, o) => sum + o.weight);
  expect(result.finalHp.weights, hp);
  expect(
    result.attackDamage.weights,
    weights(oracle, (o) => BigInt.from(o.damage), (o) => o.weight),
  );
  expect(result.finalHp.totalWeight, total);
  expect(result.attackDamage.totalWeight, total);
  expect(result.knockout.totalWeight, total);
  expect(result.knockout.weight, hp[0] ?? BigInt.zero);
  expect(
    weights(
      result.finalStates,
      (o) => (o.state.currentHp!, o.state.itemConsumed),
      (o) => o.weight,
    ),
    weights(oracle, (o) => (o.hp, o.consumed), (o) => o.weight),
  );
}

void expectBudgetFailure(CombinedDamageRequestDto dto) {
  final validation = CombinedDamageRequest.fromDto(dto);
  expect(validation, isA<Valid<CombinedDamageRequest>>());
  final result = calculateCombinedDamage(
    (validation as Valid<CombinedDamageRequest>).value,
  );
  expect(result, isA<Failure<CombinedDamageResult>>());
  final failure = result as Failure<CombinedDamageResult>;
  expect(failure.kind, FailureKind.complexityExceeded);
  expect(failure.path, 'distribution');
}
