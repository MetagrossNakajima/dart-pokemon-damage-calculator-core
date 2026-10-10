part of 'models.dart';

final class Attack extends DomainValue {
  const Attack._(
    this.turn,
    this.hits,
    this.hitCounts,
    this.conditionalHitCounts,
  );

  final TurnNumber turn;
  final List<DamageWeights> hits;
  final Map<int, BigInt> hitCounts;
  final Map<int, BigInt>? conditionalHitCounts;

  static Validation<Attack> fromDto(AttackDto input) {
    final checks = _Checks();
    return checks.finish(_checkAttack(checks, input, 'attack'));
  }

  AttackDto get toDto => AttackDto(
    turn: turn.value,
    hits: hits.map((hit) => hit.toDto).toList(),
    hitCounts: hitCounts,
    conditionalHitCounts: conditionalHitCounts,
  );

  @override
  List<Object?> get _properties => [
    turn,
    hits,
    hitCounts,
    conditionalHitCounts,
  ];
}
