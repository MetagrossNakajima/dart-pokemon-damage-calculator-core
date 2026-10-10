import '../battle_effects.dart';

import '../models/dto.dart';
import '../models/value_objects.dart';
import '../rules/ability_rules.dart';
import '../rules/item_rules.dart';
import 'calculation_context.dart';
import 'common_modifier.dart';
import 'type_effectiveness.dart';
import 'dart:math' as math;

// スキン系特性
RuleModifier? _skinPowerModifier(DamageEffectsContext context) {
  final move = context.move;
  // ウェザーボールは天候がなくてもスキン系の対象外。固有のタイプ変化と強化を重ねない。
  final convertible =
      !(move.id == MoveId.weatherBall ||
          (move.id == MoveId.terrainPulse && context.terrain != null) ||
          (move.id == MoveId.teraBlast && context.attacker.teraType != null));
  final converted =
      convertible &&
      (context.attackerAbility == AbilityId.normalize ||
          (skinTypes.containsKey(context.attackerAbility) &&
              context.originalMove.type == PokemonType.normal &&
              move.type == skinTypes[context.attackerAbility]));
  return modifierWhen(
    context.attackerAbility?.value ?? 'Skin',
    4915,
    converted,
  );
}

// フェアリーオーラ・ダークオーラ・オーラブレイク
RuleModifier? _auraPowerModifier(DamageEffectsContext context) {
  final aura = context.move.type == TeraType.fairy
      ? AbilityId.fairyAura
      : context.move.type == TeraType.dark
      ? AbilityId.darkAura
      : null;
  final active =
      aura != null &&
      (context.attackerAbility == aura ||
          context.activeDefenderAbility == aura ||
          context.field(
            aura == AbilityId.fairyAura
                ? FieldEffect.fairyAura
                : FieldEffect.darkAura,
          ));
  final broken =
      context.attackerAbility == AbilityId.auraBreak ||
      context.defenderAbility == AbilityId.auraBreak ||
      context.field(FieldEffect.auraBreak);
  return modifierWhen(
    broken ? AbilityId.auraBreak.value : aura?.value ?? 'Aura',
    broken ? 3072 : 5448,
    active,
  );
}

// とうそうしん
RuleModifier? _rivalryPowerModifier(DamageEffectsContext context) {
  final applies =
      context.attackerAbility == AbilityId.rivalry &&
      context.attacker.gender != Gender.genderless &&
      context.defender.gender != Gender.genderless;
  return modifierWhen(
    AbilityId.rivalry.value,
    context.attacker.gender == context.defender.gender ? 5120 : 3072,
    applies,
  );
}

// そうだいしょう
RuleModifier? _supremeOverlordPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.supremeOverlord.value,
      [4096, 4506, 4915, 5325, 5734, 6144][math.min(
        5,
        context.attacker.faintedAllies.value,
      )],
      context.attackerAbility == AbilityId.supremeOverlord &&
          context.attacker.faintedAllies.value > 0,
    );

// てつのこぶし
RuleModifier? _ironFistPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.ironFist.value,
      4915,
      context.attackerAbility == AbilityId.ironFist &&
          context.flag(MoveFlag.punch),
    );

// すてみ
RuleModifier? _recklessPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.reckless.value,
      4915,
      context.attackerAbility == AbilityId.reckless &&
          context.flag(MoveFlag.recoil),
    );

// バッテリー
RuleModifier? _batteryPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.battery.value,
      5325,
      context.field(FieldEffect.battery) && !context.physical,
    );

// ちからずく
RuleModifier? _sheerForcePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.sheerForce.value,
      5325,
      context.attackerAbility == AbilityId.sheerForce &&
          context.flag(MoveFlag.sheerForce),
    );

// すなのちから
RuleModifier? _sandForcePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.sandForce.value,
      5325,
      context.attackerAbility == AbilityId.sandForce &&
          context.weather == Weather.sandstorm &&
          {
            TeraType.ground,
            TeraType.rock,
            TeraType.steel,
          }.contains(context.move.type),
    );

// アナライズ
RuleModifier? _analyticPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.analytic.value,
      5325,
      context.attackerAbility == AbilityId.analytic &&
          !pokemonFlag(context.attacker, PokemonFlag.movesFirst),
    );

// かたいツメ
RuleModifier? _toughClawsPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.toughClaws.value,
      5325,
      context.attackerAbility == AbilityId.toughClaws && context.contact,
    );

// パンクロック
RuleModifier? _punkRockPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.punkRock.value,
      5325,
      context.attackerAbility == AbilityId.punkRock &&
          context.flag(MoveFlag.sound),
    );

// パワースポット
RuleModifier? _powerSpotPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.powerSpot.value,
      5325,
      context.field(FieldEffect.powerSpot),
    );

// きれあじ
RuleModifier? _sharpnessPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.sharpness.value,
      6144,
      context.attackerAbility == AbilityId.sharpness &&
          context.flag(MoveFlag.sharpness),
    );

// テクニシャン
RuleModifier? _technicianPowerModifier(
  DamageEffectsContext context,
  int power,
) => modifierWhen(
  AbilityId.technician.value,
  6144,
  context.attackerAbility == AbilityId.technician && power <= 60,
);

// ねつぼうそう
RuleModifier? _flareBoostPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.flareBoost.value,
      6144,
      context.attackerAbility == AbilityId.flareBoost &&
          !context.physical &&
          context.attacker.status == Status.burn,
    );

// どくぼうそう
RuleModifier? _toxicBoostPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.toxicBoost.value,
      6144,
      context.attackerAbility == AbilityId.toxicBoost &&
          context.physical &&
          {Status.poison, Status.toxic}.contains(context.attacker.status),
    );

// がんじょうあご
RuleModifier? _strongJawPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.strongJaw.value,
      6144,
      context.attackerAbility == AbilityId.strongJaw &&
          context.flag(MoveFlag.bite),
    );

// メガランチャー
RuleModifier? _megaLauncherPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.megaLauncher.value,
      6144,
      context.attackerAbility == AbilityId.megaLauncher &&
          context.flag(MoveFlag.pulse),
    );

// はがねのせいしん
RuleModifier? _steelySpiritPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.steelySpirit.value,
      6144,
      context.attackerAbility == AbilityId.steelySpirit &&
          context.move.type == TeraType.steel,
    );

// サイコブレイド
RuleModifier? _psybladePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.psyblade.value,
      6144,
      context.move.id == MoveId.psyblade && context.terrain == Terrain.electric,
    );

// かんそうはだ
RuleModifier? _drySkinPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.drySkin.value,
      5120,
      context.defenderAbility == AbilityId.drySkin &&
          context.move.type == TeraType.fire,
    );

// ちからのハチマキ
RuleModifier? _muscleBandPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.muscleBand.value,
      4505,
      context.attackerItem == ItemId.muscleBand && context.physical,
    );

// ものしりメガネ
RuleModifier? _wiseGlassesPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.wiseGlasses.value,
      4505,
      context.attackerItem == ItemId.wiseGlasses && !context.physical,
    );

// パンチグローブ
RuleModifier? _punchingGlovePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.punchingGlove.value,
      4506,
      context.attackerItem == ItemId.punchingGlove &&
          context.flag(MoveFlag.punch),
    );

// タイプ強化道具
RuleModifier? _typeItemPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.attackerItem?.value ?? 'TypeItem',
      4915,
      typeItems[context.attackerItem] == context.move.type,
    );

// こんごうだま・だいこんごうだま
RuleModifier? _adamantOrbPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.attackerItem?.value ?? ItemId.adamantOrb.value,
      4915,
      {
            PokemonId.dialga,
            PokemonId.dialgaOrigin,
          }.contains(context.attacker.id) &&
          {
            ItemId.adamantOrb,
            ItemId.adamantCrystal,
          }.contains(context.attackerItem) &&
          {TeraType.steel, TeraType.dragon}.contains(context.move.type),
    );

// しらたま・だいしらたま
RuleModifier? _lustrousOrbPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.attackerItem?.value ?? ItemId.lustrousOrb.value,
      4915,
      {
            PokemonId.palkia,
            PokemonId.palkiaOrigin,
          }.contains(context.attacker.id) &&
          {
            ItemId.lustrousOrb,
            ItemId.lustrousGlobe,
          }.contains(context.attackerItem) &&
          {TeraType.water, TeraType.dragon}.contains(context.move.type),
    );

// はっきんだま・だいはっきんだま
RuleModifier? _griseousOrbPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.attackerItem?.value ?? ItemId.griseousOrb.value,
      4915,
      {
            PokemonId.giratina,
            PokemonId.giratinaOrigin,
          }.contains(context.attacker.id) &&
          {
            ItemId.griseousOrb,
            ItemId.griseousCore,
          }.contains(context.attackerItem) &&
          {TeraType.ghost, TeraType.dragon}.contains(context.move.type),
    );

// こころのしずく
RuleModifier? _soulDewPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.attackerItem?.value ?? ItemId.soulDew.value,
      4915,
      {PokemonId.latias, PokemonId.latios}.contains(context.attacker.id) &&
          context.attackerItem == ItemId.soulDew &&
          {TeraType.psychic, TeraType.dragon}.contains(context.move.type),
    );

// ノーマルジュエル
RuleModifier? _normalGemPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.normalGem.value,
      5325,
      context.attackerItem == ItemId.normalGem &&
          context.move.type == TeraType.normal,
    );

// ソーラービーム・ソーラーブレード
RuleModifier? _solarMovePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      'Solar',
      2048,
      {MoveId.solarBeam, MoveId.solarBlade}.contains(context.move.id) &&
          context.weather != null &&
          context.weather != Weather.sunlight,
    );

// はたきおとす
RuleModifier? _knockOffPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.knockOff.value,
      6144,
      context.move.id == MoveId.knockOff &&
          context.defender.item != null &&
          !context.defender.itemConsumed &&
          pokemonFlag(context.defender, PokemonFlag.itemRemovable, true),
    );

// てだすけ
RuleModifier? _helpingHandPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.helpingHand.value,
      6144,
      context.field(FieldEffect.helpingHand),
    );

// Gのちから
RuleModifier? _gravApplePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.gravApple.value,
      6144,
      context.move.id == MoveId.gravApple && context.battleField.gravity,
    );

// ワイドフォース
RuleModifier? _expandingForcePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.expandingForce.value,
      6144,
      context.move.id == MoveId.expandingForce &&
          context.terrain == Terrain.psychic &&
          context.grounded,
    );

// じゅうでん
RuleModifier? _chargePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.charge.value,
      8192,
      context.move.type == TeraType.electric &&
          pokemonFlag(context.attacker, PokemonFlag.charge),
    );

// ライジングボルト
RuleModifier? _risingVoltagePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.risingVoltage.value,
      8192,
      context.move.id == MoveId.risingVoltage &&
          context.terrain == Terrain.electric &&
          context.defenderGrounded,
    );

// フィールドの攻撃強化は使用者の接地、軽減やライジングボルトは対象の接地を参照する。
// エレキフィールド・グラスフィールド
RuleModifier? _terrainPowerModifier(DamageEffectsContext context) {
  final boostedType = {
    Terrain.electric: TeraType.electric,
    Terrain.grass: TeraType.grass,
    Terrain.psychic: TeraType.psychic,
  }[context.terrain];
  return modifierWhen(
    'Terrain',
    5325,
    context.grounded && boostedType == context.move.type,
  );
}

// ミストフィールド
RuleModifier? _mistyTerrainPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.mistyTerrain.value,
      2048,
      context.terrain == Terrain.misty &&
          context.move.type == TeraType.dragon &&
          context.defenderGrounded,
    );

// グラスフィールド
RuleModifier? _grassyTerrainPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.grassyTerrain.value,
      2048,
      context.terrain == Terrain.grass &&
          {
            MoveId.earthquake,
            MoveId.bulldoze,
            MoveId.magnitude,
          }.contains(context.move.id) &&
          context.defenderGrounded,
    );

// どろあそび
RuleModifier? _mudSportPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.mudSport.value,
      1352,
      context.field(FieldEffect.mudSport) &&
          context.move.type == TeraType.electric,
    );

// みずあそび
RuleModifier? _waterSportPowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      MoveId.waterSport.value,
      1352,
      context.field(FieldEffect.waterSport) &&
          context.move.type == TeraType.fire,
    );

ModifierChain calculatePowerModifiers(
  DamageEffectsContext context,
  int unmodifiedPower,
) {
  final modifierChain = ModifierChain(
    name: 'power',
    modifierStage: ModifierStage.powerModifier,
    valueStage: ModifierStage.power,
  );
  final orderedRules = [
    _statusMovePowerModifier(context),
    _expandingForcePowerModifier(context),
    _knockOffPowerModifier(context),
    _gravApplePowerModifier(context),
    _solarMovePowerModifier(context),
    _collisionCoursePowerModifier(context),
    _helpingHandPowerModifier(context),
    _terrainPowerModifier(context),
    _mistyTerrainPowerModifier(context),
    _grassyTerrainPowerModifier(context),
    _technicianPowerModifier(context, unmodifiedPower),
    _flareBoostPowerModifier(context),
    _toxicBoostPowerModifier(context),
    _strongJawPowerModifier(context),
    _megaLauncherPowerModifier(context),
    _steelySpiritPowerModifier(context),
    _sharpnessPowerModifier(context),
    _chargePowerModifier(context),
    _auraPowerModifier(context),
    _sheerForcePowerModifier(context),
    _sandForcePowerModifier(context),
    _analyticPowerModifier(context),
    _toughClawsPowerModifier(context),
    _punkRockPowerModifier(context),
    _batteryPowerModifier(context),
    _powerSpotPowerModifier(context),
    _rivalryPowerModifier(context),
    _skinPowerModifier(context),
    _ironFistPowerModifier(context),
    _recklessPowerModifier(context),
    _drySkinPowerModifier(context),
    _supremeOverlordPowerModifier(context),
    _normalGemPowerModifier(context),
    _muscleBandPowerModifier(context),
    _wiseGlassesPowerModifier(context),
    _punchingGlovePowerModifier(context),
    _typeItemPowerModifier(context),
    _adamantOrbPowerModifier(context),
    _lustrousOrbPowerModifier(context),
    _griseousOrbPowerModifier(context),
    _soulDewPowerModifier(context),
    _psybladePowerModifier(context),
    _risingVoltagePowerModifier(context),
    _mudSportPowerModifier(context),
    _waterSportPowerModifier(context),
  ];
  for (final rule in orderedRules) {
    modifierChain.addRule(rule);
  }
  return modifierChain;
}

RuleModifier? _statusMovePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.move.id.value,
      8192,
      (context.move.id == MoveId.facade &&
              const {
                Status.burn,
                Status.poison,
                Status.toxic,
                Status.paralysis,
              }.contains(context.attacker.status)) ||
          (context.move.id == MoveId.brine &&
              context.hp(context.defender) <=
                  context.defender.stats.hp.value ~/ 2),
    );

RuleModifier? _collisionCoursePowerModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.move.id.value,
      5461,
      {MoveId.collisionCourse, MoveId.electroDrift}.contains(context.move.id) &&
          calculateTypeEffectiveness(context) > 1,
    );
