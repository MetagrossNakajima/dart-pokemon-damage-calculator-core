part of 'models.dart';

final class PokemonState extends DomainValue {
  const PokemonState._({
    required this.profile,
    required this.stats,
    required this.stages,
    required this.ability,
    required this.item,
    required this.currentHp,
    required this.toxicCounter,
    required this.cudChewTurn,
    required this.teraType,
    required this.status,
    required this.sideConditions,
    required this.itemConsumed,
    required this.boostedStat,
    required this.flags,
    required this.faintedAllies,
    required this.timesHit,
  });

  final PokemonProfile profile;
  final Stats stats;
  final StatStages stages;

  /// 発動済みとして計算する特性。未指定の場合は特性の効果なし。
  ///
  /// HP・状態異常・天候などの発動条件は判定せず、技への適用条件と
  /// かたやぶりなどによる無効化は適用する。入力された状態は変更しない。
  final AbilityId? ability;
  final ItemId? item;
  final CurrentHp? currentHp;
  final ToxicCounter? toxicCounter;
  final CudChewTurn? cudChewTurn;
  final TeraType? teraType;
  final Status? status;
  final SideConditions sideConditions;
  final bool itemConsumed;
  final Stat? boostedStat;
  final Map<PokemonFlag, bool> flags;
  final FaintedAllies faintedAllies;
  final TimesHit timesHit;

  static Validation<PokemonState> fromDto(PokemonStateDto input) {
    final checks = _Checks();
    return checks.finish(_checkPokemon(checks, input, 'pokemonState'));
  }

  PokemonStateDto get toDto => PokemonStateDto(
    profile: profile.toDto,
    stats: stats.toDto,
    stages: stages.toDto,
    ability: ability,
    item: item,
    currentHp: currentHp?.value,
    toxicCounter: toxicCounter?.value,
    cudChewTurn: cudChewTurn?.value,
    teraType: teraType,
    status: status,
    sideConditions: sideConditions,
    itemConsumed: itemConsumed,
    boostedStat: boostedStat,
    flags: flags,
    faintedAllies: faintedAllies.value,
    timesHit: timesHit.value,
  );

  PokemonId get id => profile.id;
  List<PokemonType> get types => profile.types;
  PokemonWeight get weight => profile.weight;
  Gender get gender => profile.gender;
  bool get reflect => sideConditions.reflect;
  bool get lightScreen => sideConditions.lightScreen;

  @override
  List<Object?> get _properties => [
    profile,
    stats,
    stages,
    ability,
    item,
    currentHp,
    toxicCounter,
    cudChewTurn,
    teraType,
    status,
    sideConditions,
    itemConsumed,
    boostedStat,
    flags,
    faintedAllies,
    timesHit,
  ];
}
