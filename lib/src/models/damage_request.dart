part of 'models.dart';

final class DamageRequest extends DomainValue {
  const DamageRequest._({
    required this.attacker,
    required this.defender,
    required this.move,
    required this.field,
    required this.critical,
    required this.hitIndex,
  });

  final PokemonState attacker;
  final PokemonState defender;
  final Move move;
  final BattleField field;
  final bool critical;
  final int hitIndex;

  static Validation<DamageRequest> fromDto(DamageRequestDto input) {
    final checks = _Checks();
    return checks.finish(_checkDamageRequest(checks, input, 'damageRequest'));
  }

  DamageRequestDto get toDto => DamageRequestDto(
    attacker: attacker.toDto,
    defender: defender.toDto,
    move: move.toDto,
    field: field.toDto,
    critical: critical,
    hitIndex: hitIndex,
  );

  @override
  List<Object?> get _properties => [
    defender,
    field,
    attacker,
    move,
    critical,
    hitIndex,
  ];
}
