import '../battle_effects.dart';
import '../models/dto.dart';
import '../models/value_objects.dart';
import 'calculation_context.dart';
import 'common_modifier.dart';
import 'stat_modifier.dart';

// わざわいのたま
RuleModifier? _beadsOfRuinDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.beadsofRuin.value,
      3072,
      // 防御側がわざわいのたまの場合は反映しない
      !context.physicalDefense &&
          context.activeDefenderAbility != AbilityId.beadsofRuin &&
          (context.attackerAbility == AbilityId.beadsofRuin ||
              context.field(FieldEffect.beadsOfRuin)),
    );

// わざわいのつるぎ
RuleModifier? _swordOfRuinDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.swordofRuin.value,
      3072,
      // 防御側がわざわいのつるぎの場合は反映しない
      context.physicalDefense &&
          context.activeDefenderAbility != AbilityId.swordofRuin &&
          (context.attackerAbility == AbilityId.swordofRuin ||
              context.field(FieldEffect.swordOfRuin)),
    );

// こだいかっせい・クォークチャージ
RuleModifier? _paradoxDefenseModifier(
  DamageEffectsContext context,
  Stat stat,
) => modifierWhen(
  context.defenderAbility?.value ?? 'Paradox',
  5324,
  isParadoxBoostedStat(
    context,
    context.defender,
    context.defenderAbility,
    context.defenderItem,
    stat,
  ),
);

// フラワーギフト
RuleModifier? _flowerGiftDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.flowerGift.value,
      6144,
      !context.physicalDefense &&
          context.weather == Weather.sunlight &&
          (context.defenderAbility == AbilityId.flowerGift ||
              context.field(FieldEffect.defenderFlowerGift)),
    );

// ふしぎなうろこ
RuleModifier? _marvelScaleDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.marvelScale.value,
      6144,
      context.defenderAbility == AbilityId.marvelScale &&
          context.physicalDefense &&
          context.defender.status != null,
    );

// くさのけがわ
RuleModifier? _grassPeltDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.grassPelt.value,
      6144,
      context.defenderAbility == AbilityId.grassPelt &&
          context.physicalDefense &&
          context.terrain == Terrain.grass,
    );

// ファーコート
RuleModifier? _furCoatDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      AbilityId.furCoat.value,
      8192,
      context.defenderAbility == AbilityId.furCoat && context.physicalDefense,
    );

// しんかのきせき
RuleModifier? _evioliteDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.eviolite.value,
      6144,
      context.defenderItem == ItemId.eviolite &&
          pokemonFlag(context.defender, PokemonFlag.canEvolve),
    );

// とつげきチョッキ
RuleModifier? _assaultVestDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.assaultVest.value,
      6144,
      context.defenderItem == ItemId.assaultVest && !context.physicalDefense,
    );

// しんかいのウロコ
RuleModifier? _deepSeaScaleDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.deepSeaScale.value,
      8192,
      context.defenderItem == ItemId.deepSeaScale &&
          context.defender.id == PokemonId.clamperl &&
          !context.physicalDefense,
    );

// メタルパウダー
RuleModifier? _metalPowderDefenseModifier(DamageEffectsContext context) =>
    modifierWhen(
      ItemId.metalPowder.value,
      8192,
      context.defenderItem == ItemId.metalPowder &&
          context.defender.id == PokemonId.ditto &&
          context.physicalDefense &&
          !pokemonFlag(context.defender, PokemonFlag.transformed),
    );

ModifierChain calculateDefenseModifiers(
  DamageEffectsContext context,
  Stat stat,
) {
  final modifierChain = ModifierChain(
    name: 'defense',
    modifierStage: ModifierStage.defenseModifier,
    valueStage: ModifierStage.defense,
  );
  final orderedRules = [
    _beadsOfRuinDefenseModifier(context),
    _swordOfRuinDefenseModifier(context),
    _paradoxDefenseModifier(context, stat),
    _flowerGiftDefenseModifier(context),
    _marvelScaleDefenseModifier(context),
    _grassPeltDefenseModifier(context),
    _furCoatDefenseModifier(context),
    _evioliteDefenseModifier(context),
    _assaultVestDefenseModifier(context),
    _deepSeaScaleDefenseModifier(context),
    _metalPowderDefenseModifier(context),
  ];
  for (final rule in orderedRules) {
    modifierChain.addRule(rule);
  }
  return modifierChain;
}
