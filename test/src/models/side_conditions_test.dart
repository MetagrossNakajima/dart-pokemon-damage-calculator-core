import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';

void main() {
  test('壁と置換値も値による等価性を持つ', () {
    const walls = SideConditions(reflect: true, lightScreen: true);
    final same = SideConditions(reflect: true, lightScreen: true);
    expect(walls, same);
    expect(walls.hashCode, same.hashCode);
    expect(walls == Object(), isFalse);
    expect(walls, isNot(const SideConditions(lightScreen: true)));
    expect(walls, isNot(const SideConditions(reflect: true)));
  });
}
