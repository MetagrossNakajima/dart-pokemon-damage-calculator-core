import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';

void main() {
  test('検証エラー一覧のコピーと不変性', () {
    const a = ValidationError('hp', ValidationCode.outOfRange);
    final errors = [a];
    final result = Invalid<int>(errors);
    errors.clear();
    expect(result.errors, [a]);
    expect(() => result.errors.clear(), throwsUnsupportedError);
    expect(() => Invalid<int>([]), throwsArgumentError);
  });
}
