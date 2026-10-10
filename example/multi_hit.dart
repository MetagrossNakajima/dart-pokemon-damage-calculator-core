import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

void main() {
  const pokemonId = 'Pikachu';
  final pokemon = PokemonStateDto(
    profile: PokemonProfileDto(
      id: valid(PokemonId.create(pokemonId)),
      weight: 6,
      types: [PokemonType.electric],
    ),
    stats: const StatsDto(
      hp: 100,
      atk: 100,
      def: 100,
      spa: 100,
      spd: 100,
      spe: 100,
    ),
  );
  final field = BattleFieldDto(format: BattleFormat.single);
  final move = MoveDto(
    id: valid(MoveId.create('DoubleHit')),
    type: PokemonType.normal,
    power: 35,
    category: Category.physical,
  );
  final request = valid(
    DamageRequest.fromDto(
      DamageRequestDto(
        attacker: pokemon,
        defender: pokemon,
        move: move,
        field: field,
      ),
    ),
  );
  final DamageDistribution distribution;
  switch (calculateDamage(request)) {
    case Success(:final value):
      distribution = value.distribution;
      print('per hit: ${value.min}–${value.max}');
    case Failure(:final kind, :final path):
      print('$kind: $path');
      return;
  }
  final input = CombinedDamageRequestDto(
    attacks: [
      AttackDto.fromAccuracy(
        turn: 1,
        hits: [distribution, distribution],
        accuracyPercent: 90,
        hitCountWeights: {2: 1},
      ),
    ],
    defender: pokemon,
    field: field,
    setup: BattleSetupDto.none,
  );
  switch (calculateCombinedDamage(
    valid(CombinedDamageRequest.fromDto(input)),
  )) {
    case Success(:final value):
      print(
        'attack damage: ${value.attackDamage.min}–${value.attackDamage.max}',
      );
      print('final HP: ${value.finalHp.min}–${value.finalHp.max}');
      print('KO category: ${value.ko.category}');
      print(
        'KO weight: ${value.knockout.weight}/${value.knockout.totalWeight}',
      );
    case Failure(:final kind, :final path):
      print('$kind: $path');
  }
}

T valid<T>(Validation<T> validation) => switch (validation) {
  Valid(:final value) => value,
  Invalid(:final errors) => throw ArgumentError(
    errors.map((error) => '${error.path}: ${error.code}').join(', '),
  ),
};
