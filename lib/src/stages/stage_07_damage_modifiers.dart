import '../models/dto.dart';
import '../models/value_objects.dart';
import '../rules/item_rules.dart';
import 'calculation_context.dart';
import 'common_modifier.dart';

// 急所と壁破壊技は壁補正を通さない。壁は防御参照値ではなく技の分類で選ぶ。
// リフレクター・ひかりのかべ
RuleModifier? _screenDamageModifier(
  DamageEffectsContext context,
  bool critical,
) => modifierWhen(
  'Screen',
  context.battleField.format == BattleFormat.single ? 2048 : 2732,
  !critical &&
      context.attackerAbility != AbilityId.infiltrator &&
      !{
        MoveId.brickBreak,
        MoveId.ragingBull,
        MoveId.psychicFangs,
      }.contains(context.move.id) &&
      (context.physical
          ? context.defender.reflect
          : context.defender.lightScreen),
);

// ブレインフォース
RuleModifier? _neuroforceDamageModifier(
  DamageEffectsContext context,
  double effectiveness,
) => modifierWhen(
  AbilityId.neuroforce.value,
  5120,
  context.attackerAbility == AbilityId.neuroforce && effectiveness > 1,
);

// スナイパー
RuleModifier? _sniperDamageModifier(
  DamageEffectsContext context,
  bool critical,
) => modifierWhen(
  AbilityId.sniper.value,
  6144,
  context.attackerAbility == AbilityId.sniper && critical,
);

// いろめがね
RuleModifier? _tintedLensDamageModifier(
  DamageEffectsContext context,
  double effectiveness,
) => modifierWhen(
  AbilityId.tintedLens.value,
  8192,
  context.attackerAbility == AbilityId.tintedLens && effectiveness < 1,
);

// マルチスケイル・ファントムガード
RuleModifier? _fullHpDamageModifier(DamageEffectsContext context) =>
    modifierWhen(
      context.defenderAbility?.value ?? 'FullHp',
      2048,
      context.hitIndex == 0 &&
          {
            AbilityId.multiscale,
            AbilityId.shadowShield,
          }.contains(context.defenderAbility),
    );

// 接触軽減と炎の倍化は独立して連結するため、接触する炎技では両方が成立する。
// もふもふ
RuleModifier? _fluffyContactDamageModifier(DamageEffectsContext context) =>
    modifierWhen(
      'FluffyContact',
      2048,
      context.defenderAbility == AbilityId.fluffy && context.contact,
    );

// はどうのぼうご
RuleModifier? _waveShieldDamageModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.waveShield.value,
      2048,
      context.defenderAbility == AbilityId.waveShield && context.contact,
    );

// パンクロック
RuleModifier? _punkRockDamageModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.punkRock.value,
      2048,
      context.defenderAbility == AbilityId.punkRock &&
          context.flag(MoveFlag.sound),
    );

// こおりのりんぷん
RuleModifier? _iceScalesDamageModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.iceScales.value,
      2048,
      context.defenderAbility == AbilityId.iceScales && !context.physical,
    );

// フレンドガード
RuleModifier? _friendGuardDamageModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.friendGuard.value,
      3072,
      context.field(FieldEffect.friendGuard),
    );

// ハードロック・フィルター・プリズムアーマー
RuleModifier? _solidRockDamageModifier(
  DamageEffectsContext context,
  double effectiveness,
) => modifierWhen(
  context.defenderAbility?.value ?? AbilityId.solidRock.value,
  3072,
  {
        AbilityId.solidRock,
        AbilityId.filter,
        AbilityId.prismArmor,
      }.contains(context.defenderAbility) &&
      effectiveness > 1,
);

// もふもふ
RuleModifier? _fluffyFireDamageModifier(DamageEffectsContext context) =>
    modifierWhen(
      'FluffyFire',
      8192,
      context.defenderAbility == AbilityId.fluffy &&
          context.move.type == TeraType.fire,
    );

// たつじんのおび
RuleModifier? _expertBeltDamageModifier(
  DamageEffectsContext context,
  double effectiveness,
) => modifierWhen(
  ItemId.expertBelt.value,
  4915,
  context.attackerItem == ItemId.expertBelt && effectiveness > 1,
);

// いのちのたま
RuleModifier? _lifeOrbDamageModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.lifeOrb.value,
      5324,
      context.attackerItem == ItemId.lifeOrb,
    );

// ノーマルの半減きのみだけは等倍以下でも対象。きんちょうかんは消費と補正を防ぐ。
// 半減きのみ
RuleModifier? _resistBerryDamageModifier(
  DamageEffectsContext context,
  double effectiveness,
) => modifierWhen(
  context.defenderItem?.value ?? 'Berry',
  context.defenderAbility == AbilityId.ripen ? 1024 : 2048,
  context.hitIndex == 0 &&
      resistBerries[context.defenderItem] == context.move.type &&
      (effectiveness > 1 || context.move.type == TeraType.normal) &&
      !context.unnerveActive,
);

TracedValue calculateFinalModifier(
  DamageEffectsContext context,
  bool critical,
  double effectiveness,
) {
  final modifierChain = ModifierChain(
    name: 'damage',
    modifierStage: ModifierStage.damageModifier,
  );
  final orderedRules = [
    _screenDamageModifier(context, critical),
    _neuroforceDamageModifier(context, effectiveness),
    _sniperDamageModifier(context, critical),
    _tintedLensDamageModifier(context, effectiveness),
    _fullHpDamageModifier(context),
    _fluffyContactDamageModifier(context),
    _waveShieldDamageModifier(context),
    _punkRockDamageModifier(context),
    _iceScalesDamageModifier(context),
    _friendGuardDamageModifier(context),
    _solidRockDamageModifier(context, effectiveness),
    _fluffyFireDamageModifier(context),
    _expertBeltDamageModifier(context, effectiveness),
    _lifeOrbDamageModifier(context),
    _resistBerryDamageModifier(context, effectiveness),
  ];
  for (final rule in orderedRules) {
    modifierChain.addRule(rule);
  }
  return modifierChain.finish();
}
