part of 'models.dart';

final class CalculationLimits extends DomainValue {
  const CalculationLimits._(this.maxOperations, this.maxStates);

  final OperationLimit maxOperations;
  final StateLimit maxStates;

  static Validation<CalculationLimits> fromDto(CalculationLimitsDto input) {
    final checks = _Checks();
    return checks.finish(_checkLimits(checks, input, 'calculationLimits'));
  }

  CalculationLimitsDto get toDto => CalculationLimitsDto(
    maxOperations: maxOperations.value,
    maxStates: maxStates.value,
  );

  @override
  List<Object?> get _properties => [maxOperations, maxStates];
  static final defaults = _checked(fromDto(const CalculationLimitsDto()));
}
