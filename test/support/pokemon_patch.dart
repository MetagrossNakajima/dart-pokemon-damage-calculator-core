import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

/// 未指定と明示的な `null` を区別する置換値。
///
/// `Replacement<ItemId?>(null)` は道具をクリアする。
/// [PokemonPatch] の対応するフィールドを省くと現在の道具を維持する。
final class Replacement<T> {
  const Replacement(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      other is Replacement<T> &&
      runtimeType == other.runtimeType &&
      value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

/// Test fixture builder for replacing selected Pokemon fields.
final class PokemonPatch {
  PokemonPatch({
    this.id,
    List<PokemonType>? types,
    Map<Stat, int>? stats,
    Map<Stat, int>? ranks,
    this.ability,
    this.item,
    this.status,
    this.weight,
    this.reflect,
    this.lightScreen,
    this.currentHp,
    this.toxicCounter,
    this.itemConsumed,
    this.cudChewTurn,
    this.teraType,
    this.gender,
    this.boostedStat,
    this.faintedAllies,
    this.timesHit,
    Map<PokemonFlag, bool> flags = const {},
  }) : types = types == null ? null : List.unmodifiable(types),
       stats = stats == null ? null : Map.unmodifiable(stats),
       ranks = ranks == null ? null : Map.unmodifiable(ranks),
       flags = Map.unmodifiable(flags);
  final PokemonId? id;
  final List<PokemonType>? types;
  final Map<Stat, int>? stats;
  final Map<Stat, int>? ranks;
  final Replacement<AbilityId?>? ability;
  final Replacement<ItemId?>? item;
  final Replacement<Status?>? status;
  final bool? reflect;
  final bool? lightScreen;
  final double? weight;
  final Replacement<int?>? currentHp;
  final Replacement<int?>? toxicCounter;
  final bool? itemConsumed;
  final Replacement<int?>? cudChewTurn;
  final Replacement<TeraType?>? teraType;
  final Gender? gender;
  final Replacement<Stat?>? boostedStat;
  final int? faintedAllies;
  final int? timesHit;
  final Map<PokemonFlag, bool> flags;

  /// [pokemon] に未検証の置換値を適用し、検証前のDTOを返す。
  PokemonStateDto apply(PokemonStateDto pokemon) => PokemonStateDto(
    profile: PokemonProfileDto(
      id: id ?? pokemon.id,
      types: types ?? pokemon.types,
      weight: weight ?? pokemon.weight,
      gender: gender ?? pokemon.gender,
    ),
    stats: StatsDto.fromMap({...pokemon.stats, ...?stats}),
    stages: StatStagesDto.fromMap({...pokemon.stages, ...?ranks}),
    ability: ability == null ? pokemon.ability : ability!.value,
    item: item == null ? pokemon.item : item!.value,
    status: status == null ? pokemon.status : status!.value,
    sideConditions: SideConditions(
      reflect: reflect ?? pokemon.reflect,
      lightScreen: lightScreen ?? pokemon.lightScreen,
    ),
    currentHp: currentHp == null ? pokemon.currentHp : currentHp!.value,
    toxicCounter: toxicCounter == null
        ? pokemon.toxicCounter
        : toxicCounter!.value,
    itemConsumed: itemConsumed ?? pokemon.itemConsumed,
    cudChewTurn: cudChewTurn == null ? pokemon.cudChewTurn : cudChewTurn!.value,
    teraType: teraType == null ? pokemon.teraType : teraType!.value,
    boostedStat: boostedStat == null ? pokemon.boostedStat : boostedStat!.value,
    faintedAllies: faintedAllies ?? pokemon.faintedAllies,
    timesHit: timesHit ?? pokemon.timesHit,
    flags: {...pokemon.flags, ...flags},
  );
}
