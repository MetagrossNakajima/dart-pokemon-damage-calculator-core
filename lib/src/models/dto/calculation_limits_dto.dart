part of '../dto.dart';

/// リクエストの各段階で共有する、未検証の計算量制限DTO。
final class CalculationLimitsDto {
  const CalculationLimitsDto({
    this.maxOperations = 2000000,
    this.maxStates = 100000,
  });
  final int maxOperations;
  final int maxStates;
}
