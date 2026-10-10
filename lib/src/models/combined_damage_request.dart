part of 'models.dart';

final class CombinedDamageRequest extends DomainValue {
  const CombinedDamageRequest._({
    required this.defender,
    required this.field,
    required this.setup,
    required this.limits,
    required this.attacks,
  });

  final PokemonState defender;
  final BattleField field;
  final BattleSetup setup;
  final CalculationLimits limits;
  final List<Attack> attacks;

  static Validation<CombinedDamageRequest> fromDto(
    CombinedDamageRequestDto input,
  ) {
    final checks = _Checks();
    return checks.finish(
      _checkCombinedRequest(checks, input, 'combinedDamageRequest'),
    );
  }

  CombinedDamageRequestDto get toDto => CombinedDamageRequestDto(
    defender: defender.toDto,
    field: field.toDto,
    setup: setup.toDto,
    limits: limits.toDto,
    attacks: attacks.map((attack) => attack.toDto).toList(),
  );

  @override
  List<Object?> get _properties => [defender, field, setup, limits, attacks];
}
