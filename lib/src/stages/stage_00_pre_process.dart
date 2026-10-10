import '../models/dto.dart';
import '../models/value_objects.dart';
import '../rules/ability_rules.dart';
import 'calculation_context.dart';
import 'common_modifier.dart';

final class PreparedMoveValues {
  const PreparedMoveValues({
    required this.type,
    required this.power,
    required this.category,
  });

  final TeraType type;
  final int power;
  final Category category;
}

final class EffectiveMove {
  const EffectiveMove({
    required this.id,
    required this.type,
    required this.power,
    required this.category,
    required this.spread,
    required this.flags,
    required this.priority,
  });

  final MoveId id;
  final TeraType type;
  final int power;
  final Category category;
  final bool spread;
  final Set<MoveFlag> flags;
  final int priority;
}

Category _adaptiveCategory(DamageEffectsContext context) =>
    rankedStat(
          context.attacker.stats.atk.value,
          context.attacker.stages.atk.value,
        ) >
        rankedStat(
          context.attacker.stats.spa.value,
          context.attacker.stages.spa.value,
        )
    ? Category.physical
    : Category.special;

// テラバースト
PreparedMoveValues? _teraBlastTransformation(DamageEffectsContext context) {
  if (context.originalMove.id != MoveId.teraBlast ||
      context.attacker.teraType == null) {
    return null;
  }
  final type = context.attacker.teraType!;
  // 分類はランク込みの攻撃・特攻で比較し、同値なら特殊。特性・道具補正は含めない。
  return PreparedMoveValues(
    type: type,
    power: type == TeraType.stellar ? 100 : 80,
    category: _adaptiveCategory(context),
  );
}

// テラクラスター
PreparedMoveValues? _teraStarstormTransformation(
  DamageEffectsContext context,
) =>
    context.originalMove.id == MoveId.teraStarstorm &&
        context.attacker.id == PokemonId.terapagosStellar
    ? PreparedMoveValues(
        type: TeraType.stellar,
        power: context.originalMove.power.value,
        category: context.attacker.teraType != null
            ? _adaptiveCategory(context)
            : context.originalMove.category,
      )
    : null;

// ウェザーボール
PreparedMoveValues? _weatherBallTransformation(DamageEffectsContext context) {
  // ばんのうがさは使用者に対する晴れ・雨の変化を防ぐが、砂・雪には作用しない。
  // MegaSolによる威力倍化は参照元の例外として維持する。
  if (context.originalMove.id != MoveId.weatherBall) return null;
  final umbrellaBlocksWeather =
      context.attackerItem == ItemId.utilityUmbrella &&
      {Weather.sunlight, Weather.rain}.contains(context.weather);
  // MegaSol下でも傘があれば、実際の砂・雪によるタイプ変化を参照する。
  final sandOrSnow = {
    Weather.sandstorm,
    Weather.snow,
  }.contains(context.battleField.weather);
  final typeWeather =
      context.attackerItem == ItemId.utilityUmbrella &&
          context.attackerAbility == AbilityId.megaSol &&
          context.weather == Weather.sunlight &&
          sandOrSnow
      ? context.battleField.weather
      : context.weather;
  final weatherType =
      {
        Weather.sunlight: TeraType.fire,
        Weather.rain: TeraType.water,
        Weather.sandstorm: TeraType.rock,
        Weather.snow: TeraType.ice,
      }[typeWeather] ??
      TeraType.of(context.originalMove.type);
  final type =
      context.attackerItem == ItemId.utilityUmbrella &&
          {Weather.sunlight, Weather.rain}.contains(typeWeather)
      ? TeraType.normal
      : weatherType;
  final doublesPower =
      context.weather != null &&
      (!umbrellaBlocksWeather || context.attackerAbility == AbilityId.megaSol);
  return PreparedMoveValues(
    type: type,
    power: context.originalMove.power.value * (doublesPower ? 2 : 1),
    category: context.originalMove.category,
  );
}

// だいちのはどう
PreparedMoveValues? _terrainPulseTransformation(DamageEffectsContext context) {
  if (context.originalMove.id != MoveId.terrainPulse ||
      context.terrain == null ||
      !context.grounded) {
    return null;
  }
  return PreparedMoveValues(
    type: {
      Terrain.electric: TeraType.electric,
      Terrain.grass: TeraType.grass,
      Terrain.misty: TeraType.fairy,
      Terrain.psychic: TeraType.psychic,
    }[context.terrain]!,
    power: context.originalMove.power.value * 2,
    category: context.originalMove.category,
  );
}

// レイジングブル
PreparedMoveValues? _ragingBullTransformation(DamageEffectsContext context) {
  if (context.originalMove.id != MoveId.ragingBull) return null;
  final type =
      {
        PokemonId.taurosPaldeaCombat: TeraType.fighting,
        PokemonId.taurosPaldeaBlaze: TeraType.fire,
        PokemonId.taurosPaldeaAqua: TeraType.water,
      }[context.attacker.id] ??
      TeraType.of(context.originalMove.type);
  return PreparedMoveValues(
    type: context.attackerAbility == AbilityId.normalize
        ? TeraType.normal
        : type,
    power: context.originalMove.power.value,
    category: context.originalMove.category,
  );
}

// ノーマルスキン
PreparedMoveValues? _normalizeTransformation(DamageEffectsContext context) =>
    context.attackerAbility == AbilityId.normalize
    ? PreparedMoveValues(
        type: TeraType.normal,
        power: context.originalMove.power.value,
        category: context.originalMove.category,
      )
    : null;

// エレキスキン・スカイスキン・フェアリースキン・フリーズスキン・ドラゴンスキン
PreparedMoveValues? _skinTransformation(DamageEffectsContext context) =>
    skinTypes.containsKey(context.attackerAbility) &&
        context.originalMove.type == PokemonType.normal
    ? PreparedMoveValues(
        type: skinTypes[context.attackerAbility]!,
        power: context.originalMove.power.value,
        category: context.originalMove.category,
      )
    : null;

// うるおいボイス
PreparedMoveValues? _liquidVoiceTransformation(DamageEffectsContext context) =>
    context.attackerAbility == AbilityId.liquidVoice &&
        context.originalMove.flags.contains(MoveFlag.sound)
    ? PreparedMoveValues(
        type: TeraType.water,
        power: context.originalMove.power.value,
        category: context.originalMove.category,
      )
    : null;

EffectiveMove prepareEffectiveMove(DamageEffectsContext context) {
  // 技固有の変化を先に採用する。同じ技へスキン系や音声の変化を重ねない。
  final orderedTransformations = [
    _teraBlastTransformation,
    _teraStarstormTransformation,
    _weatherBallTransformation,
    _terrainPulseTransformation,
    _ragingBullTransformation,
    _normalizeTransformation,
    _skinTransformation,
    _liquidVoiceTransformation,
  ];
  var values = PreparedMoveValues(
    type: TeraType.of(context.originalMove.type),
    power: context.originalMove.power.value,
    category: context.originalMove.category,
  );
  for (final transform in orderedTransformations) {
    final transformation = transform(context);
    if (transformation != null) {
      values = transformation;
      break;
    }
  }
  return EffectiveMove(
    id: context.originalMove.id,
    type: values.type,
    power: values.power,
    category: context.originalMove.id == MoveId.photonGeyser
        ? _adaptiveCategory(context)
        : values.category,
    spread: context.originalMove.spread,
    flags: context.originalMove.flags,
    priority: context.originalMove.priority.value,
  );
}
