part of 'dto.dart';

/// 計算に成功した [value] を持つ結果。
final class Success<T> extends Calculation<T> {
  const Success(this.value);
  final T value;
}
