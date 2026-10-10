part of '../dto.dart';

/// 防御側の最終状態と、その分岐の正確な重み。
final class WeightedBattleState {
  const WeightedBattleState({required this.state, required this.weight});
  final BattleState state;
  final BigInt weight;
}
