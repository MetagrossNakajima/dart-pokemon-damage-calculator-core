import 'dart:math' as math;

import '../models/dto.dart';

// 能力値・威力・ダメージへの補正適用は五捨五超入（ちょうど0.5は切り捨て）。
int applyModifierWithHalfDownRounding(
  int value,
  int numerator, [
  int denominator = 4096,
]) => (value * numerator * 2 + denominator - 1) ~/ (denominator * 2);

// 4096単位の補正値同士の連結は四捨五入。能力値へ適用するときの丸めとは異なる。
int chainModifiersWithHalfUpRounding(int current, int next) =>
    (current * next + 2048) ~/ 4096;

int unsigned16(int value) => value & 0xffff;
int unsigned32(int value) => value & 0xffffffff;

int rankedStat(int value, int rank) => rank == 0
    ? value
    : rank > 0
    ? unsigned16(value * (2 + rank)) ~/ 2
    : unsigned16(value * 2) ~/ (2 - rank);

final class TracedValue {
  TracedValue(this.value, Iterable<ModifierTrace> trace)
    : trace = List.unmodifiable(trace);

  final int value;
  final List<ModifierTrace> trace;
}

final class RuleModifier {
  const RuleModifier(this.id, this.multiplier);

  final String id;
  final int multiplier;
}

RuleModifier? modifierWhen(String id, int multiplier, bool applies) =>
    applies ? RuleModifier(id, multiplier) : null;

TracedValue applyFixedPointModifier(
  String id,
  ModifierStage stage,
  int value,
  int numerator, [
  int denominator = 4096,
]) {
  final after = applyModifierWithHalfDownRounding(
    value,
    numerator,
    denominator,
  );
  return TracedValue(after, [
    ModifierTrace(id, stage, numerator, denominator, value, after),
  ]);
}

final class ModifierChain {
  ModifierChain({
    required this.name,
    required this.modifierStage,
    this.valueStage,
  });
  final String name;
  final ModifierStage modifierStage;
  final ModifierStage? valueStage;
  final List<ModifierTrace> _trace = [];
  int value = 4096;
  void add(String id, int multiplier) {
    // 各連結で丸めるため、呼び出し順を変えると最終補正値も変わり得る。
    final before = value;
    value = chainModifiersWithHalfUpRounding(value, multiplier);
    _trace.add(
      ModifierTrace(id, modifierStage, multiplier, 4096, before, value),
    );
  }

  void addRule(RuleModifier? modifier) {
    if (modifier != null) add(modifier.id, modifier.multiplier);
  }

  TracedValue apply(int input) {
    final applied = applyFixedPointModifier(
      '${name}Modifiers',
      valueStage!,
      input,
      value,
    );
    return TracedValue(unsigned16(math.max(1, applied.value)), [
      ..._trace,
      ...applied.trace,
    ]);
  }

  TracedValue finish() => TracedValue(value, _trace);
}
