import '../battle_effects.dart';

import '../models/dto.dart';
import '../models/value_objects.dart';
import 'calculation_context.dart';
import 'common_modifier.dart';
import 'dart:math' as math;
import 'multi_hit.dart';

int calculateStab(DamageEffectsContext context) {
  final type = context.move.type;
  final tera = context.attacker.teraType;
  // テラスタル後も元タイプの一致補正を残し、テラタイプ一致分を加算する。
  final original =
      type.pokemonType != null &&
      context.attacker.types.contains(type.pokemonType);
  var stab = original ? 6144 : 4096;
  if (!original &&
      tera == null &&
      {AbilityId.protean, AbilityId.libero}.contains(context.attackerAbility)) {
    stab += 2048;
  }
  if (tera == type && tera != TeraType.stellar) stab += 2048;
  final currentType = tera == null || tera == TeraType.stellar
      ? original
      : tera == type;
  if (context.attackerAbility == AbilityId.adaptability && currentType) {
    stab +=
        tera?.pokemonType != null &&
            context.attacker.types.contains(tera!.pokemonType)
        ? 1024
        : 2048;
  }
  // ステラの強化はタイプごとの使用済み状態に従い、テラパゴスは使い切らない。
  if (tera == TeraType.stellar &&
      (pokemonFlag(context.attacker, PokemonFlag.stellarBoostAvailable, true) ||
          context.attacker.id == PokemonId.terapagosStellar)) {
    stab = original ? stab + 2048 : 4915;
  }
  return stab;
}

TracedValue _applyDamageModifier(
  String id,
  ModifierStage stage,
  int damage,
  int numerator,
) {
  final product = unsigned32(damage * numerator);
  final after = (product * 2 + 4095) ~/ 8192;
  return TracedValue(after, [
    ModifierTrace(id, stage, numerator, 4096, damage, after),
  ]);
}

TracedValue _conditionalDamageModifier(
  String id,
  int value,
  int numerator,
  bool applies,
) => applies
    ? _applyDamageModifier(id, ModifierStage.damage, value, numerator)
    : TracedValue(value, const []);

TracedValue _baseDamage(int power, int attack, int defense) {
  // レベル50の係数22を使い、防御で割った段階と50で割った段階でそれぞれ切り捨てる。
  final damage =
      unsigned32(unsigned32(unsigned32(22 * power) * attack) ~/ defense) ~/ 50 +
      2;
  return TracedValue(damage, [
    ModifierTrace('BaseDamage', ModifierStage.damage, 1, 1, damage, damage),
  ]);
}

TracedValue _spreadDamageModifier(DamageEffectsContext context, int damage) =>
    _conditionalDamageModifier(
      'Spread',
      damage,
      3072,
      context.battleField.format == BattleFormat.double && context.move.spread,
    );

TracedValue _parentalBondDamageModifier(
  DamageEffectsContext context,
  int damage,
) => _conditionalDamageModifier(
  AbilityId.parentalBond.value,
  damage,
  1024,
  context.hitIndex == 1 && appliesParentalBond(context),
);

TracedValue _weatherDamageModifier(DamageEffectsContext context, int damage) {
  // ハイドロスチームの晴れ・MegaSol補正は対象の傘より先に適用する。
  // 使用者の傘が有効なら、この例外を使わず通常の天候補正へ進む。
  if ((context.weather == Weather.sunlight ||
          context.attackerAbility == AbilityId.megaSol) &&
      context.move.id == MoveId.hydroSteam &&
      context.attackerItem != ItemId.utilityUmbrella) {
    return _applyDamageModifier('Weather', ModifierStage.damage, damage, 6144);
  }
  // 通常の天候ダメージ補正を防ぐのは対象の傘。ウェザーボールの変化は使用者の傘で決まる。
  return switch ((context.defenderItem, context.weather, context.move.type)) {
    (ItemId.utilityUmbrella, _, _) => TracedValue(damage, const []),
    (_, Weather.sunlight, TeraType.fire) || (_, Weather.rain, TeraType.water) =>
      _applyDamageModifier('Weather', ModifierStage.damage, damage, 6144),
    (_, Weather.sunlight, TeraType.water) || (_, Weather.rain, TeraType.fire) =>
      _applyDamageModifier('Weather', ModifierStage.damage, damage, 2048),
    _ => TracedValue(damage, const []),
  };
}

TracedValue _criticalDamageModifier(int damage, bool critical) => critical
    ? TracedValue(unsigned32(damage * 3 ~/ 2), [
        ModifierTrace(
          'Critical',
          ModifierStage.damage,
          6144,
          4096,
          damage,
          unsigned32(damage * 3 ~/ 2),
        ),
      ])
    : TracedValue(damage, const []);

TracedValue calculatePreRandomDamage(
  DamageEffectsContext context,
  int power,
  int attack,
  int defense,
  bool critical,
) {
  final base = _baseDamage(power, attack, defense);
  var damage = base.value;
  final trace = <ModifierTrace>[...base.trace];
  final orderedStages = [_spreadDamageModifier(context, damage)];
  for (final stage in orderedStages) {
    damage = stage.value;
    trace.addAll(stage.trace);
  }
  for (final transform in [
    _parentalBondDamageModifier,
    _weatherDamageModifier,
  ]) {
    final stage = transform(context, damage);
    damage = stage.value;
    trace.addAll(stage.trace);
  }
  final criticalStage = _criticalDamageModifier(damage, critical);
  return TracedValue(criticalStage.value, [...trace, ...criticalStage.trace]);
}

TracedValue _randomDamage(int damage, int roll) {
  final after = unsigned32(damage * roll) ~/ 100;
  return TracedValue(after, [
    ModifierTrace('Random', ModifierStage.damage, roll, 100, damage, after),
  ]);
}

TracedValue _stabDamage(DamageEffectsContext context, int damage) {
  final stab = calculateStab(context);
  return _conditionalDamageModifier('STAB', damage, stab, stab != 4096);
}

TracedValue _typeDamage(int damage, double effectiveness) {
  final after = unsigned32((damage * effectiveness).floor());
  return TracedValue(after, [
    ModifierTrace(
      'Type',
      ModifierStage.damage,
      effectiveness,
      1,
      damage,
      after,
    ),
  ]);
}

TracedValue _burnDamageModifier(DamageEffectsContext context, int damage) =>
    context.physical &&
        context.attacker.status == Status.burn &&
        context.attackerAbility != AbilityId.guts &&
        context.move.id != MoveId.facade
    ? applyFixedPointModifier('Burn', ModifierStage.damage, damage, 2048)
    : TracedValue(damage, const []);

TracedValue _finalDamageModifier(int damage, int modifier) =>
    _applyDamageModifier(
      'FinalModifiers',
      ModifierStage.damage,
      damage,
      modifier,
    );

TracedValue calculateDamageRoll(
  DamageEffectsContext context,
  int baseDamage,
  int roll,
  double effectiveness,
  int finalModifier,
) {
  var damage = baseDamage;
  final trace = <ModifierTrace>[];
  // 乱数→一致→相性→やけど→最終補正の順に、その段階の丸めを確定させる。
  final random = _randomDamage(damage, roll);
  damage = random.value;
  trace.addAll(random.trace);
  final stab = _stabDamage(context, damage);
  damage = stab.value;
  trace.addAll(stab.trace);
  final type = _typeDamage(damage, effectiveness);
  damage = type.value;
  trace.addAll(type.trace);
  final burn = _burnDamageModifier(context, damage);
  damage = burn.value;
  trace.addAll(burn.trace);
  final finalDamage = _finalDamageModifier(damage, finalModifier);
  return TracedValue(
    effectiveness == 0 ? 0 : unsigned16(math.max(1, finalDamage.value)),
    [...trace, ...finalDamage.trace],
  );
}
