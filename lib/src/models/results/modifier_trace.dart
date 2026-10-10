part of '../dto.dart';

/// 1撃の補正トレースに記録された、名前付きの演算。
final class ModifierTrace {
  const ModifierTrace(
    this.id,
    this.stage,
    this.numerator,
    this.denominator,
    this.before,
    this.after,
  );
  final String id;
  final ModifierStage stage;
  final num numerator;
  final int denominator;
  final int before;
  final int after;
}
