import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';

void main() {
  test('検証エラーの等価性と一覧の不変性', () {
    const a = ValidationError('hp', ValidationCode.outOfRange);
    const b = ValidationError('hp', ValidationCode.outOfRange);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == Object(), isFalse);
    expect(
      a,
      isNot(const ValidationError('weight', ValidationCode.outOfRange)),
    );
    expect(a, isNot(const ValidationError('hp', ValidationCode.required)));
  });
}
