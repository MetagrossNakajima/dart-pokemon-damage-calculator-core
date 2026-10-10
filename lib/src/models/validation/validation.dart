part of '../validation.dart';

/// 計算の失敗と分けて扱う、検証付きの生成結果。
sealed class Validation<T> {
  const Validation();
}
