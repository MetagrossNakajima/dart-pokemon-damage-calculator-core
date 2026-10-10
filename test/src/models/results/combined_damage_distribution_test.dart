import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'combined distribution keeps BigInt keys and immutable exact weights',
    () {
      final large = BigInt.one << 100;
      final source = {
        BigInt.from(7): BigInt.two,
        large: BigInt.from(3),
        BigInt.zero: BigInt.one,
      };
      final result = CombinedDamageDistribution(source);
      source.clear();
      expect(result.min, BigInt.zero);
      expect(result.max, large);
      expect(result.weights, {
        BigInt.from(7): BigInt.two,
        large: BigInt.from(3),
        BigInt.zero: BigInt.one,
      });
      expect(result.totalWeight, BigInt.from(6));
      expect(() => result.weights.clear(), throwsUnsupportedError);
    },
  );
}
