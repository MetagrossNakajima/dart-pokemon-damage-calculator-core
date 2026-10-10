part of '../dto.dart';

/// 実行され得る1撃の、中間値・乱数・補正トレース。
final class HitResult {
  HitResult(
    this.power,
    this.attack,
    this.defense,
    this.critical,
    List<int> rolls,
    List<ModifierTrace> trace, {
    this.kind = DamageKind.normal,
  }) : rolls = List.unmodifiable(rolls),
       trace = List.unmodifiable(trace);
  final int power;
  final int attack;
  final int defense;
  final bool critical;
  final DamageKind kind;

  /// 固定ダメージでは、[power] は入力した技のメタデータとしてのみ保持する。
  ///
  /// [attack] と [defense] は補正前の参照能力値であり、
  /// [DamageKind.fixed] の演算には使用しない。
  final List<int> rolls;
  final List<ModifierTrace> trace;
}
