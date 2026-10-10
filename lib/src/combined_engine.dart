import 'battle_effects.dart';

import 'dart:math' as math;
import 'models/dto.dart';
import 'models/models.dart';
import 'models/value_objects.dart';
import 'rules/type_chart.dart';

final class _Budget {
  _Budget(this.limits);

  final CalculationLimits limits;
  int operations = 0;

  bool spend(int count, int states) {
    if (operations + count > limits.maxOperations.value ||
        states > limits.maxStates.value) {
      return false;
    }
    operations += count;
    return true;
  }
}

typedef _BranchKey = (int, bool, int?, int?, BigInt);

final class _Branch {
  const _Branch({
    required this.hp,
    required this.itemConsumed,
    required this.toxicCounter,
    required this.cudChewTurn,
    required this.attackDamage,
    required this.weight,
  });

  final int hp;
  final BigInt attackDamage;
  final bool itemConsumed;
  final int? toxicCounter;
  final int? cudChewTurn;
  final BigInt weight;

  _Branch copyWith({
    int? hp,
    bool? itemConsumed,
    int? toxicCounter,
    int? cudChewTurn,
    bool clearCudChewTurn = false,
    BigInt? attackDamage,
    BigInt? weight,
  }) => _Branch(
    hp: hp ?? this.hp,
    itemConsumed: itemConsumed ?? this.itemConsumed,
    toxicCounter: toxicCounter ?? this.toxicCounter,
    cudChewTurn: clearCudChewTurn ? null : (cudChewTurn ?? this.cudChewTurn),
    attackDamage: attackDamage ?? this.attackDamage,
    weight: weight ?? this.weight,
  );

  // 消費状態・毒・回復予約が異なれば、次の行動が変わるので統合しない。
  _BranchKey get key =>
      (hp, itemConsumed, toxicCounter, cudChewTurn, attackDamage);
}

void _addBranch(Map<_BranchKey, _Branch> merged, _Branch branch) {
  final key = branch.key;
  final previous = merged[key];
  merged[key] = previous == null
      ? branch
      : branch.copyWith(weight: previous.weight + branch.weight);
}

List<_Branch> _mergeBranches(Iterable<_Branch> branches) {
  final merged = <_BranchKey, _Branch>{};
  for (final branch in branches) {
    _addBranch(merged, branch);
  }
  return merged.values.toList(growable: false);
}

int _healedHp(int hp, int maxHp, int healing) =>
    hp + math.min(maxHp - hp, healing);

_Branch _healBerry(
  _Branch branch,
  PokemonState defender,
  BattleField field,
  int turn, {
  required bool repeat,
}) {
  final maxHp = defender.stats.hp.value;
  final ability = activeAbility(
    defender,
    field,
    itemConsumed: branch.itemConsumed,
  );
  var healing = math.max(1, maxHp ~/ 4);
  if (ability == AbilityId.ripen) {
    healing *= 2;
  }
  // きのみ本体の回復を上限HPで止めてから、ほおぶくろの追加回復を適用する。
  var hp = _healedHp(branch.hp, maxHp, healing);
  // ほおぶくろ
  if (ability == AbilityId.cheekPouch) {
    hp = _healedHp(hp, maxHp, math.max(1, maxHp ~/ 3));
  }
  return branch.copyWith(
    hp: hp,
    itemConsumed: true,
    cudChewTurn: !repeat && ability == AbilityId.cudChew ? turn + 1 : null,
    clearCudChewTurn: repeat,
  );
}

_Branch _maybeSitrus(
  _Branch branch,
  PokemonState defender,
  BattleField field,
  int turn,
) {
  final maxHp = defender.stats.hp.value;
  // オボンは各ダメージ直後に判定し、ひんしから回復させない。半分ちょうども対象。
  if (branch.hp <= 0 ||
      branch.hp > maxHp ~/ 2 ||
      activeItem(defender, field, itemConsumed: branch.itemConsumed) !=
          ItemId.sitrusBerry ||
      field.effects.contains(FieldEffect.unnerve)) {
    return branch;
  }
  return _healBerry(branch, defender, field, turn, repeat: false);
}

_Branch _damageEvent(
  _Branch branch,
  int damage,
  PokemonState defender,
  BattleField field,
  int turn, {
  bool attackDamage = false,
}) {
  // ひんしになった枝は後続の設置技・定数ダメージ・回復イベントを発生させない。
  if (branch.hp <= 0) return branch;
  final lost = math.min(branch.hp, damage);
  final damaged = branch.copyWith(
    hp: branch.hp - lost,
    attackDamage: attackDamage
        ? branch.attackDamage + BigInt.from(damage)
        : null,
  );

  if (lost == 0) return damaged;
  return _maybeSitrus(damaged, defender, field, turn);
}

Map<T, BigInt> _branchDistribution<T>(
  Iterable<_Branch> branches,
  T Function(_Branch) select,
) {
  final result = <T, BigInt>{};
  for (final branch in branches) {
    final value = select(branch);
    result[value] = (result[value] ?? BigInt.zero) + branch.weight;
  }
  return result;
}

List<_Branch> _applySetup(
  List<_Branch> branches,
  PokemonState defender,
  BattleField field,
  BattleSetup setup,
) {
  final ability = activeAbility(defender, field);
  final item = activeItem(defender, field);
  final boots = item == ItemId.heavyDutyBoots;
  final magicGuard = ability == AbilityId.magicGuard;
  final maxHp = defender.stats.hp.value;
  var current = branches;
  // この入力モデルではステルスロック→まきびし→手動削りの順に、各回のきのみ判定を挟む。
  if (setup.entryHazards.stealthRock && !boots && !magicGuard) {
    var factor = 1.0;
    for (final type in currentTypes(defender)) {
      factor *= typeEffectiveness(PokemonType.rock, type);
    }
    final damage = math.max(1, (maxHp * factor / 8).floor());
    current = [
      for (final branch in current)
        _damageEvent(branch, damage, defender, field, 0),
    ];
  }
  if (!boots &&
      !magicGuard &&
      setup.entryHazards.spikesLayers.value > 0 &&
      isGrounded(defender, field, ability, item)) {
    final denominator = switch (setup.entryHazards.spikesLayers.value) {
      1 => 8,
      2 => 6,
      _ => 4,
    };
    final damage = math.max(1, maxHp ~/ denominator);
    current = [
      for (final branch in current)
        _damageEvent(branch, damage, defender, field, 0),
    ];
  }
  for (final chip in setup.initialDamages) {
    current = [
      for (final branch in current)
        _damageEvent(branch, chip, defender, field, 0),
    ];
  }
  return current;
}

// 攻撃とは独立した状態異常のHP処理。回復・ダメージの後に猛毒を進める。
_Branch _applyStatusAtTurnEnd(
  _Branch branch,
  PokemonState defender,
  BattleField field,
  int turn,
) {
  final status = defender.status;
  if (branch.hp == 0 ||
      !{Status.burn, Status.poison, Status.toxic}.contains(status) ||
      (activeAbility(defender, field, itemConsumed: branch.itemConsumed) ==
          AbilityId.magicGuard)) {
    return branch;
  }
  final maxHp = defender.stats.hp.value;
  final ability = activeAbility(
    defender,
    field,
    itemConsumed: branch.itemConsumed,
  );
  _Branch updated;
  if (status != Status.burn && ability == AbilityId.poisonHeal) {
    updated = branch.copyWith(
      hp: _healedHp(branch.hp, maxHp, math.max(1, maxHp ~/ 8)),
    );
  } else {
    // たいねつは炎技だけでなく、やけどの定数ダメージも半減する。
    final damage = switch (status) {
      Status.burn => math.max(
        1,
        maxHp ~/ (ability == AbilityId.heatproof ? 32 : 16),
      ),
      Status.poison => math.max(1, maxHp ~/ 8),
      _ => math.max(1, maxHp * (branch.toxicCounter ?? 1) ~/ 16),
    };
    updated = _damageEvent(branch, damage, defender, field, turn);
  }
  return status == Status.toxic
      ? updated.copyWith(
          toxicCounter: math.min(15, (updated.toxicCounter ?? 1) + 1),
        )
      : updated;
}

_Branch _applySandAtTurnEnd(
  _Branch branch,
  PokemonState defender,
  BattleField field,
  int turn,
) {
  if (branch.hp == 0 ||
      effectiveWeather(field, [
            activeAbility(defender, field, itemConsumed: branch.itemConsumed),
          ]) !=
          Weather.sandstorm ||
      currentTypes(defender).any(
        {PokemonType.rock, PokemonType.ground, PokemonType.steel}.contains,
      ) ||
      ({
        AbilityId.sandVeil,
        AbilityId.sandRush,
        AbilityId.sandForce,
        AbilityId.overcoat,
        AbilityId.magicGuard,
      }.contains(
        activeAbility(defender, field, itemConsumed: branch.itemConsumed),
      )) ||
      (activeItem(defender, field, itemConsumed: branch.itemConsumed) ==
          ItemId.safetyGoggles)) {
    return branch;
  }
  return _damageEvent(
    branch,
    math.max(1, defender.stats.hp.value ~/ 16),
    defender,
    field,
    turn,
  );
}

_Branch _applyGrassyTerrainAtTurnEnd(
  _Branch branch,
  PokemonState defender,
  BattleField field,
) {
  if (branch.hp == 0 ||
      field.terrain != Terrain.grass ||
      !isGrounded(
        defender,
        field,
        activeAbility(defender, field, itemConsumed: branch.itemConsumed),
        activeItem(defender, field, itemConsumed: branch.itemConsumed),
      )) {
    return branch;
  }
  final maxHp = defender.stats.hp.value;
  return branch.copyWith(
    hp: _healedHp(branch.hp, maxHp, math.max(1, maxHp ~/ 16)),
  );
}

_Branch _applyLeftoversAtTurnEnd(
  _Branch branch,
  PokemonState defender,
  BattleField field,
) {
  final maxHp = defender.stats.hp.value;
  if (branch.hp == 0 ||
      branch.hp == maxHp ||
      activeItem(defender, field, itemConsumed: branch.itemConsumed) !=
          ItemId.leftovers) {
    return branch;
  }
  return branch.copyWith(
    hp: _healedHp(branch.hp, maxHp, math.max(1, maxHp ~/ 16)),
  );
}

_Branch _applyCudChewAtTurnEnd(
  _Branch branch,
  PokemonState defender,
  BattleField field,
  int turn,
) {
  if (branch.hp == 0 ||
      branch.cudChewTurn != turn ||
      activeAbility(defender, field) != AbilityId.cudChew ||
      activeItem(
            defender,
            field,
            itemConsumed: branch.itemConsumed,
            ignoreConsumption: true,
          ) !=
          ItemId.sitrusBerry ||
      field.effects.contains(FieldEffect.unnerve)) {
    return branch;
  }
  // 再摂取で次の予約は作らない。
  return _healBerry(branch, defender, field, turn, repeat: true);
}

List<_Branch> _applyTurnEnd(
  List<_Branch> branches,
  PokemonState defender,
  BattleField field,
  int turn,
) {
  final result = <_Branch>[];
  for (final branch in branches) {
    // 対応する効果の順序: 砂→グラス→残飯→状態異常→はんすう。
    // 各ダメージ直後のきのみ判定と、ひんしによる後続処理停止は各関数で扱う。
    var current = _applySandAtTurnEnd(branch, defender, field, turn);
    current = _applyGrassyTerrainAtTurnEnd(current, defender, field);
    current = _applyLeftoversAtTurnEnd(current, defender, field);
    current = _applyStatusAtTurnEnd(current, defender, field, turn);
    current = _applyCudChewAtTurnEnd(current, defender, field, turn);
    result.add(current);
  }
  return _mergeBranches(result);
}

// 共通のヒット列は一度だけ畳み込み、必要な回数の時点で分布を取り出す。
// 各回数の分母へ正確に通分し、撃破後も未実行の乱数の重みだけを乗せる。
final class _AttackBranches {
  const _AttackBranches(this.actual, this.conditional);
  final List<_Branch> actual;
  final List<_Branch>? conditional;
}

bool _collectPrefix(
  Map<_BranchKey, _Branch> collected,
  List<_Branch> prefix,
  BigInt scale,
  _Budget budget, {
  required bool trackAttackDamage,
}) {
  for (final branch in prefix) {
    _addBranch(
      collected,
      branch.copyWith(
        weight: branch.weight * scale,
        attackDamage: trackAttackDamage ? null : BigInt.zero,
      ),
    );
    if (!budget.spend(1, collected.length)) return false;
  }
  return true;
}

Calculation<_AttackBranches> _executeAttack(
  List<_Branch> branches,
  Attack attack,
  Map<int, BigInt> counts,
  PokemonState defender,
  BattleField field,
  _Budget budget, {
  Map<int, BigInt>? sharedConditionalCounts,
  bool trackAttackDamage = true,
}) {
  final actualMaximum = counts.keys.reduce(math.max);
  final conditionalMaximum =
      sharedConditionalCounts?.keys.reduce(math.max) ?? 0;
  final maximum = math.max(actualMaximum, conditionalMaximum);
  final denominators = [BigInt.one];
  for (final hit in attack.hits.take(maximum)) {
    denominators.add(denominators.last * hit.totalWeight);
  }
  final actual = <_BranchKey, _Branch>{};
  final conditional = <_BranchKey, _Branch>{};
  var current = branches;
  for (var hitIndex = 0; hitIndex <= maximum; hitIndex++) {
    final countWeight = counts[hitIndex];
    if (countWeight != null &&
        !_collectPrefix(
          actual,
          current,
          countWeight * (denominators[actualMaximum] ~/ denominators[hitIndex]),
          budget,
          trackAttackDamage: trackAttackDamage,
        )) {
      return const Failure(FailureKind.complexityExceeded, 'distribution');
    }
    final conditionalWeight = sharedConditionalCounts?[hitIndex];
    if (conditionalWeight != null &&
        !_collectPrefix(
          conditional,
          current,
          conditionalWeight *
              (denominators[conditionalMaximum] ~/ denominators[hitIndex]),
          budget,
          trackAttackDamage: false,
        )) {
      return const Failure(FailureKind.complexityExceeded, 'distribution');
    }
    if (hitIndex == maximum) break;
    final hit = attack.hits[hitIndex];
    final next = <_BranchKey, _Branch>{};
    for (final original in current) {
      if (original.hp == 0) {
        _addBranch(
          next,
          original.copyWith(weight: original.weight * hit.totalWeight),
        );
        if (!budget.spend(1, next.length)) {
          return const Failure(FailureKind.complexityExceeded, 'distribution');
        }
      } else {
        for (final roll in hit.weights.entries) {
          final advanced = _damageEvent(
            original.copyWith(weight: original.weight * roll.value.value),
            roll.key.value,
            defender,
            field,
            attack.turn.value,
            attackDamage: trackAttackDamage,
          );
          _addBranch(next, advanced);
          if (!budget.spend(1, next.length)) {
            return const Failure(
              FailureKind.complexityExceeded,
              'distribution',
            );
          }
        }
      }
    }
    current = next.values.toList(growable: false);
  }
  // 全枝の分母は外れ・撃破停止を含めて同じになる。
  assert(
    actual.values.fold(BigInt.zero, (sum, b) => sum + b.weight) ==
        branches.fold(BigInt.zero, (sum, b) => sum + b.weight) *
            counts.values.fold(BigInt.zero, (sum, w) => sum + w) *
            denominators[actualMaximum],
  );
  return Success(
    _AttackBranches(
      actual.values.toList(growable: false),
      sharedConditionalCounts == null
          ? null
          : conditional.values.toList(growable: false),
    ),
  );
}

List<_Branch> _initialBranches(CombinedDamageRequest request) => _applySetup(
  [
    _Branch(
      hp: request.defender.currentHp?.value ?? request.defender.stats.hp.value,
      itemConsumed: request.defender.itemConsumed,
      toxicCounter: request.defender.toxicCounter?.value,
      cudChewTurn: request.defender.cudChewTurn?.value,
      attackDamage: BigInt.zero,
      weight: BigInt.one,
    ),
  ],
  request.defender,
  request.field,
  request.setup,
);

// 確定数に必要なのは到達可能な状態。重みが違っても回数の候補が同じなら共有する。
bool _sameCountSupport(Map<int, BigInt> actual, Map<int, BigInt> conditional) =>
    actual.length == conditional.length &&
    actual.keys.every(conditional.containsKey);

/// 分布だけからHP推移と命中込みの撃破率を合算する。
Calculation<CombinedDamageResult> calculateCombinedDamage(
  CombinedDamageRequest request,
) {
  final budget = _Budget(request.limits);
  if (!budget.spend(
    request.setup.initialDamages.length +
        request.attacks.fold<int>(
          0,
          (sum, a) =>
              sum +
              a.hits.fold<int>(0, (sum, hit) => sum + hit.weights.length) +
              a.hitCounts.length +
              (a.conditionalHitCounts?.length ?? 0),
        ),
    1,
  )) {
    return const Failure(FailureKind.complexityExceeded, 'distribution');
  }
  var branches = _initialBranches(request);
  final applicable = request.attacks.every(
    (a) => a.conditionalHitCounts != null,
  );
  var conditional = applicable ? branches : <_Branch>[];
  int? possible = applicable && conditional.every((b) => b.hp == 0) ? 0 : null;
  int? guaranteed = possible;
  for (var i = 0; i < request.attacks.length; i++) {
    final attack = request.attacks[i];
    final needsConditional = applicable && guaranteed == null;
    final shared = needsConditional && identical(branches, conditional);
    final sameCounts =
        shared &&
        _sameCountSupport(attack.hitCounts, attack.conditionalHitCounts!);
    final result = _executeAttack(
      branches,
      attack,
      attack.hitCounts,
      request.defender,
      request.field,
      budget,
      sharedConditionalCounts: shared && !sameCounts
          ? attack.conditionalHitCounts
          : null,
    );
    if (result case Failure(:final kind, :final path)) {
      return Failure(kind, path);
    }
    final value = (result as Success<_AttackBranches>).value;
    branches = value.actual;
    if (needsConditional) {
      if (shared) {
        conditional = sameCounts ? branches : value.conditional!;
      } else {
        final conditionalResult = _executeAttack(
          conditional,
          attack,
          attack.conditionalHitCounts!,
          request.defender,
          request.field,
          budget,
          trackAttackDamage: false,
        );
        if (conditionalResult case Failure(:final kind, :final path)) {
          return Failure(kind, path);
        }
        conditional =
            (conditionalResult as Success<_AttackBranches>).value.actual;
      }
    }
    if (i == request.attacks.length - 1 ||
        request.attacks[i + 1].turn != attack.turn) {
      final sharedTurnEnd =
          needsConditional && identical(branches, conditional);
      branches = _applyTurnEnd(
        branches,
        request.defender,
        request.field,
        attack.turn.value,
      );
      if (needsConditional) {
        conditional = sharedTurnEnd
            ? branches
            : _applyTurnEnd(
                conditional,
                request.defender,
                request.field,
                attack.turn.value,
              );
      }
    }
    if (needsConditional) {
      if (conditional.any((b) => b.hp == 0)) possible ??= i + 1;
      if (conditional.every((b) => b.hp == 0)) guaranteed = i + 1;
    }
    if (!budget.spend(
      branches.length + (needsConditional ? conditional.length : 0),
      math.max(branches.length, needsConditional ? conditional.length : 0),
    )) {
      return const Failure(FailureKind.complexityExceeded, 'distribution');
    }
  }
  final hp = DamageDistribution(_branchDistribution(branches, (b) => b.hp));
  final defender = request.defender;
  return Success(
    CombinedDamageResult(
      referenceHp: defender.stats.hp.value,
      finalHp: hp,
      attackDamage: CombinedDamageDistribution(
        _branchDistribution(branches, (b) => b.attackDamage),
      ),
      knockout: KnockoutProbability(
        hp.weights[0] ?? BigInt.zero,
        hp.totalWeight,
      ),
      ko: KoInfo(
        evaluatedAttacks: request.attacks.length,
        status: !applicable
            ? KoStatus.notApplicable
            : guaranteed == null
            ? KoStatus.limitReached
            : KoStatus.resolved,
        possibleHits: possible,
        guaranteedHits: guaranteed,
      ),
      finalStates: [
        for (final b in branches)
          WeightedBattleState(
            state: BattleState.fromDto(
              PokemonStateDto(
                profile: defender.profile.toDto,
                stats: defender.stats.toDto,
                stages: defender.stages.toDto,
                ability: defender.ability,
                item: defender.item,
                status: defender.status,
                sideConditions: defender.sideConditions,
                currentHp: b.hp,
                toxicCounter: b.toxicCounter,
                itemConsumed: b.itemConsumed,
                cudChewTurn: b.cudChewTurn,
                teraType: defender.teraType,
                boostedStat: defender.boostedStat,
                faintedAllies: defender.faintedAllies.value,
                timesHit: defender.timesHit.value,
                flags: defender.flags,
              ),
            ),
            weight: b.weight,
          ),
      ],
    ),
  );
}
