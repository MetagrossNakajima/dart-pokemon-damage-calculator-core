import 'input_adapter.dart';
import 'package:test/test.dart';

const stats100 = StatsDto(
  hp: 100,
  atk: 100,
  def: 100,
  spa: 100,
  spd: 100,
  spe: 100,
);

PokemonStateDto pokemon({
  String id = 'test',
  List<String> types = const ['Normal'],
  StatsDto stats = stats100,
  int? currentHp,
  String? ability,
  String? item,
  Status? status,
  int? toxicCounter,
  bool itemConsumed = false,
  int? cudChewTurn,
  Map<PokemonFlag, bool> flags = const {},
}) => PokemonStateDto(
  profile: PokemonProfileDto(
    id: pokemonId(id),
    types: types.map(pokemonType).toList(),
    weight: 50,
  ),
  stats: stats,
  currentHp: currentHp,
  ability: abilityId(ability),
  item: itemId(item),
  status: status,
  toxicCounter: toxicCounter,
  itemConsumed: itemConsumed,
  cudChewTurn: cudChewTurn,
  flags: flags,
);

MoveDto fixedMove(String id, {String type = 'Normal', int power = 0}) =>
    MoveDto(
      id: moveId(id),
      type: pokemonType(type),
      power: power,
      category: Category.physical,
    );

final single = BattleFieldDto(format: BattleFormat.single);

T success<T>(Calculation<T> calculation) {
  expect(
    calculation,
    isA<Success<T>>(),
    reason: calculation is Failure<T>
        ? '${calculation.kind} at ${calculation.path}'
        : null,
  );
  return (calculation as Success<T>).value;
}

DamageResult damage(
  MoveDto move, {
  PokemonStateDto? attacker,
  PokemonStateDto? defender,
  BattleFieldDto? field,
}) => success(
  calculateDamage(
    DamageRequestDto(
      attacker: attacker ?? pokemon(currentHp: 30),
      defender:
          defender ??
          pokemon(
            currentHp: 101,
            stats: const StatsDto(
              hp: 101,
              atk: 100,
              def: 100,
              spa: 100,
              spd: 100,
              spe: 100,
            ),
          ),
      move: move,
      field: field ?? single,
    ),
  ),
);
