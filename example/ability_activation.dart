import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

import 'main.dart' show valid;

void main() {
  final profile = PokemonProfileDto(
    id: PokemonId.mew,
    types: [PokemonType.normal],
    weight: 4,
  );
  const stats = StatsDto(
    hp: 200,
    atk: 100,
    def: 100,
    spa: 100,
    spd: 100,
    spe: 100,
  );
  for (final enabled in [false, true]) {
    final request = valid(
      DamageRequest.fromDto(
        DamageRequestDto(
          attacker: PokemonStateDto(
            profile: profile,
            stats: stats,
            // ON means activated even at full HP; OFF omits the ability.
            ability: enabled ? AbilityId.blaze : null,
          ),
          defender: PokemonStateDto(profile: profile, stats: stats),
          move: MoveDto(
            id: MoveId.flamethrower,
            type: PokemonType.fire,
            power: 90,
            category: Category.special,
          ),
          field: BattleFieldDto(format: BattleFormat.single),
        ),
      ),
    );
    switch (calculateDamage(request)) {
      case Success(:final value):
        print(
          'Blaze ${enabled ? 'ON' : 'OFF'} at full HP: ${value.min}–${value.max}',
        );
      case Failure(:final kind, :final path):
        print('$kind: $path');
    }
  }
}
