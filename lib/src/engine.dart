import 'models/dto.dart';
import 'models/models.dart';
import 'models/value_objects.dart';
import 'rules/move_rules.dart';
import 'stages/calculation_context.dart';
import 'stages/fixed_damage.dart';
import 'stages/stage_02_final_power.dart';
import 'stages/stage_04_final_attack.dart';
import 'stages/stage_06_final_defense.dart';
import 'stages/stage_07_damage_modifiers.dart';
import 'stages/stage_08_final_damage.dart';
import 'stages/type_effectiveness.dart';

DamageDistribution _rolls(List<int> rolls) {
  final weights = <int, BigInt>{};
  for (final damage in rolls) {
    weights[damage] = (weights[damage] ?? BigInt.zero) + BigInt.one;
  }
  return DamageDistribution(weights);
}

bool _isCriticalHit(DamageEffectsContext context, bool requestedCritical) =>
    (requestedCritical ||
        isGuaranteedCritical(context.move.id) ||
        (context.attackerAbility == AbilityId.merciless &&
            {Status.poison, Status.toxic}.contains(context.defender.status))) &&
    !{
      AbilityId.battleArmor,
      AbilityId.shellArmor,
    }.contains(context.defenderAbility);

HitResult _hit(
  PokemonState attacker,
  PokemonState defender,
  Move originalMove,
  BattleField battleField,
  bool requestedCrit,
  int hitIndex,
) {
  final context = DamageEffectsContext(
    attacker,
    defender,
    originalMove,
    battleField,
    hitIndex,
  );
  final critical = _isCriticalHit(context, requestedCrit);
  final powerResult = calculatePower(context);
  final attackResult = calculateAttackStat(context, critical);
  final defenseResult = calculateDefenseStat(context, critical);
  final power = powerResult.value;
  final attack = attackResult.value;
  final defense = defenseResult.value;
  final trace = <ModifierTrace>[
    ...powerResult.trace,
    ...attackResult.trace,
    ...defenseResult.trace,
  ];
  final preRandomDamage = calculatePreRandomDamage(
    context,
    power,
    attack,
    defense,
    critical,
  );
  trace.addAll(preRandomDamage.trace);
  final effectiveness = calculateEffectiveness(context);
  final finalModifierResult = calculateFinalModifier(
    context,
    critical,
    effectiveness,
  );
  final finalModifier = finalModifierResult.value;
  trace.addAll(finalModifierResult.trace);
  final rolls = <int>[];
  for (var roll = 85; roll <= 100; roll++) {
    final damage = calculateDamageRoll(
      context,
      preRandomDamage.value,
      roll,
      effectiveness,
      finalModifier,
    );
    rolls.add(damage.value);
    trace.addAll(damage.trace);
  }
  return HitResult(power, attack, defense, critical, rolls, trace);
}

bool _isOhkoMove(MoveId id) => {
  MoveId.fissure,
  MoveId.sheerCold,
  MoveId.hornDrill,
  MoveId.guillotine,
}.contains(id);

HitResult _specialHit(
  PokemonState attacker,
  PokemonState defender,
  Move move,
  BattleField field,
) {
  final context = DamageEffectsContext(attacker, defender, move, field, 0);
  final hp = defender.currentHp?.value ?? defender.stats.hp.value;
  final attackerHp = attacker.currentHp?.value ?? attacker.stats.hp.value;
  final effectiveness = calculateEffectiveness(context);
  var immune = effectiveness == 0;
  // ぜったいれいど
  if (move.id == MoveId.sheerCold &&
      context.defenderTypes.contains(PokemonType.ice)) {
    immune = true;
  }
  // がんじょう
  if (_isOhkoMove(move.id) && context.defenderAbility == AbilityId.sturdy) {
    immune = true;
  }
  final damage = switch (move.id) {
    MoveId.superFang ||
    MoveId.naturesMadness ||
    MoveId.ruination => halfRemainingHp(hp),
    MoveId.guardianofAlola => threeQuarterRemainingHp(hp),
    MoveId.finalGambit => attackerHp,
    MoveId.endeavor => endeavorDamage(hp, attackerHp),
    MoveId.sonicBoom => 20,
    MoveId.dragonRage => 40,
    MoveId.seismicToss || MoveId.nightShade => 50,
    _ => hp,
  };
  final attackStat = attacker
      .stats[move.category == Category.physical ? Stat.atk : Stat.spa]
      .value;
  final defenseStat = defender
      .stats[move.category == Category.physical ? Stat.def : Stat.spd]
      .value;
  return HitResult(
    move.power.value,
    attackStat,
    defenseStat,
    false,
    [immune ? 0 : damage],
    const [],
    kind: DamageKind.fixed,
  );
}

/// 指定条件とヒット位置のダメージを算出する。
Calculation<DamageResult> calculateDamage(DamageRequest request) {
  if (isUnsupportedMove(request.move.id)) {
    return Failure(FailureKind.unsupported, 'move.${request.move.id.value}');
  }
  final hit = isFixedDamageMove(request.move.id)
      ? _specialHit(
          request.attacker,
          request.defender,
          request.move,
          request.field,
        )
      : _hit(
          request.attacker,
          request.defender,
          request.move,
          request.field,
          request.critical,
          request.hitIndex,
        );
  return Success(
    DamageResult(_rolls(hit.rolls), request.defender.stats.hp.value, [hit]),
  );
}
