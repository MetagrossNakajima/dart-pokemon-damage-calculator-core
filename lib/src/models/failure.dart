part of 'dto.dart';

/// 失敗の位置 [path] と理由 [kind] を持つ計算結果。
final class Failure<T> extends Calculation<T> {
  const Failure(this.kind, this.path);
  final FailureKind kind;
  final String path;
}
