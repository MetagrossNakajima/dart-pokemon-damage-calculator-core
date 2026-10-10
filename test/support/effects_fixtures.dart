import 'input_adapter.dart';
import 'pokemon_patch.dart';
import 'calculator_fixtures.dart' as calculator;

PokemonStateDto p({
  String id = 'test',
  String? ability,
  String? item,
  List<String> types = const ['Normal'],
  Status? status,
  int? hp,
  Map<PokemonFlag, bool> flags = const {},
  Gender gender = Gender.genderless,
  int fainted = 0,
  int timesHit = 0,
  Stat? boosted,
  Map<Stat, int> ranks = const {},
  Map<Stat, int> stats = const {},
  String? tera,
}) => PokemonStateDto(
  profile: PokemonProfileDto(
    id: pokemonId(id),
    types: types.map(pokemonType).toList(),
    weight: 50,
    gender: gender,
  ),
  ability: abilityId(ability),
  item: itemId(item),
  status: status,
  toxicCounter: status == Status.toxic ? 1 : null,
  stats: StatsDto.fromMap({...calculator.values(100), Stat.hp: 200, ...stats}),
  stages: StatStagesDto.fromMap(ranks),
  currentHp: hp,
  flags: flags,
  faintedAllies: fainted,
  timesHit: timesHit,
  boostedStat: boosted,
  teraType: teraType(tera),
);

MoveDto m({
  String id = 'Tackle',
  String type = 'Normal',
  int power = 40,
  Category category = Category.physical,
  Set<MoveFlag> flags = const {},
}) => MoveDto(
  id: moveId(id),
  type: pokemonType(type),
  power: power,
  category: category,
  flags: flags,
);

BattleFieldDto f({
  Terrain? terrain,
  Weather? weather,
  Set<FieldEffect> effects = const {},
  bool gravity = false,
}) => BattleFieldDto(
  format: BattleFormat.single,
  terrain: terrain,
  weather: weather,
  effects: effects,
  gravity: gravity,
);

HitResult hit({
  PokemonStateDto? a,
  PokemonStateDto? d,
  MoveDto? move,
  BattleFieldDto? field,
  bool crit = false,
}) => calculator
    .damage(
      a: a ?? p(),
      d: d ?? p(),
      m: move ?? m(),
      f: field ?? f(),
      crit: crit,
    )
    .hits
    .first;

PokemonStateDto change(PokemonStateDto p, PokemonPatch patch) => patch.apply(p);
