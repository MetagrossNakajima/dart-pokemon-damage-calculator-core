import '../models/dto.dart';

import '../models/value_objects.dart';
import 'calculation_context.dart';
import 'common_modifier.dart';
import 'dart:math' as math;
import 'stage_05_defense_modifiers.dart';

TracedValue calculateDefenseStat(DamageEffectsContext context, bool critical) {
  final defender = context.defender;
  final attackerAbility = context.attackerAbility;
  final move = context.move;
  final stat = context.physicalDefense ? Stat.def : Stat.spd;
  // ワンダールームは実数値の参照先だけを交換し、ランクと補正は技が使う防御側に従う。
  final rawStat = context.field(FieldEffect.wonderRoom)
      ? (stat == Stat.def ? Stat.spd : Stat.def)
      : stat;
  var rank = defender.stages[stat]?.value ?? 0;
  // 急所で無視するのは防御側の上昇だけ。下降は急所でも残す。
  if (critical) rank = math.min(0, rank);
  if (attackerAbility == AbilityId.unaware ||
      {
        MoveId.sacredSword,
        MoveId.chipAway,
        MoveId.darkestLariat,
      }.contains(move.id)) {
    rank = 0;
  }
  var value = rankedStat(defender.stats[rawStat].value, rank);
  final trace = <ModifierTrace>[
    ModifierTrace(
      'Rank',
      ModifierStage.defense,
      value,
      defender.stats[rawStat].value,
      defender.stats[rawStat].value,
      value,
    ),
  ];
  if ((context.weather == Weather.sandstorm &&
          context.defenderTypes.contains(PokemonType.rock) &&
          !context.physicalDefense) ||
      (context.weather == Weather.snow &&
          context.defenderTypes.contains(PokemonType.ice) &&
          context.physicalDefense)) {
    final result = applyFixedPointModifier(
      'WeatherDefense',
      ModifierStage.defense,
      value,
      6144,
    );
    value = result.value;
    trace.addAll(result.trace);
  }
  final modifierChain = calculateDefenseModifiers(context, stat);
  final result = modifierChain.apply(value);
  return TracedValue(result.value, [...trace, ...result.trace]);
}
