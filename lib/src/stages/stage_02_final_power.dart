import '../battle_effects.dart';

import '../models/dto.dart';
import '../models/value_objects.dart';
import '../rules/move_rules.dart';
import 'calculation_context.dart';
import 'common_modifier.dart';
import 'dart:math' as math;
import 'multi_hit.dart';
import 'stage_01_power_modifiers.dart';

// トリプルアクセル・トリプルキック
int _escalatingHitBasePower(DamageEffectsContext context, int power) =>
    {MoveId.tripleAxel, MoveId.tripleKick}.contains(context.move.id)
    ? power * (context.hitIndex + 1)
    : power;

// けたぐり・くさむすび
int _weightBasedBasePower(DamageEffectsContext context, int power) {
  if (!isWeightBasedMove(context.move.id)) return power;
  final defenderWeight = context.weight(
    context.defender,
    context.defenderAbility,
    context.defenderItem,
  );
  final attackerWeight = context.weight(
    context.attacker,
    context.attackerAbility,
    context.attackerItem,
  );
  if ({MoveId.lowKick, MoveId.grassKnot}.contains(context.move.id)) {
    final crossedThresholds = [
      10,
      25,
      50,
      100,
      200,
    ].where((threshold) => defenderWeight >= threshold).length;
    return 20 + crossedThresholds * 20;
  }
  final crossedRatios = [
    2,
    3,
    4,
    5,
  ].where((ratio) => attackerWeight >= defenderWeight * ratio).length;
  return 40 + crossedRatios * 20;
}

// アクロバット・エラがみ・でんげきくちばし・ダメおし・たたりめ
int _conditionalDoubleBasePower(DamageEffectsContext context, int power) {
  final move = context.move;
  final applies = switch (move.id) {
    MoveId.acrobatics =>
      context.attackerItem == null ||
          (context.attackerItem == ItemId.normalGem &&
              move.type == TeraType.normal),
    MoveId.hex =>
      context.defender.status != null ||
          context.defenderAbility == AbilityId.comatose,
    MoveId.fishiousRend ||
    MoveId.boltBeak => pokemonFlag(context.attacker, PokemonFlag.movesFirst),
    MoveId.assurance => pokemonFlag(
      context.defender,
      PokemonFlag.damagedThisTurn,
    ),
    _ => false,
  };
  return applies ? power * 2 : power;
}

// おはかまいり
int _lastRespectsBasePower(DamageEffectsContext context, int power) =>
    context.move.id == MoveId.lastRespects
    ? 50 * (1 + context.attacker.faintedAllies.value)
    : power;

// ふんどのこぶし
int _rageFistBasePower(DamageEffectsContext context, int power) =>
    context.move.id == MoveId.rageFist
    ? 50 * (1 + math.min(6, context.attacker.timesHit.value))
    : power;

// ふんか・しおふき・ドラゴンエナジー
int _fullHpBasePower(DamageEffectsContext context, int power) =>
    {
      MoveId.eruption,
      MoveId.waterSpout,
      MoveId.dragonEnergy,
    }.contains(context.move.id)
    ? math.max(
        1,
        150 *
            context.hp(context.attacker) ~/
            context.attacker.stats[Stat.hp].value,
      )
    : power;

// じたばた・きしかいせい
int _flailBasePower(DamageEffectsContext context, int power) {
  if (!{MoveId.flail, MoveId.reversal}.contains(context.move.id)) return power;
  final ratio =
      48 *
      context.hp(context.attacker) ~/
      context.attacker.stats[Stat.hp].value;
  return switch (ratio) {
    <= 1 => 200,
    <= 4 => 150,
    <= 9 => 100,
    <= 16 => 80,
    <= 32 => 40,
    _ => 20,
  };
}

// 防御側HPに依存する3技の威力だけを満タン時の値へ固定する。
// その他のHP依存補正は、入力された現在HPを参照する。
int _targetHpBasePower(DamageEffectsContext context, int power) =>
    switch (context.move.id) {
      MoveId.crushGrip || MoveId.wringOut => 120,
      MoveId.hardPress => 100,
      _ => power,
    };

TracedValue _basePower(DamageEffectsContext context) {
  final move = context.move;
  var power = move.power;
  final orderedTransformations = [
    _escalatingHitBasePower,
    _weightBasedBasePower,
    _conditionalDoubleBasePower,
    _lastRespectsBasePower,
    _rageFistBasePower,
    _fullHpBasePower,
    _flailBasePower,
    _targetHpBasePower,
    _boostCountBasePower,
  ];
  for (final transform in orderedTransformations) {
    power = transform(context, power);
  }
  final trace = ModifierTrace(
    move.id.value,
    ModifierStage.basePower,
    power,
    math.max(1, context.originalMove.power.value),
    context.originalMove.power.value,
    power,
  );
  return TracedValue(power, [trace]);
}

int _boostCountBasePower(DamageEffectsContext context, int power) =>
    {MoveId.storedPower, MoveId.powerTrip}.contains(context.move.id)
    ? 20 *
          (1 +
              [Stat.atk, Stat.def, Stat.spa, Stat.spd, Stat.spe].fold<int>(
                0,
                (total, stat) =>
                    total + math.max(0, context.attacker.stages[stat]!.value),
              ))
    : power;

TracedValue calculatePower(DamageEffectsContext context) {
  final attacker = context.attacker;
  final move = context.move;
  final basePower = _basePower(context);
  final unmodifiedPower = basePower.value;
  final modifierChain = calculatePowerModifiers(context, unmodifiedPower);
  final modifiedPower = modifierChain.apply(unmodifiedPower);
  var power = modifiedPower.value;
  final trace = [...basePower.trace, ...modifiedPower.trace];
  final teraBoost =
      attacker.teraType == move.type ||
      (attacker.teraType == TeraType.stellar &&
          (pokemonFlag(attacker, PokemonFlag.stellarBoostAvailable, true) ||
              attacker.id == PokemonId.terapagosStellar));
  // 最低威力60は威力補正後に判定する。連続技・先制技・噴火系は引き上げない。
  if (teraBoost &&
      !isNaturalMultiHit(move.id) &&
      move.priority <= 0 &&
      !{
        MoveId.eruption,
        MoveId.waterSpout,
        MoveId.dragonEnergy,
      }.contains(move.id) &&
      power < 60) {
    trace.add(
      ModifierTrace('TeraMinimum', ModifierStage.power, 60, power, power, 60),
    );
    power = 60;
  }
  return TracedValue(power, trace);
}
