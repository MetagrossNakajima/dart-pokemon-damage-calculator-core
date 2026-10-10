part of '../dto.dart';

/// 計算中に変化しない、ポケモンの未検証プロフィールDTO。
final class PokemonProfileDto {
  PokemonProfileDto({
    required this.id,
    required List<PokemonType> types,
    required this.weight,
    this.gender = Gender.genderless,
  }) : types = List.unmodifiable(types);

  final PokemonId id;

  /// このヒットで使うタイプ（テラスタルによる変更前）。
  ///
  /// へんげんじざい・リベロのタイプ変更はクライアントが反映して渡す。
  /// コアは発動や発動済み状態を判定しない。
  final List<PokemonType> types;

  /// 0.1kg単位の体重。検証時に0.1〜999.9kgの範囲に制限する。
  final double weight;
  final Gender gender;
}
