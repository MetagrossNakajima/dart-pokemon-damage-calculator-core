// はんすうの再発動ターン
part of '../value_objects.dart';

final class CudChewTurn extends Value<int> {
  const CudChewTurn._(super.value) : super._();
  static Validation<CudChewTurn> create(int value) =>
      Valid(CudChewTurn._(value));
}
