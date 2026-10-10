part of '../dto.dart';

/// HP0のひんし状態も表せる、計算結果の不変スナップショット。
final class BattleState {
  BattleState.fromDto(PokemonStateDto state) : _state = state;
  final PokemonStateDto _state;
  PokemonProfileDto get profile => _state.profile;
  StatsDto get stats => _state.stats;
  StatStagesDto get stages => _state.stages;
  AbilityId? get ability => _state.ability;
  ItemId? get item => _state.item;
  Status? get status => _state.status;
  SideConditions get sideConditions => _state.sideConditions;
  int? get currentHp => _state.currentHp;
  int? get toxicCounter => _state.toxicCounter;
  bool get itemConsumed => _state.itemConsumed;
  int? get cudChewTurn => _state.cudChewTurn;
  TeraType? get teraType => _state.teraType;
  Stat? get boostedStat => _state.boostedStat;
  int get faintedAllies => _state.faintedAllies;
  int get timesHit => _state.timesHit;
  Map<PokemonFlag, bool> get flags => _state.flags;
  PokemonId get id => _state.id;
  List<PokemonType> get types => _state.types;
  double get weight => _state.weight;
  Gender get gender => _state.gender;
  bool get reflect => _state.reflect;
  bool get lightScreen => _state.lightScreen;
}
