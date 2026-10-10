part of '../validation.dart';

/// 入力フィールドまたは添字付きの位置を示す検証エラー。
final class ValidationError {
  const ValidationError(this.path, this.code);
  final String path;
  final ValidationCode code;

  @override
  bool operator ==(Object other) =>
      other is ValidationError && path == other.path && code == other.code;

  @override
  int get hashCode => Object.hash(path, code);
}
