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
  final damageRequest = valid(
    DamageRequest.fromDto(
      DamageRequestDto(
        attacker: pokemon,
        defender: pokemon,
        move: MoveDto(
          id: valid(MoveId.create('IronTail')),
          type: PokemonType.steel,
          power: 100,
          category: Category.physical,
        ),
        field: BattleFieldDto(format: BattleFormat.single),
      ),
    ),
  );
  switch (calculateDamage(damageRequest)) {
    case Failure(:final kind, :final path):
      print('$kind: $path');
    case Success(:final value):
      print('damage: ${value.min}–${value.max}');
      print('percent: ${value.minPercent}–${value.maxPercent}%');
      print('weights: ${value.distribution.weights}');
      final input = CombinedDamageRequestDto.repeatSingleHit(
        firstHit: value.distribution,
        defender: pokemon,
        field: BattleFieldDto(format: BattleFormat.single),
        setup: BattleSetupDto.none,
        accuracyPercent: 75,
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
}

T valid<T>(Validation<T> validation) => switch (validation) {
  Valid(:final value) => value,
  Invalid(:final errors) => throw ArgumentError(
    errors.map((error) => '${error.path}: ${error.code}').join(', '),
  ),
};
