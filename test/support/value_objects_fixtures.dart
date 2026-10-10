import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';

T valid<T>(Validation<T> result) {
  expect(result, isA<Valid<T>>());
  return (result as Valid<T>).value;
}

void cases<T extends Value<V>, V>(
  String name,
  Validation<T> Function(V) create,
  List<V> accepted,
  List<V> rejected,
  ValidationCode code,
) {
  test('$nameの許容境界と値による等価性', () {
    for (final value in accepted) {
      final a = valid(create(value));
      final b = valid(create(value));
      expect(a.value, value);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    }
    expect(valid(create(accepted.first)), isNot(valid(create(accepted.last))));
  });
  if (rejected.isNotEmpty) {
    test('$nameの不正な値を構築できない', () {
      for (final value in rejected) {
        final result = create(value);
        expect(result, isA<Invalid<T>>());
        expect((result as Invalid<T>).errors, [ValidationError('value', code)]);
      }
    });
  }
}
