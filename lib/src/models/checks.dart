part of 'models.dart';

final class _Checks {
  final errors = <ValidationError>[];

  void require(bool condition, String path, ValidationCode code) {
    if (!condition) errors.add(ValidationError(path, code));
  }

  T? take<T>(Validation<T> result, String path) {
    switch (result) {
      case Valid(:final value):
        return value;
      case Invalid(:final errors):
        for (final error in errors) {
          this.errors.add(ValidationError(path, error.code));
        }
        return null;
    }
  }

  Validation<T> finish<T>(T Function() build) =>
      errors.isEmpty ? Valid(build()) : Invalid(errors);
}

Stats Function() _checkStats(_Checks c, StatsDto input, String path) {
  final hp = c.take(StatValue.create(input.hp), '$path.hp');
  final atk = c.take(StatValue.create(input.atk), '$path.atk');
  final def = c.take(StatValue.create(input.def), '$path.def');
  final spa = c.take(StatValue.create(input.spa), '$path.spa');
  final spd = c.take(StatValue.create(input.spd), '$path.spd');
  final spe = c.take(StatValue.create(input.spe), '$path.spe');
  return () => Stats._(hp!, atk!, def!, spa!, spd!, spe!);
}

StatStages Function() _checkStages(
  _Checks c,
  StatStagesDto input,
  String path,
) {
  final atk = c.take(StatStage.create(input.atk), '$path.atk');
  final def = c.take(StatStage.create(input.def), '$path.def');
  final spa = c.take(StatStage.create(input.spa), '$path.spa');
  final spd = c.take(StatStage.create(input.spd), '$path.spd');
  final spe = c.take(StatStage.create(input.spe), '$path.spe');
  return () => StatStages._(atk!, def!, spa!, spd!, spe!);
}

PokemonProfile Function() _checkProfile(
  _Checks c,
  PokemonProfileDto p,
  String path,
) {
  c.require(p.types.isNotEmpty, '$path.types', ValidationCode.required);
  c.require(p.types.length <= 2, '$path.types', ValidationCode.outOfRange);
  c.require(
    p.types.toSet().length == p.types.length,
    '$path.types',
    ValidationCode.duplicate,
  );
  final weight = c.take(PokemonWeight.create(p.weight), '$path.weight');
  return () =>
      PokemonProfile._(p.id, List.unmodifiable(p.types), weight!, p.gender);
}

PokemonState Function() _checkPokemon(
  _Checks c,
  PokemonStateDto p,
  String path,
) {
  final profile = _checkProfile(c, p.profile, '$path.profile');
  final stats = _checkStats(c, p.stats, '$path.stats');
  final stages = _checkStages(c, p.stages, '$path.stages');
  CurrentHp? currentHp;
  if (p.currentHp != null) {
    currentHp = c.take(CurrentHp.create(p.currentHp!), '$path.currentHp');
    if (currentHp != null && p.stats.hp > 0) {
      c.require(
        currentHp.value <= p.stats.hp,
        '$path.currentHp',
        ValidationCode.inconsistent,
      );
    }
  }
  ToxicCounter? toxicCounter;
  if (p.toxicCounter != null) {
    toxicCounter = c.take(
      ToxicCounter.create(p.toxicCounter!),
      '$path.toxicCounter',
    );
  }
  c.require(
    p.status == Status.toxic ? p.toxicCounter != null : p.toxicCounter == null,
    '$path.toxicCounter',
    ValidationCode.inconsistent,
  );
  c.require(
    p.boostedStat != Stat.hp,
    '$path.boostedStat',
    ValidationCode.inconsistent,
  );
  final faintedAllies = c.take(
    FaintedAllies.create(p.faintedAllies),
    '$path.faintedAllies',
  );
  final timesHit = c.take(TimesHit.create(p.timesHit), '$path.timesHit');
  final cudChewTurn = p.cudChewTurn == null
      ? null
      : c.take(CudChewTurn.create(p.cudChewTurn!), '$path.cudChewTurn');
  return () => PokemonState._(
    profile: profile(),
    stats: stats(),
    stages: stages(),
    ability: p.ability,
    item: p.item,
    currentHp: currentHp,
    toxicCounter: toxicCounter,
    cudChewTurn: cudChewTurn,
    teraType: p.teraType,
    status: p.status,
    sideConditions: p.sideConditions,
    itemConsumed: p.itemConsumed,
    boostedStat: p.boostedStat,
    flags: Map.unmodifiable(p.flags),
    faintedAllies: faintedAllies!,
    timesHit: timesHit!,
  );
}

Move Function() _checkMove(_Checks c, MoveDto m, String path) {
  final power = c.take(MovePower.create(m.power), '$path.power');
  if (power != null && !isFixedDamageMove(m.id)) {
    c.require(power.value > 0, '$path.power', ValidationCode.outOfRange);
  }
  final priority = c.take(MovePriority.create(m.priority), '$path.priority');
  return () => Move._(
    id: m.id,
    type: m.type,
    power: power!,
    category: m.category,
    spread: m.spread,
    flags: Set.unmodifiable(m.flags),
    priority: priority!,
  );
}

CalculationLimits Function() _checkLimits(
  _Checks c,
  CalculationLimitsDto l,
  String path,
) {
  final maxOperations = c.take(
    OperationLimit.create(l.maxOperations),
    '$path.maxOperations',
  );
  final maxStates = c.take(StateLimit.create(l.maxStates), '$path.maxStates');
  return () => CalculationLimits._(maxOperations!, maxStates!);
}

EntryHazards Function() _checkHazards(
  _Checks c,
  EntryHazardsDto h,
  String path,
) {
  final spikesLayers = c.take(
    SpikesLayers.create(h.spikesLayers),
    '$path.spikesLayers',
  );
  return () => EntryHazards._(h.stealthRock, spikesLayers!);
}

BattleSetup Function() _checkSetup(_Checks c, BattleSetupDto s, String path) {
  for (var i = 0; i < s.initialDamages.length; i++) {
    c.take(
      DamageAmount.create(s.initialDamages[i]),
      '$path.initialDamages[$i]',
    );
  }
  final hazards = _checkHazards(c, s.entryHazards, '$path.entryHazards');
  return () => BattleSetup._(hazards(), List.unmodifiable(s.initialDamages));
}

DamageWeights Function() _checkDistribution(
  _Checks c,
  DamageDistribution d,
  String path,
) {
  c.require(d.weights.isNotEmpty, path, ValidationCode.required);
  final keys = d.weights.keys.toList()..sort();
  final entries = <(DamageAmount?, DistributionWeight?)>[];
  for (final key in keys) {
    final damage = c.take(DamageAmount.create(key), '$path[$key].damage');
    final weight = c.take(
      DistributionWeight.create(d.weights[key]!),
      '$path[$key].weight',
    );
    entries.add((damage, weight));
  }
  return () => DamageWeights._(
    Map.unmodifiable({for (final entry in entries) entry.$1!: entry.$2!}),
    d.weights.values.fold(BigInt.zero, (sum, weight) => sum + weight),
    keys.first,
    keys.last,
  );
}

DamageRequest Function() _checkDamageRequest(
  _Checks c,
  DamageRequestDto r,
  String path,
) {
  final attacker = _checkPokemon(c, r.attacker, '$path.attacker');
  final defender = _checkPokemon(c, r.defender, '$path.defender');
  final move = _checkMove(c, r.move, '$path.move');
  c.require(r.hitIndex >= 0, '$path.hitIndex', ValidationCode.outOfRange);
  return () => DamageRequest._(
    attacker: attacker(),
    defender: defender(),
    move: move(),
    field: BattleField._fromDto(r.field),
    critical: r.critical,
    hitIndex: r.hitIndex,
  );
}

void _checkCounts(
  _Checks c,
  Map<int, BigInt> counts,
  int maximum,
  String path, {
  required bool conditional,
}) {
  c.require(counts.isNotEmpty, path, ValidationCode.required);
  for (final entry in counts.entries) {
    c.require(
      entry.key >= (conditional ? 1 : 0) && entry.key <= maximum,
      '$path[${entry.key}]',
      ValidationCode.outOfRange,
    );
    c.take(
      DistributionWeight.create(entry.value),
      '$path[${entry.key}].weight',
    );
  }
}

Attack Function() _checkAttack(_Checks c, AttackDto a, String path) {
  final turn = c.take(TurnNumber.create(a.turn), '$path.turn');
  c.require(a.hits.isNotEmpty, '$path.hits', ValidationCode.required);
  final hits = [
    for (var i = 0; i < a.hits.length; i++)
      _checkDistribution(c, a.hits[i], '$path.hits[$i]'),
  ];
  _checkCounts(
    c,
    a.hitCounts,
    a.hits.length,
    '$path.hitCounts',
    conditional: false,
  );
  final conditional = a.conditionalHitCounts;
  if (conditional != null) {
    _checkCounts(
      c,
      conditional,
      a.hits.length,
      '$path.conditionalHitCounts',
      conditional: true,
    );
  }
  return () => Attack._(
    turn!,
    List.unmodifiable(hits.map((build) => build())),
    Map.unmodifiable(a.hitCounts),
    conditional == null ? null : Map.unmodifiable(conditional),
  );
}

CombinedDamageRequest Function() _checkCombinedRequest(
  _Checks c,
  CombinedDamageRequestDto r,
  String path,
) {
  c.require(r.attacks.isNotEmpty, '$path.attacks', ValidationCode.required);
  final attacks = <Attack Function()>[];
  for (var i = 0; i < r.attacks.length; i++) {
    final a = r.attacks[i];
    attacks.add(_checkAttack(c, a, '$path.attacks[$i]'));
    c.require(
      i == 0
          ? a.turn == 1
          : a.turn == r.attacks[i - 1].turn ||
                a.turn == r.attacks[i - 1].turn + 1,
      '$path.attacks[$i].turn',
      ValidationCode.inconsistent,
    );
  }
  final defender = _checkPokemon(c, r.defender, '$path.defender');
  final setup = _checkSetup(c, r.setup, '$path.setup');
  final limits = _checkLimits(c, r.limits, '$path.limits');
  return () => CombinedDamageRequest._(
    defender: defender(),
    field: BattleField._fromDto(r.field),
    setup: setup(),
    limits: limits(),
    attacks: List.unmodifiable(attacks.map((build) => build())),
  );
}
