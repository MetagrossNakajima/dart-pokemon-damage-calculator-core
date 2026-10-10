import '../battle_effects.dart';
import '../models/dto.dart';
import '../models/value_objects.dart';
import 'calculation_context.dart';
import 'common_modifier.dart';
import 'stat_modifier.dart';

// スロースタート
RuleModifier? _slowStartAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.slowStart.value,
      2048,
      context.attackerAbility == AbilityId.slowStart &&
          context.physical &&
          pokemonFlag(context.attacker, PokemonFlag.slowStart, true),
    );

// よわき
RuleModifier? _defeatistAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.defeatist.value,
      2048,
      context.attackerAbility == AbilityId.defeatist &&
          context.hp(context.attacker) * 2 <=
              context.attacker.stats[Stat.hp].value,
    );

// わざわいのうつわ
RuleModifier? _vesselOfRuinAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.vesselofRuin.value,
      3072,
      // 攻撃側がわざわいのうつわの場合、反映しない
      !context.physical &&
          context.attackerAbility != AbilityId.vesselofRuin &&
          (context.activeDefenderAbility == AbilityId.vesselofRuin ||
              context.field(FieldEffect.vesselOfRuin)),
    );

// わざわいのおふだ
RuleModifier? _tabletsOfRuinAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.tabletsofRuin.value,
      3072,
      // 攻撃側がわざわいのおふだの場合、反映しない
      context.physical &&
          context.attackerAbility != AbilityId.tabletsofRuin &&
          (context.activeDefenderAbility == AbilityId.tabletsofRuin ||
              context.field(FieldEffect.tabletsOfRuin)),
    );

// こだいかっせい・クォークチャージ
RuleModifier? _paradoxAttackModifier(DamageEffectsContext context, Stat stat) =>
    modifierWhen(
      context.attackerAbility?.value ?? 'Paradox',
      5325,
      isParadoxBoostedStat(
        context,
        context.attacker,
        context.attackerAbility,
        context.attackerItem,
        stat,
      ),
    );

// トランジスタ
RuleModifier? _transistorAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.transistor.value,
      5325,
      context.attackerAbility == AbilityId.transistor &&
          context.move.type == TeraType.electric,
    );

// ハドロンエンジン
RuleModifier? _hadronEngineAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.hadronEngine.value,
      5461,
      context.attackerAbility == AbilityId.hadronEngine &&
          context.terrain == Terrain.electric &&
          !context.physical,
    );

// ひひいろのこどう
RuleModifier? _orichalcumPulseAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.orichalcumPulse.value,
      5461,
      context.attackerAbility == AbilityId.orichalcumPulse &&
          context.weather == Weather.sunlight &&
          context.attackerItem != ItemId.utilityUmbrella &&
          context.physical,
    );

// フラワーギフト
RuleModifier? _flowerGiftAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.flowerGift.value,
      6144,
      context.physical &&
          context.weather == Weather.sunlight &&
          (context.attackerAbility == AbilityId.flowerGift ||
              context.field(FieldEffect.attackerFlowerGift)),
    );

// こんじょう
RuleModifier? _gutsAttackModifier(DamageEffectsContext context) => modifierWhen(
  AbilityId.guts.value,
  6144,
  context.attackerAbility == AbilityId.guts &&
      context.physical &&
      context.attacker.status != null,
);

// しんりょく・もうか・げきりゅう・むしのしらせ
RuleModifier? _lowHpAbilityAttackModifier(DamageEffectsContext context) {
  final boostedType = {
    AbilityId.overgrow: TeraType.grass,
    AbilityId.blaze: TeraType.fire,
    AbilityId.torrent: TeraType.water,
    AbilityId.swarm: TeraType.bug,
  }[context.attackerAbility];
  return modifierWhen(
    context.attackerAbility?.value ?? 'LowHpAbility',
    6144,
    boostedType == context.move.type &&
        context.hp(context.attacker) * 3 <=
            context.attacker.stats[Stat.hp].value,
  );
}

// もらいび
RuleModifier? _flashFireAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.flashFire.value,
      6144,
      context.attackerAbility == AbilityId.flashFire &&
          context.move.type == TeraType.fire &&
          pokemonFlag(context.attacker, PokemonFlag.flashFire),
    );

// サンパワー
RuleModifier? _solarPowerAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.solarPower.value,
      6144,
      context.attackerAbility == AbilityId.solarPower &&
          !context.physical &&
          context.weather == Weather.sunlight,
    );

// プラス・マイナス
RuleModifier? _plusMinusAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.attackerAbility?.value ?? 'PlusMinus',
      6144,
      {AbilityId.plus, AbilityId.minus}.contains(context.attackerAbility) &&
          !context.physical &&
          pokemonFlag(context.attacker, PokemonFlag.plusMinusAlly),
    );

// タイプ強化特性
RuleModifier? _typeAbilityAttackModifier(DamageEffectsContext context) {
  final boostedType = {
    AbilityId.rockyPayload: TeraType.rock,
    AbilityId.steelworker: TeraType.steel,
    AbilityId.fireMane: TeraType.fire,
    AbilityId.dragonsMaw: TeraType.dragon,
  }[context.attackerAbility];
  return modifierWhen(
    context.attackerAbility?.value ?? 'TypeAbility',
    6144,
    boostedType == context.move.type,
  );
}

// ごりむちゅう
RuleModifier? _gorillaTacticsAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.gorillaTactics.value,
      6144,
      context.attackerAbility == AbilityId.gorillaTactics && context.physical,
    );

// ちからもち・ヨガパワー
RuleModifier? _hugePowerAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.attackerAbility?.value ?? AbilityId.hugePower.value,
      8192,
      {
            AbilityId.hugePower,
            AbilityId.purePower,
          }.contains(context.attackerAbility) &&
          context.physical,
    );

// すいほう
RuleModifier? _attackerWaterBubbleAttackModifier(
  DamageEffectsContext context,
) => modifierWhen(
  AbilityId.waterBubble.value,
  8192,
  context.attackerAbility == AbilityId.waterBubble &&
      context.move.type == TeraType.water,
);

// はりこみ
RuleModifier? _stakeoutAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.stakeout.value,
      8192,
      context.attackerAbility == AbilityId.stakeout &&
          pokemonFlag(context.defender, PokemonFlag.switchedIn),
    );

// あついしぼう
RuleModifier? _thickFatAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.thickFat.value,
      2048,
      context.defenderAbility == AbilityId.thickFat &&
          {TeraType.fire, TeraType.ice}.contains(context.move.type),
    );

// たいねつ
RuleModifier? _heatproofAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.heatproof.value,
      2048,
      context.defenderAbility == AbilityId.heatproof &&
          context.move.type == TeraType.fire,
    );

// すいほう
RuleModifier? _defenderWaterBubbleAttackModifier(
  DamageEffectsContext context,
) => modifierWhen(
  'DefenderWaterBubble',
  2048,
  context.defenderAbility == AbilityId.waterBubble &&
      context.move.type == TeraType.fire,
);

// きよめのしお
RuleModifier? _purifyingSaltAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.purifyingSalt.value,
      2048,
      context.defenderAbility == AbilityId.purifyingSalt &&
          context.move.type == TeraType.ghost,
    );

// こだわりハチマキ・こだわりメガネ
RuleModifier? _choiceItemAttackModifier(DamageEffectsContext context) {
  final choiceItem = context.physical ? ItemId.choiceBand : ItemId.choiceSpecs;
  return modifierWhen(
    context.attackerItem?.value ?? 'Choice',
    6144,
    context.attackerItem == choiceItem,
  );
}

// ふといホネ
RuleModifier? _thickClubAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.thickClub.value,
      8192,
      context.attackerItem == ItemId.thickClub &&
          {
            PokemonId.marowak,
            PokemonId.marowakAlola,
            PokemonId.cubone,
          }.contains(context.attacker.id) &&
          context.physical,
    );

// しんかいのキバ
RuleModifier? _deepSeaToothAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.deepSeaTooth.value,
      8192,
      context.attackerItem == ItemId.deepSeaTooth &&
          context.attacker.id == PokemonId.clamperl &&
          !context.physical,
    );

// でんきだま
RuleModifier? _lightBallAttackModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.lightBall.value,
      8192,
      context.attackerItem == ItemId.lightBall &&
          context.attacker.id == PokemonId.pikachu,
    );

ModifierChain calculateAttackModifiers(DamageEffectsContext context) {
  final modifierChain = ModifierChain(
    name: 'attack',
    modifierStage: ModifierStage.attackModifier,
    valueStage: ModifierStage.attack,
  );
  final orderedRules = [
    _slowStartAttackModifier(context),
    _defeatistAttackModifier(context),
    _vesselOfRuinAttackModifier(context),
    _tabletsOfRuinAttackModifier(context),
    _paradoxAttackModifier(context, context.physical ? Stat.atk : Stat.spa),
    _transistorAttackModifier(context),
    _hadronEngineAttackModifier(context),
    _orichalcumPulseAttackModifier(context),
    _flowerGiftAttackModifier(context),
    _gutsAttackModifier(context),
    _lowHpAbilityAttackModifier(context),
    _flashFireAttackModifier(context),
    _solarPowerAttackModifier(context),
    _plusMinusAttackModifier(context),
    _typeAbilityAttackModifier(context),
    _gorillaTacticsAttackModifier(context),
    _hugePowerAttackModifier(context),
    _attackerWaterBubbleAttackModifier(context),
    _stakeoutAttackModifier(context),
    modifierWhen(
      'AllySteelySpirit',
      6144,
      context.field(FieldEffect.steelySpirit) &&
          context.move.type == TeraType.steel,
    ),
    _thickFatAttackModifier(context),
    _heatproofAttackModifier(context),
    _defenderWaterBubbleAttackModifier(context),
    _purifyingSaltAttackModifier(context),
    _choiceItemAttackModifier(context),
    _thickClubAttackModifier(context),
    _deepSeaToothAttackModifier(context),
    _lightBallAttackModifier(context),
  ];
  for (final rule in orderedRules) {
    modifierChain.addRule(rule);
  }
  return modifierChain;
}
