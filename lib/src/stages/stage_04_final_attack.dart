import '../models/dto.dart';
import '../models/value_objects.dart';

import 'calculation_context.dart';
import 'common_modifier.dart';
import 'dart:math' as math;
import 'stage_03_attack_modifiers.dart';

TracedValue calculateAttackStat(DamageEffectsContext context, bool critical) {
  final attacker = context.attacker;
  final defender = context.defender;
  final move = context.move;
  final attackerAbility = context.attackerAbility;
  final defenderAbility = context.defenderAbility;
  // イカサマは相手の能力値・ランクだけを借り、攻撃補正の特性・道具は使用者を参照する。
  final source = move.id == MoveId.foulPlay ? defender : attacker;
  // ボディプレスの考慮
  final stat = move.id == MoveId.bodyPress
      ? Stat.def
      : context.physical
      ? Stat.atk
      : Stat.spa;
  var rank = source.stages[stat]?.value ?? 0;
  // 急所は不利な下降ランクだけを無視し、てんねんは上昇・下降の両方を無視する。
  if (critical) rank = math.max(0, rank);
  if (defenderAbility == AbilityId.unaware) rank = 0;
  var value = rankedStat(source.stats[stat].value, rank);
  final trace = <ModifierTrace>[
    ModifierTrace(
      'Rank',
      ModifierStage.attack,
      value,
      source.stats[stat].value,
      source.stats[stat].value,
      value,
    ),
  ];
  // はりきりは補正連結へ含めず、ランク適用後の能力値へ直接丸めて適用する。
  if (attackerAbility == AbilityId.hustle && context.physical) {
    final result = applyFixedPointModifier(
      AbilityId.hustle.value,
      ModifierStage.attack,
      value,
      6144,
    );
    value = result.value;
    trace.addAll(result.trace);
  }
  final modifierChain = calculateAttackModifiers(context);
  final result = modifierChain.apply(value);
  return TracedValue(result.value, [...trace, ...result.trace]);
}
