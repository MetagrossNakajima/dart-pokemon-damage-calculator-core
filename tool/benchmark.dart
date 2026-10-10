import 'dart:io';

import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

const _stats = StatsDto(
  hp: 200,
  atk: 100,
  def: 100,
  spa: 100,
  spd: 100,
  spe: 100,
);

PokemonStateDto _pokemon({String? ability, String? item}) => PokemonStateDto(
  profile: PokemonProfileDto(
    id: (PokemonId.create('benchmark') as Valid<PokemonId>).value,
    types: [PokemonType.normal],
    weight: 50,
  ),
  stats: _stats,
  ability: ability == null
      ? null
      : (AbilityId.create(ability) as Valid<AbilityId>).value,
  item: item == null ? null : (ItemId.create(item) as Valid<ItemId>).value,
);

MoveDto _move({String id = 'Tackle', int power = 40}) => MoveDto(
  id: (MoveId.create(id) as Valid<MoveId>).value,
  type: PokemonType.normal,
  power: power,
  category: Category.physical,
);

final _field = BattleFieldDto(format: BattleFormat.single);

int _damageChecksum(Calculation<DamageResult> calculation) =>
    switch (calculation) {
      Success(:final value) =>
        value.min + value.max + value.distribution.weights.length,
      Failure(:final kind, :final path) => throw StateError(
        'benchmark failed: $kind at $path',
      ),
    };

int _combinedChecksum(Calculation<CombinedDamageResult> calculation) =>
    switch (calculation) {
      Success(:final value) =>
        value.attackDamage.min.toInt() +
            value.attackDamage.max.toInt() +
            value.finalHp.weights.length,
      Failure(:final kind, :final path) => throw StateError(
        'benchmark failed: $kind at $path',
      ),
    };

int _runScenario(String scenario) => switch (scenario) {
  'single' => _damageChecksum(
    calculateDamage(
      _valid(
        DamageRequest.fromDto(
          DamageRequestDto(
            attacker: _pokemon(),
            defender: _pokemon(),
            move: _move(),
            field: _field,
          ),
        ),
      ),
    ),
  ),
  'ten-hit' => _combinedScenario(turns: 1, hits: 10),
  'combined' => _combinedScenario(turns: 4, hits: 2),
  'recovery' => _combinedScenario(turns: 4, hits: 2, item: 'Leftovers'),
  'near-limit' => _repeatedScenario(
    DamageDistribution({
      for (var damage = 0; damage < 300; damage++) damage: BigInt.one,
    }),
  ),
  'ko-search' => _repeatedScenario(
    DamageDistribution({0: BigInt.one, 1: BigInt.one}),
  ),
  _ => throw ArgumentError.value(scenario, 'scenario'),
};

int _repeatedScenario(DamageDistribution distribution) => _combinedChecksum(
  calculateCombinedDamage(
    _valid(
      CombinedDamageRequest.fromDto(
        CombinedDamageRequestDto.repeatSingleHit(
          firstHit: distribution,
          defender: _pokemon(),
          field: _field,
          setup: BattleSetupDto.none,
        ),
      ),
    ),
  ),
);

int _combinedScenario({required int turns, required int hits, String? item}) {
  final distribution = DamageDistribution({
    for (var damage = 5; damage <= 20; damage++) damage: BigInt.one,
  });
  return _combinedChecksum(
    calculateCombinedDamage(
      _valid(
        CombinedDamageRequest.fromDto(
          CombinedDamageRequestDto(
            attacks: [
              for (var turn = 1; turn <= turns; turn++)
                AttackDto(
                  turn: turn,
                  hits: List.filled(hits, distribution),
                  hitCounts: {0: BigInt.one, hits: BigInt.from(9)},
                ),
            ],
            defender: _pokemon(item: item),
            field: _field,
            setup: BattleSetupDto.none,
          ),
        ),
      ),
    ),
  );
}

void main(List<String> arguments) {
  const defaults = {
    'single': 2000,
    'ten-hit': 100,
    'combined': 200,
    'recovery': 200,
    'near-limit': 3,
    'ko-search': 1000,
  };
  if (arguments.isEmpty || !defaults.containsKey(arguments.first)) {
    stderr.writeln(
      'usage: dart run tool/benchmark.dart '
      '<single|ten-hit|combined|recovery|near-limit|ko-search> [iterations]',
    );
    exitCode = 64;
    return;
  }
  final scenario = arguments.first;
  final iterations = arguments.length == 1
      ? defaults[scenario]!
      : int.tryParse(arguments[1]);
  if (iterations == null || iterations <= 0 || arguments.length > 2) {
    stderr.writeln('iterations must be a positive integer');
    exitCode = 64;
    return;
  }

  for (var index = 0; index < 5; index++) {
    _runScenario(scenario);
  }
  var checksum = 0;
  final stopwatch = Stopwatch()..start();
  for (var index = 0; index < iterations; index++) {
    checksum += _runScenario(scenario);
  }
  stopwatch.stop();
  stdout.writeln(
    '$scenario iterations=$iterations '
    'elapsed_us=${stopwatch.elapsedMicroseconds} checksum=$checksum',
  );
}

T _valid<T>(Validation<T> validation) => switch (validation) {
  Valid(:final value) => value,
  Invalid(:final errors) => throw StateError(
    'Invalid benchmark: ${errors.map((e) => e.path).join(', ')}',
  ),
};
