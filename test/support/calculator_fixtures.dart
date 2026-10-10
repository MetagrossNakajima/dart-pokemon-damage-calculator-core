import 'input_adapter.dart';
import 'package:test/test.dart';

final single = BattleFieldDto(format: BattleFormat.single);

Map<Stat, int> values(int n) => {for (final s in Stat.values) s: n};

PokemonStateDto pokemon({
  String id = 'test',
  List<String> types = const ['Normal'],
  int stat = 100,
  int hp = 200,
  Map<Stat, int> ranks = const {},
  String? ability,
  String? item,
  Status? status,
  bool fullHp = true,
  bool reflect = false,
  bool lightScreen = false,
  double weight = 50,
}) => PokemonStateDto(
  profile: PokemonProfileDto(
    id: pokemonId(id),
    types: types.map(pokemonType).toList(),
    weight: weight,
  ),
  stats: StatsDto.fromMap({...values(stat), Stat.hp: hp}),
  stages: StatStagesDto.fromMap(ranks),
  ability: abilityId(ability),
  item: itemId(item),
  status: status,
  toxicCounter: status == Status.toxic ? 1 : null,
  currentHp: fullHp ? null : hp - 1,
  sideConditions: SideConditions(reflect: reflect, lightScreen: lightScreen),
);

MoveDto move({
  String id = 'Tackle',
  String type = 'Normal',
  int power = 40,
  Category category = Category.physical,
  bool spread = false,
}) => MoveDto(
  id: moveId(id),
  type: pokemonType(type),
  power: power,
  category: category,
  spread: spread,
);

T ok<T>(Calculation<T> c) {
  expect(
    c,
    isA<Success<T>>(),
    reason: c is Failure<T> ? '${c.kind} at ${c.path}' : null,
  );
  return (c as Success<T>).value;
}

void failure<T>(Calculation<T> c, FailureKind kind) {
  expect(c, isA<Failure<T>>());
  expect((c as Failure<T>).kind, kind);
  expect(c.path, isNotEmpty);
}

DamageResult damage({
  PokemonStateDto? a,
  PokemonStateDto? d,
  MoveDto? m,
  BattleFieldDto? f,
  bool crit = false,
}) => ok(
  calculateDamage(
    DamageRequestDto(
      attacker: a ?? pokemon(),
      defender: d ?? pokemon(),
      move: m ?? move(),
      field: f ?? single,
      critical: crit,
    ),
  ),
);

DamageDistribution dist(Map<int, int> w) =>
    DamageDistribution(w.map((k, v) => MapEntry(k, BigInt.from(v))));
