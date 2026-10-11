import '../models/dto.dart';
import '../models/value_objects.dart';
import '../rules/type_chart.dart';
import 'calculation_context.dart';

// ステラタイプ
double? _stellarEffectiveness(DamageEffectsContext context) =>
    context.move.type == TeraType.stellar
    ? context.defender.teraType == null
          ? 1
          : 2
    : null;

// じゅうりょく・くろいてっきゅう・サウザンアロー
double _groundedFlyingFactor(
  DamageEffectsContext context,
  PokemonType defenderType,
  double factor,
) =>
    context.move.type == TeraType.ground &&
        defenderType == PokemonType.flying &&
        (context.battleField.gravity ||
            context.defender.flags[PokemonFlag.grounded] == true)
    ? 1
    : factor;

// きもったま・しんがん
double _scrappyFactor(
  DamageEffectsContext context,
  PokemonType defenderType,
  double factor,
) =>
    {AbilityId.scrappy, AbilityId.mindsEye}.contains(context.attackerAbility) &&
        {TeraType.normal, TeraType.fighting}.contains(context.move.type) &&
        defenderType == PokemonType.ghost
    ? 1
    : factor;

// ねらいのまと
double _ringTargetFactor(
  DamageEffectsContext context,
  PokemonType defenderType,
  double factor,
) => factor == 0 && context.defenderItem == ItemId.ringTarget ? 1 : factor;

// フリーズドライ
double _freezeDryFactor(
  DamageEffectsContext context,
  PokemonType defenderType,
  double factor,
) => context.move.id == MoveId.freezeDry && defenderType == PokemonType.water
    ? 2
    : factor;

// フライングプレス
double _flyingPressFactor(
  DamageEffectsContext context,
  PokemonType defenderType,
) => context.move.id == MoveId.flyingPress
    ? typeEffectiveness(PokemonType.flying, defenderType)
    : 1;

// 浮遊・Eelevate・ふうせん由来の無効。ひこうタイプの無効は相性表で扱う。
bool _groundAirborneImmunity(DamageEffectsContext context, double _) =>
    context.move.type == TeraType.ground &&
    context.move.id != MoveId.thousandArrows &&
    !context.defenderGrounded &&
    ({
          AbilityId.levitate,
          AbilityId.eelevate,
        }.contains(context.defenderAbility) ||
        context.defenderItem == ItemId.airBalloon);

// もらいび・こんがりボディ
bool _fireAbsorbImmunity(DamageEffectsContext context, double _) =>
    context.move.type == TeraType.fire &&
    {
      AbilityId.flashFire,
      AbilityId.wellBakedBody,
    }.contains(context.defenderAbility);

// どしょく。浮遊由来の無効と異なり、じゅうりょくやサウザンアローでも有効。
bool _earthEaterImmunity(DamageEffectsContext context, double _) =>
    context.move.type == TeraType.ground &&
    context.defenderAbility == AbilityId.earthEater;

// ちょすい・よびみず・かんそうはだ
bool _waterAbsorbImmunity(DamageEffectsContext context, double _) =>
    context.move.type == TeraType.water &&
    {
      AbilityId.waterAbsorb,
      AbilityId.stormDrain,
      AbilityId.drySkin,
    }.contains(context.defenderAbility);

// ちくでん・ひらいしん・でんきエンジン
bool _electricAbsorbImmunity(DamageEffectsContext context, double _) =>
    context.move.type == TeraType.electric &&
    {
      AbilityId.voltAbsorb,
      AbilityId.lightningRod,
      AbilityId.motorDrive,
    }.contains(context.defenderAbility);

// そうしょく
bool _grassAbsorbImmunity(DamageEffectsContext context, double _) =>
    context.move.type == TeraType.grass &&
    context.defenderAbility == AbilityId.sapSipper;

// ぼうおん
bool _soundproofImmunity(DamageEffectsContext context, double _) =>
    context.flag(MoveFlag.sound) &&
    context.defenderAbility == AbilityId.soundproof;

// ぼうだん
bool _bulletproofImmunity(DamageEffectsContext context, double _) =>
    context.flag(MoveFlag.bullet) &&
    context.defenderAbility == AbilityId.bulletproof;

// かぜのり
bool _windRiderImmunity(DamageEffectsContext context, double _) =>
    context.flag(MoveFlag.wind) &&
    context.defenderAbility == AbilityId.windRider;

// ふしぎなまもり
bool _wonderGuardImmunity(DamageEffectsContext context, double effectiveness) =>
    context.defenderAbility == AbilityId.wonderGuard && effectiveness <= 1;

double calculateTypeEffectiveness(DamageEffectsContext context) {
  final stellar = _stellarEffectiveness(context);
  if (stellar != null) return stellar;
  final types = context.defenderTypes;
  final orderedFactorRules = [
    _groundedFlyingFactor,
    _scrappyFactor,
    _ringTargetFactor,
    _freezeDryFactor,
  ];
  var result = 1.0;
  for (final type in types) {
    var factor = typeEffectiveness(context.move.type.pokemonType!, type);
    for (final rule in orderedFactorRules) {
      factor = rule(context, type, factor);
    }
    result = result * factor;
    result = result * _flyingPressFactor(context, type);
  }
  if (result == 0 &&
      context.move.type == TeraType.ground &&
      (context.defenderItem == ItemId.ironBall ||
          context.move.id == MoveId.thousandArrows)) {
    return 1;
  }
  return result;
}

double calculateEffectiveness(DamageEffectsContext context) {
  var result = calculateTypeEffectiveness(context);
  if (result != 0 && context.defenderAbility == AbilityId.teraShell) {
    result = 0.5;
  }
  // タイプごとの例外を反映してから特性無効を判定し、ふしぎなまもりは合成相性を見る。
  final orderedImmunityRules = [
    _groundAirborneImmunity,
    _earthEaterImmunity,
    _fireAbsorbImmunity,
    _waterAbsorbImmunity,
    _electricAbsorbImmunity,
    _grassAbsorbImmunity,
    _soundproofImmunity,
    _bulletproofImmunity,
    _windRiderImmunity,
    _wonderGuardImmunity,
  ];
  if (orderedImmunityRules.any((rule) => rule(context, result))) {
    return 0;
  }
  return result;
}
