part of '../dto.dart';

/// 対戦中に変化する値を保持する、不変の未検証ポケモン状態DTO。
final class PokemonStateDto {
  PokemonStateDto({
    required this.profile,
    required this.stats,
    StatStagesDto? stages,
    this.ability,
    this.item,
    this.status,
    this.sideConditions = const SideConditions(),
    this.currentHp,
    this.toxicCounter,
    this.itemConsumed = false,
    this.cudChewTurn,
    this.teraType,
    this.boostedStat,
    this.faintedAllies = 0,
    this.timesHit = 0,
    Map<PokemonFlag, bool> flags = const {},
  }) : stages = stages ?? const StatStagesDto(),
       flags = Map.unmodifiable(flags);

  final PokemonProfileDto profile;
  final StatsDto stats;
  final StatStagesDto stages;
  final AbilityId? ability;
  final ItemId? item;
  final Status? status;
  final SideConditions sideConditions;
  final int? currentHp;
  final int? toxicCounter;
  final bool itemConsumed;
  final int? cudChewTurn;
  final TeraType? teraType;
  final Stat? boostedStat;
  final int faintedAllies;
  final int timesHit;
  final Map<PokemonFlag, bool> flags;

  PokemonId get id => profile.id;
  List<PokemonType> get types => profile.types;
  double get weight => profile.weight;
  Gender get gender => profile.gender;
  bool get reflect => sideConditions.reflect;
  bool get lightScreen => sideConditions.lightScreen;
}
