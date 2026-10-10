// 値オブジェクトの基底型
part of '../value_objects.dart';

abstract base class Value<T> {
  const Value._(this.value);
  final T value;

  @override
  bool operator ==(Object other) =>
      other is Value<T> &&
      runtimeType == other.runtimeType &&
      value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}
