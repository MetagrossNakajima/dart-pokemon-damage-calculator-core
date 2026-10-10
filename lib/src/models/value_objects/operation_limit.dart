// 演算数の制限
part of '../value_objects.dart';

final class OperationLimit extends Value<int> {
  const OperationLimit._(super.value) : super._();
  static Validation<OperationLimit> create(int value) => value > 0
      ? Valid(OperationLimit._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
