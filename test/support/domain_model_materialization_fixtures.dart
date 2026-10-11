import 'package:pokemon_damage_calculator_core/src/models/dto.dart';
import 'package:pokemon_damage_calculator_core/src/models/validation.dart';
import 'package:pokemon_damage_calculator_core/src/models/value_objects.dart';

T value<T>(Validation<T> validation) => (validation as Valid<T>).value;

const stats = StatsDto(hp: 200, atk: 1, def: 3, spa: 4, spd: 5, spe: 6);

PokemonStateDto makePokemon({bool detailed = true}) => PokemonStateDto(
  profile: PokemonProfileDto(
    id: value(PokemonId.create('materialization')),
    types: [PokemonType.fire, PokemonType.flying],
    weight: 999.9,
    gender: Gender.female,
  ),
  stats: stats,
  stages: const StatStagesDto(atk: -6, def: 6, spa: -1, spd: 1, spe: 2),
  ability: detailed ? AbilityId.magicGuard : null,
  item: detailed ? ItemId.leftovers : null,
  currentHp: detailed ? 1 : null,
  status: detailed ? Status.toxic : null,
  toxicCounter: detailed ? 15 : null,
  cudChewTurn: detailed ? -1 : null,
  teraType: detailed ? TeraType.stellar : null,
  sideConditions: SideConditions(reflect: detailed, lightScreen: detailed),
  itemConsumed: detailed,
  boostedStat: detailed ? Stat.spa : null,
  faintedAllies: 100,
  timesHit: 100,
  flags: {PokemonFlag.grounded: true, PokemonFlag.charge: false},
);

MoveDto move() => MoveDto(
  id: value(MoveId.create('materialization')),
  type: PokemonType.fire,
  power: 1000,
  category: Category.special,
  spread: true,
  flags: {MoveFlag.sound, MoveFlag.bullet},
  priority: -7,
);

BattleFieldDto field() => BattleFieldDto(
  format: BattleFormat.double,
  weather: Weather.rain,
  gravity: true,
  terrain: Terrain.electric,
  effects: {FieldEffect.friendGuard, FieldEffect.battery},
);
