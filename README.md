# pokemon_damage_calculator_core

A pure Dart Pokémon damage calculator with no Flutter dependency. Supply actual stat values; calculations use a fixed level of 50.

Maximum and current HP must be integers from 1 through 999. Current HP must not exceed maximum HP.
Attack, Defense, Special Attack, Special Defense, and Speed inputs must also be integers from 1 through 999. Rank and battle modifiers may produce values above 999.

## Usage

Add the package to your `pubspec.yaml` and run `dart pub get`.

```yaml
dependencies:
    pokemon_damage_calculator_core:
        git:
            url: https://github.com/MetagrossNakajima/dart-pokemon-damage-calculator-core.git
```

`DamageRequest.fromDto` validates input, and `calculateDamage` calculates the damage distribution for one hit.
`calculateCombinedDamage` combines supplied fixed distributions and hit count weights, returning remaining HP, knockout probability, and hits to KO assuming every attack lands.
Run the [combined damage example](example/main.dart) with `dart run example/main.dart`.

## Request example

Validate a string ID with `PokemonId.create`, calculate one hit, then use the same distribution for attacks over four consecutive turns.
This example uses Iron Tail (100 base power, Steel, physical) with 75% accuracy each turn. Use the core’s ID spelling (for example, `Pikachu`) and specify weight in kilograms.

```dart
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
```

## Response example

```text
damage: 19–23
percent: 19.0–23.0%
weights: {19: 2, 20: 5, 21: 4, 22: 4, 23: 1}
attack damage: 0–92
final HP: 8–100
KO category: KoCategory.fiveOrMore
KO weight: 0/16777216
```

## Multi-hit request example

This example uses Double Hit for one turn (35 base power per hit, Normal, physical, 90% accuracy).
Set `hitCountWeights: {2: 1}` because the move always hits twice when it lands.
Both hits use the same power and modifiers, so calculate the distribution once and supply it for both hits.
The combined calculation treats each hit’s random roll independently.

Reuse `pokemon` and `valid` from the previous example and replace the calculation inside `main` with the following.
Run the [multi-hit example](example/multi_hit.dart) with `dart run example/multi_hit.dart`.

```dart
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
```

## Multi-hit response example

```text
per hit: 14–17
attack damage: 0–34
final HP: 66–100
KO category: KoCategory.undetermined
KO weight: 0/2560
```

The attack misses 10% of the time and hits twice 90% of the time. When it lands, total damage is 28–34.
Only one turn is supplied, so the number of hits to KO remains undetermined within that range.

## Install

[mise](https://mise.jdx.dev/) manages the Dart SDK. `mise.toml` pins Dart 3.13.4, matching CI.
After installing mise, run the following from the repository root:

```sh
mise trust
mise install
mise run check
```

`check` installs dependencies, checks formatting and generated IDs, runs static analysis,
collects and verifies 100% line and VM branch coverage, then runs the single-hit and multi-hit examples in sequence.
Coverage collection also runs the full test suite.

Individual commands are listed below.

| Command                | Description                                       |
| ----------------------- | ------------------------------------------ |
| `mise run setup`        | Install dependencies using the lockfile |
| `mise run format`       | Format Dart code                           |
| `mise run format:check` | Check formatting                               |
| `mise run analyze`      | Run static analysis                                   |
| `mise run test`         | Run all tests                             |
| `mise run coverage`     | Collect line and VM branch coverage and verify 100%   |
| `mise run ids:generate` | Generate ID definitions                               |
| `mise run ids:check`    | Check generated ID definitions                         |
| `mise run example`      | Run the single-hit and multi-hit examples               |
| `mise run benchmark`    | Run the single-hit benchmark                         |
| `mise run check`        | Run all development checks             |

List available tasks with `mise tasks`. Each task uses the Dart version specified in `mise.toml`.

## Additional notes

Priority-move blocking is outside the scope of this package, including effects from abilities such as Queenly Majesty, Armor Tail, and Dazzling, as well as Psychic Terrain. The client must determine whether a priority move can hit before requesting a damage calculation. Psychic Terrain's damage modifiers are supported.
