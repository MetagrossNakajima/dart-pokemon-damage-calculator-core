// 既存の計算ゴールデンはプリミティブなDTOで入力を定義する。
// 公開の生成APIと計算APIを順に通し、テスト内だけで共通の結果へ変換する。
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart'
    as core;
export 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;

// 旧ゴールデンの入力不正アサーションを維持するための、テスト専用の結果型。
// ライブラリの検証結果と計算結果は別の型のままである。
enum FailureKind { invalidInput, unsupported, complexityExceeded }

core.PokemonType pokemonType(String id) =>
    (core.PokemonType.create(id) as core.Valid<core.PokemonType>).value;

core.TeraType? teraType(String? id) => id == null
    ? null
    : (core.TeraType.create(id) as core.Valid<core.TeraType>).value;

sealed class Calculation<T> {}

final class Success<T> extends Calculation<T> {
  Success(this.value);
  final T value;
}

final class Failure<T> extends Calculation<T> {
  Failure(this.kind, this.path);
  final FailureKind kind;
  final String path;
}

Calculation<T> _run<R, T>(
  core.Validation<R> validation,
  core.Calculation<T> Function(R) calculate,
) {
  switch (validation) {
    case core.Invalid(:final errors):
      return Failure(FailureKind.invalidInput, errors.first.path);
    case core.Valid(:final value):
      return switch (calculate(value)) {
        core.Success(:final value) => Success(value),
        core.Failure(:final kind, :final path) => Failure(switch (kind) {
          core.FailureKind.unsupported => FailureKind.unsupported,
          core.FailureKind.complexityExceeded => FailureKind.complexityExceeded,
        }, path),
      };
  }
}

Calculation<core.DamageResult> calculateDamage(core.DamageRequestDto dto) =>
    _run(core.DamageRequest.fromDto(dto), core.calculateDamage);
Calculation<core.CombinedDamageResult> calculateCombinedDamage(
  core.CombinedDamageRequestDto dto,
) =>
    _run(core.CombinedDamageRequest.fromDto(dto), core.calculateCombinedDamage);
core.PokemonId pokemonId(String id) =>
    (core.PokemonId.create(id) as core.Valid<core.PokemonId>).value;
core.MoveId moveId(String id) =>
    (core.MoveId.create(id) as core.Valid<core.MoveId>).value;
core.AbilityId? abilityId(String? id) => id == null
    ? null
    : (core.AbilityId.create(id) as core.Valid<core.AbilityId>).value;
core.ItemId? itemId(String? id) => id == null
    ? null
    : (core.ItemId.create(id) as core.Valid<core.ItemId>).value;
